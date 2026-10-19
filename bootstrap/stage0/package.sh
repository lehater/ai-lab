#!/usr/bin/env bash
set -euo pipefail
# Build a clean USB executable bundle. Secret archive stays separate.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE="${1:?Usage: package.sh /path/to/proxy-migration /path/to/age-executable /path/to/output}"
AGE_BIN="${2:?Missing local trusted age executable}"
TARGET="${3:?Missing bundle output directory}"
SOURCE="$(realpath "$SOURCE")"
AGE_BIN="$(realpath "$AGE_BIN")"
mkdir -p "$TARGET"
TARGET="$(realpath "$TARGET")"
[[ "$TARGET" != "$SOURCE" ]] || { echo "ERROR: output must differ from source" >&2; exit 1; }
for f in v2rayN-linux-64.deb; do [[ -f "$SOURCE/$f" ]] || exit 1; done
[[ -x "$AGE_BIN" ]] || { echo "ERROR: age executable must exist and be executable" >&2; exit 1; }
for p in bootstrap.sh install.sh age v2rayN-linux-64.deb checksums.sha256; do
  [[ ! -e "$TARGET/$p" ]] || { echo "ERROR: output directory must be empty" >&2; exit 1; }
done
install -m 0755 "$ROOT/bootstrap/stage0/bootstrap.sh" "$TARGET/bootstrap.sh"
install -m 0755 "$ROOT/bootstrap/proxy/install.sh" "$TARGET/install.sh"
install -m 0755 "$AGE_BIN" "$TARGET/age"
install -m 0644 "$SOURCE/v2rayN-linux-64.deb" "$TARGET/v2rayN-linux-64.deb"
(cd "$TARGET" && sha256sum bootstrap.sh install.sh age v2rayN-linux-64.deb > checksums.sha256)
echo "USB program bundle prepared: $TARGET"
echo "Store the encrypted v2rayn-data.tar.gz.age separately."
echo "Verify age binary provenance and checksums against a trusted source before deployment."
