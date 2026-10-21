#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for script in "$DIR"/{setup.sh,verify.sh,render.sh,net-diagnose.sh}; do bash -n "$script"; done
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
bash "$DIR/render.sh" sources > "$scratch/one"
bash "$DIR/render.sh" sources > "$scratch/two"
cmp "$scratch/one" "$scratch/two"
grep -qx 'Suites: noble' "$scratch/one"
grep -qx 'Signed-By: /etc/apt/keyrings/docker.asc' "$scratch/one"
bash "$DIR/render.sh" daemon-proxy > "$scratch/three"
grep -q 'HTTP_PROXY=http://127.0.0.1:10808' "$scratch/three"
grep -q 'HTTPS_PROXY=http://127.0.0.1:10808' "$scratch/three"
if bash "$DIR/render.sh" invalid >/dev/null 2>&1; then
    echo 'FAIL: invalid template option succeeded' >&2; exit 1
fi
[[ "$(wc -l < "$scratch/three")" == 2 ]]
grep -Fq -- '--network bridge' "$DIR/net-diagnose.sh"
grep -Fq -- '--add-host host.docker.internal:host-gateway' "$DIR/net-diagnose.sh"
grep -Fq -- '--noproxy' "$DIR/net-diagnose.sh"
echo 'PASS: Docker Shell syntax, stable APT repository template, daemon proxy template and bridge diagnostic contract.'
