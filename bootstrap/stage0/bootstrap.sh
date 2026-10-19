#!/usr/bin/env bash
set -euo pipefail
# Offline Stage 0: Ubuntu 24.04 Desktop amd64 on VMware.
# Bundle has no plaintext proxy data. A separate encrypted secret is required.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS="${1:?Usage: bash bootstrap.sh /path/to/v2rayn-data.tar.gz.age}"
PROFILE="${AI_LAB_PROFILE:-vmware}"
DEST="${AI_LAB_DEST:-$HOME/projects/ai-lab}"
PROXY="http://127.0.0.1:10808"
[[ "$EUID" -ne 0 ]] || { echo "ERROR: do not run as root" >&2; exit 1; }
[[ "$PROFILE" == "vmware" ]] || { echo "ERROR: only vmware profile supported" >&2; exit 1; }
[[ "$(dpkg --print-architecture)" == "amd64" ]] || { echo "ERROR: only amd64 supported" >&2; exit 1; }
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || { echo "ERROR: Ubuntu 24.04 required" >&2; exit 1; }
[[ -f "$SECRETS" ]] || { echo "ERROR: encrypted secrets not found" >&2; exit 1; }
for f in install.sh v2rayN-linux-64.deb age checksums.sha256; do
  [[ -f "$DIR/$f" ]] || { echo "ERROR: missing $DIR/$f" >&2; exit 1; }
done
echo "Checking bundled executable and installer integrity"
(cd "$DIR" && sha256sum -c checksums.sha256)
[[ -x "$DIR/age" ]] || chmod u+x "$DIR/age"
[[ "$(dpkg-deb -f "$DIR/v2rayN-linux-64.deb" Package)" == "v2rayn" ]]
[[ "$(dpkg-deb -f "$DIR/v2rayN-linux-64.deb" Version)" == "7.20.2" ]]
if [[ ! -d "$HOME/.local/share/v2rayN" ]]; then
  TEMP="$(mktemp -d)"
  chmod 700 "$TEMP"
  trap 'rm -rf -- "$TEMP"' EXIT
  echo "Decrypting private configuration (passphrase/key requested by age)"
  "$DIR/age" -d -o "$TEMP/v2rayn-data.tar.gz" "$SECRETS"
  (cd "$TEMP" && sha256sum v2rayn-data.tar.gz > v2rayn-data.sha256)
  cp "$DIR/v2rayN-linux-64.deb" "$TEMP/"
  bash "$DIR/install.sh" "$TEMP"
else
  dpkg-query -W -f='${Status}' v2rayn 2>/dev/null | grep -qx 'install ok installed' || {
    echo "ERROR: configuration exists but v2rayN package is missing" >&2; exit 1;
  }
  echo "Existing proxy configuration preserved"
fi
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/v2rayn.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=v2rayN
Exec=/usr/bin/v2rayn
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
echo "Start v2rayN in GNOME and select the server. Press Enter when Xray is listening."
read -r
(echo > /dev/tcp/127.0.0.1/10808) 2>/dev/null || { echo "ERROR: Xray not listening" >&2; exit 1; }
https_proxy="$PROXY" http_proxy="$PROXY" wget -q --spider -T 20 https://github.com || {
  echo "ERROR: proxied GitHub connectivity failed" >&2; exit 1;
}
printf 'Acquire::http::Proxy "%s/";\nAcquire::https::Proxy "%s/";\n' "$PROXY" "$PROXY" |
 sudo tee /etc/apt/apt.conf.d/80proxy >/dev/null
sudo apt-get update
# open-vm-tools desktop is a post-proxy VMware dependency, not required to establish access.
sudo apt-get install -y git curl openssh-client ca-certificates open-vm-tools open-vm-tools-desktop
curl --noproxy "" --proxy "$PROXY" -fsS --max-time 30 -o /dev/null https://github.com
if [[ ! -e "$DEST" ]]; then
  mkdir -p "$(dirname "$DEST")"
  git -c http.proxy="$PROXY" clone https://github.com/lehater/ai-lab.git "$DEST"
elif [[ -d "$DEST/.git" ]]; then
  echo "Existing Git clone preserved: $DEST"
else
  echo "ERROR: destination exists and is not a Git checkout: $DEST" >&2; exit 1;
fi
echo "Stage 0 PASS: proxy, APT, VMware Tools, Git and repository checkout"
