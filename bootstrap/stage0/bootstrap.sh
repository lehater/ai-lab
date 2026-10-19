#!/usr/bin/env bash
set -euo pipefail

# Stage 0: offline local v2rayN installation -> network -> git clone over HTTPS.
# Run from an extracted offline bundle as a non-root desktop user.
PACK_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PACK_DIR="$(realpath "$PACK_DIR")"
PROXY_URL="http://127.0.0.1:10808"
REPO_URL="https://github.com/lehater/ai-lab.git"
DEST="${AI_LAB_DEST:-$HOME/projects/ai-lab}"
AUTOSTART="$HOME/.config/autostart/v2rayn.desktop"

if [[ "$EUID" -eq 0 ]]; then echo "Run as a regular user, not root" >&2; exit 1; fi
if [[ ! -f "$PACK_DIR/install.sh" ]]; then echo "Missing install.sh in $PACK_DIR" >&2; exit 1; fi
for f in v2rayN-linux-64.deb v2rayn-data.tar.gz v2rayn-data.sha256; do
  [[ -f "$PACK_DIR/$f" ]] || { echo "Missing $f" >&2; exit 1; }
done
(cd "$PACK_DIR" && sha256sum -c v2rayn-data.sha256)
echo "Stage 0: installation"
if ! dpkg-query -W -f='${Status}' v2rayn 2>/dev/null | grep -qx 'install ok installed' || [[ ! -d "$HOME/.local/share/v2rayN" ]]; then
  if [[ -d "$HOME/.local/share/v2rayN" ]]; then
    echo "Partial existing configuration; refusing to overwrite: ~/.local/share/v2rayN" >&2
    exit 1
  fi
  bash "$PACK_DIR/install.sh" "$PACK_DIR"
else
  echo "v2rayN and user configuration already present; skipping restore"
fi

mkdir -p "$(dirname "$AUTOSTART")"
cat > "$AUTOSTART" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=v2rayN
Exec=/usr/bin/v2rayn
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
chmod 644 "$AUTOSTART"

echo "Start v2rayN in the graphical desktop and select the working server."
echo "Then return here and press Enter. The proxy must already listen at 127.0.0.1:10808."
read -r -p "Press Enter to test the proxy... "
if ! (echo > /dev/tcp/127.0.0.1/10808) 2>/dev/null; then
  echo "Proxy port 10808 is not listening" >&2
  exit 1
fi
# wget ships on the target Ubuntu Desktop image; explicit HTTP proxy avoids
# dependence on GNOME proxy settings or interactive shell configuration.
command -v wget >/dev/null || { echo "wget missing; offline check requires wget" >&2; exit 1; }
https_proxy="$PROXY_URL" http_proxy="$PROXY_URL" \
  wget -q --spider -T 20 https://github.com || {
    echo "Could not reach GitHub through Xray" >&2; exit 1;
  }

echo "Configuring APT proxy"
sudo install -d -m 0755 /etc/apt/apt.conf.d
printf 'Acquire::http::Proxy "%s/";\nAcquire::https::Proxy "%s/";\n' "$PROXY_URL" "$PROXY_URL" | \
  sudo tee /etc/apt/apt.conf.d/80proxy >/dev/null
sudo apt-get update
sudo apt-get install -y git openssh-client curl ca-certificates

echo "Verifying explicit HTTPS proxy"
curl --noproxy "" --proxy "$PROXY_URL" -fsS -o /dev/null \
  --connect-timeout 10 --max-time 30 https://github.com

echo "Cloning public repository over proxied HTTPS"
mkdir -p "$(dirname "$DEST")"
if [[ -e "$DEST/.git" ]]; then
  echo "Repository directory already exists: $DEST (not overwriting)"
elif [[ -e "$DEST" ]]; then
  echo "Destination exists and is not a git repository: $DEST" >&2; exit 1
else
  git -c http.proxy="$PROXY_URL" clone "$REPO_URL" "$DEST"
fi
echo "Stage 0 complete. Next: cd '$DEST' and run the host bootstrap from Git."
