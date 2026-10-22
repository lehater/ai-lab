#!/usr/bin/env bash
# Offline constraints; runtime verification is ./lab.sh verify on lab-test.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash -n "$ROOT/lab.sh" "$ROOT/tests/test-static.sh"
[[ -f "$ROOT/compose.yaml" ]]
grep -Fq -- '127.0.0.1:5678:5678' "$ROOT/compose.yaml"
grep -Fq -- 'N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY:' "$ROOT/compose.yaml"
grep -Fq -- 'n8n_data:/home/node/.n8n' "$ROOT/compose.yaml"
grep -Fq -- 'docker.n8n.io/n8nio/n8n:2.44.5' "$ROOT/compose.yaml"
! grep -Eq '(^[[:space:]]*privileged:|latest|network_mode: host|/var/run/docker.sock)' "$ROOT/compose.yaml"
grep -Fq -- 'down --volumes --remove-orphans' "$ROOT/lab.sh"
grep -Fq -- 'clean --destroy-experiment-data' "$ROOT/lab.sh"
echo 'PASS: static shell and scoped n8n Compose expectations.'
