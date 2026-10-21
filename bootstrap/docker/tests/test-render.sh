#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for script in "$DIR"/{setup.sh,verify.sh,render.sh,compose-smoke.sh}; do bash -n "$script"; done
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
grep -Fq -- 'up --abort-on-container-exit --exit-code-from smoke' "$DIR/compose-smoke.sh"
grep -Fq -- 'network inspect' "$DIR/compose-smoke.sh"
grep -Fq -- 'down' "$DIR/compose-smoke.sh"
echo 'PASS: Docker Shell syntax, APT/daemon-proxy templates and Compose smoke contract.'
