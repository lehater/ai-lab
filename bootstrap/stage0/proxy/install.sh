#!/usr/bin/env bash
set -euo pipefail
PACK_DIR="${1:?Usage: install.sh /path/to/private-proxy}"
PACK_DIR="$(realpath "$PACK_DIR")"
DEB="$PACK_DIR/v2rayN-linux-64.deb"
ARCHIVE="$PACK_DIR/v2rayn-data.tar.gz"
CHECKSUM="$PACK_DIR/v2rayn-data.sha256"
DATA_DIR="$HOME/.local/share/v2rayN"
[[ "$EUID" -ne 0 ]] || { echo "Run as regular user, not root" >&2; exit 1; }
for file in "$DEB" "$ARCHIVE" "$CHECKSUM"; do
  [[ -f "$file" ]] || { echo "Missing: $file" >&2; exit 1; }
done
[[ ! -e "$DATA_DIR" ]] || { echo "Existing configuration; refusing to overwrite: $DATA_DIR" >&2; exit 1; }
echo "Verifying private archive..."
# The old backup checksum names its ORIGINAL absolute path. Only use the digest
# so it remains valid after moving the archive to a USB directory.
expected="$(awk 'NR==1 {print $1}' "$CHECKSUM")"
[[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || { echo "Invalid archive checksum file" >&2; exit 1; }
actual="$(sha256sum "$ARCHIVE")"
actual="${actual%% *}"
[[ "${expected,,}" == "${actual,,}" ]] || { echo "Archive checksum mismatch" >&2; exit 1; }
[[ "$(dpkg-deb -f "$DEB" Package)" == "v2rayn" ]] || { echo "Unexpected Debian package" >&2; exit 1; }
[[ "$(dpkg-deb -f "$DEB" Version)" == "7.20.2" ]] || { echo "Unexpected v2rayN version" >&2; exit 1; }
[[ "$(dpkg-deb -f "$DEB" Architecture)" == "amd64" ]] || { echo "Unexpected architecture" >&2; exit 1; }
sudo dpkg -i "$DEB"
mkdir -p "$HOME/.local/share"
tar -xzf "$ARCHIVE" -C "$HOME/.local/share"
[[ -d "$DATA_DIR" ]] || { echo "Expected configuration directory missing after restore" >&2; exit 1; }
chmod -R go-rwx "$DATA_DIR"
echo "Offline v2rayN installation and configuration restore complete."
