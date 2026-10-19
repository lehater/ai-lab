#!/usr/bin/env bash
set -euo pipefail
# USB layout is identical to Git: bootstrap/stage0/{bootstrap.sh,proxy/,private-proxy/}.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE="$DIR/private-proxy"
DEST="${AI_LAB_DEST:-$HOME/projects/ai-lab}"
PROXY="http://127.0.0.1:10808"
[[ "$EUID" -ne 0 ]] || { echo "ERROR: run as desktop user, not root" >&2; exit 1; }
[[ "$(dpkg --print-architecture)" == amd64 ]] || { echo "ERROR: amd64 required" >&2; exit 1; }
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || { echo "ERROR: Ubuntu 24.04 required" >&2; exit 1; }
for script in install.sh configure.sh verify.sh; do
  [[ -f "$DIR/proxy/$script" ]] || { echo "ERROR: missing $DIR/proxy/$script" >&2; exit 1; }
done
for file in v2rayN-linux-64.deb v2rayn-data.tar.gz v2rayn-data.sha256; do
  [[ -f "$PRIVATE/$file" ]] || {
    echo "ERROR: missing $PRIVATE/$file. See private-proxy/README.md" >&2; exit 1;
  }
done
if [[ ! -d "$HOME/.local/share/v2rayN" ]]; then
  bash "$DIR/proxy/install.sh" "$PRIVATE"
else
  dpkg-query -W -f='${Status}' v2rayn 2>/dev/null | grep -qx 'install ok installed' || {
    echo "ERROR: existing v2rayN configuration but package missing" >&2; exit 1;
  }
  echo "Existing configuration preserved."
fi
bash "$DIR/proxy/configure.sh"
echo "Start v2rayN in GNOME and select a working server."
read -r -p "Press Enter when Xray is running on localhost:10808 ... "
(echo >/dev/tcp/127.0.0.1/10808) 2>/dev/null || { echo "ERROR: proxy not listening" >&2; exit 1; }
command -v wget >/dev/null || { echo "ERROR: wget not installed; cannot validate initial network" >&2; exit 1; }
wget -q --spider -T 25 -e use_proxy=yes -e https_proxy="$PROXY" https://github.com ||
  { echo "ERROR: GitHub unreachable through proxy" >&2; exit 1; }
echo "Configuring APT to use local proxy"
printf 'Acquire::http::Proxy "%s/";\nAcquire::https::Proxy "%s/";\n' "$PROXY" "$PROXY" |
  sudo tee /etc/apt/apt.conf.d/80proxy >/dev/null
sudo apt-get update
sudo apt-get install -y git curl openssh-client ca-certificates open-vm-tools open-vm-tools-desktop
bash "$DIR/proxy/verify.sh"
if [[ ! -e "$DEST" ]]; then
  mkdir -p "$(dirname "$DEST")"
  git -c http.proxy="$PROXY" clone https://github.com/lehater/ai-lab.git "$DEST"
elif [[ -d "$DEST/.git" ]]; then
  echo "Existing Git repository preserved: $DEST"
else
  echo "ERROR: directory exists but isn't a Git repository: $DEST" >&2; exit 1;
fi
echo "Stage 0 PASS: proxy, autostart, APT, VMware tools and GitHub checkout."
