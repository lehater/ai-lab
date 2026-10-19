#!/usr/bin/env bash
set -euo pipefail
# Build USB program bundle without any private configuration.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="${1:?Usage: package.sh /path/to/proxy-migration /path/to/output}"
TARGET="${2:?Missing bundle output directory}"
SOURCE="$(realpath "$SOURCE")"
mkdir -p "$TARGET"
TARGET="$(realpath "$TARGET")"
[[ "$TARGET" != "$SOURCE" ]] || { echo "ERROR: output must differ from source" >&2; exit 1; }
for f in v2rayN-linux-64.deb; do [[ -f "$SOURCE/$f" ]] || exit 1; done
for p in bootstrap.sh install.sh configure.sh v2rayN-linux-64.deb checksums.sha256; do
  [[ ! -e "$TARGET/$p" ]] || { echo "ERROR: output directory must be empty" >&2; exit 1; }
done
install -m 0755 "$ROOT/bootstrap/stage0/bootstrap.sh" "$TARGET/bootstrap.sh"
install -m 0755 "$ROOT/bootstrap/proxy/install.sh" "$TARGET/install.sh"
install -m 0755 "$ROOT/bootstrap/proxy/configure.sh" "$TARGET/configure.sh"
install -m 0644 "$SOURCE/v2rayN-linux-64.deb" "$TARGET/v2rayN-linux-64.deb"
(cd "$TARGET" && sha256sum bootstrap.sh install.sh configure.sh v2rayN-linux-64.deb > checksums.sha256)
echo "USB program bundle prepared: $TARGET"
echo "Store the private v2rayn-data.tar.gz and v2rayn-data.sha256 separately, outside Git."
echo "Private proxy archives must not be uploaded to GitHub."
