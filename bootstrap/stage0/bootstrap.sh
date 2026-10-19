#!/usr/bin/env bash
set -euo pipefail
# Offline Stage 0: Ubuntu 24.04 Desktop amd64 on VMware.
# Public code and private proxy configuration are stored separately.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS="${1:?Usage: bash bootstrap.sh /path/to/private-proxy-directory}"
SECRETS="$(realpath "$SECRETS")"
PROFILE="${AI_LAB_PROFILE:-vmware}"
DEST="${AI_LAB_DEST:-$HOME/projects/ai-lab}"
PROXY="http://127.0.0.1:10808"
[[ "$EUID" -ne 0 ]] || { echo "ERROR: do not run as root" >&2; exit 1; }
[[ "$PROFILE" == "vmware" ]] || { echo "ERROR: only vmware profile supported" >&2; exit 1; }
[[ "$(dpkg --print-architecture)" == "amd64" ]] || { echo "ERROR: only amd64 supported" >&2; exit 1; }
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || { echo "ERROR: Ubuntu 24.04 required" >&2; exit 1; }
[[ -d "$SECRETS" ]] || { echo "ERROR: private directory not found" >&2; exit 1; }
for f in v2rayn-data.tar.gz v2rayn-data.sha256; do
  [[ -f "$SECRETS/$f" ]] || { echo "ERROR: missing private $f" >&2; exit 1; }
done
for f in install.sh configure.sh v2rayN-linux-64.deb checksums.sha256; do
  [[ -f "$DIR/$f" ]] || { echo "ERROR: missing $DIR/$f" >&2; exit 1; }
done
echo "Checking bundled executable and installer integrity"
(cd "$DIR" && sha256sum -c checksums.sha256)
[[ "$(dpkg-deb -f "$DIR/v2rayN-linux-64.deb" Package)" == "v2rayn" ]]
[[ "$(dpkg-deb -f "$DIR/v2rayN-linux-64.deb" Version)" == "7.20.2" ]]
if [[ ! -d "$HOME/.local/share/v2rayN" ]]; then
  # Existing install.sh expects DEB, archive and checksum in one directory.
  # Secret tarball never gets copied to this public repository.
  (cd "$SECRETS" && sha256sum -c v2rayn-data.sha256)
  TEMP="$(mktemp -d)"
  chmod 700 "$TEMP"
  trap 'rm -rf -- "$TEMP"' EXIT
  cp "$SECRETS/v2rayn-data.tar.gz" "$SECRETS/v2rayn-data.sha256" "$TEMP/"
  cp "$DIR/v2rayN-linux-64.deb" "$TEMP/"
  bash "$DIR/install.sh" "$TEMP"
else
  dpkg-query -W -f='${Status}' v2rayn 2>/dev/null | grep -qx 'install ok installed' || {
    echo "ERROR: configuration exists but v2rayN package is missing" >&2; exit 1;
  }
  echo "Existing proxy configuration preserved"
fi
bash "$DIR/configure.sh"
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
