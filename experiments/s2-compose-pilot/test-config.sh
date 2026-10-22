#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash -n "$DIR/smoke.sh"
command -v sudo >/dev/null || { echo 'ERROR: sudo required' >&2; exit 1; }
command -v docker >/dev/null || { echo 'ERROR: Docker/Compose required (run S1-D first)' >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
umask 077
printf '%s\n' 'temporary-fixture-value' > "$tmp/password"
sudo env S2_SECRET_FILE="$tmp/password" docker compose -f "$DIR/compose.yaml" config --quiet
echo 'PASS: S2.1 shell syntax and Compose configuration.'
