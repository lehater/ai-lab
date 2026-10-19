#!/usr/bin/env bash
set -euo pipefail
# Assemble a temporary *unencrypted* test bundle locally. Never commit output.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="${1:?Usage: package-test.sh /path/to/proxy-migration /path/to/output}"
TARGET="${2:?Usage: package-test.sh /path/to/proxy-migration /path/to/output}"
SOURCE="$(realpath "$SOURCE")"
mkdir -p "$TARGET"
TARGET="$(realpath "$TARGET")"
[[ "$SOURCE" != "$TARGET" ]] || { echo "Input and output must differ" >&2; exit 1; }
for f in v2rayN-linux-64.deb v2rayn-data.tar.gz v2rayn-data.sha256; do
  [[ -f "$SOURCE/$f" ]] || { echo "Missing $SOURCE/$f" >&2; exit 1; }
done
(cd "$SOURCE" && sha256sum -c v2rayn-data.sha256)
install -m 0755 "$ROOT/bootstrap/stage0/bootstrap.sh" "$TARGET/bootstrap.sh"
install -m 0755 "$ROOT/bootstrap/proxy/install.sh" "$TARGET/install.sh"
install -m 0600 "$SOURCE/v2rayn-data.tar.gz" "$TARGET/v2rayn-data.tar.gz"
install -m 0600 "$SOURCE/v2rayn-data.sha256" "$TARGET/v2rayn-data.sha256"
install -m 0644 "$SOURCE/v2rayN-linux-64.deb" "$TARGET/v2rayN-linux-64.deb"
echo "Temporary sensitive test bundle created: $TARGET"
echo "Do not commit, publish, or retain it unencrypted."
