#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="${1:?Usage: install.sh PACK_DIR}"
PACK_DIR="$(realpath "$PACK_DIR")"

DEB="$PACK_DIR/v2rayN-linux-64.deb"
ARCHIVE="$PACK_DIR/v2rayn-data.tar.gz"
CHECKSUM="$PACK_DIR/v2rayn-data.sha256"

DATA_DIR="$HOME/.local/share/v2rayN"

if [[ "$EUID" -eq 0 ]]; then
    echo "Run as a regular user, not root" >&2
    exit 1
fi

for file in "$DEB" "$ARCHIVE" "$CHECKSUM"; do
    [[ -f "$file" ]] || {
        echo "Missing: $file" >&2
        exit 1
    }
done

echo "Verifying archive..."
(cd "$PACK_DIR" && sha256sum -c "$(basename "$CHECKSUM")")

echo "Checking package..."
[[ "$(dpkg-deb -f "$DEB" Package)" == "v2rayn" ]]
[[ "$(dpkg-deb -f "$DEB" Version)" == "7.20.2" ]]
[[ "$(dpkg-deb -f "$DEB" Architecture)" == "amd64" ]]

if [[ -e "$DATA_DIR" ]]; then
    echo "Existing configuration: $DATA_DIR"
    echo "Refusing to overwrite."
    exit 1
fi

echo "Installing v2rayN..."
sudo dpkg -i "$DEB"

echo "Restoring configuration..."
mkdir -p "$HOME/.local/share"
tar -xzf "$ARCHIVE" -C "$HOME/.local/share"

chmod -R go-rwx "$DATA_DIR"

echo "Installation complete."
