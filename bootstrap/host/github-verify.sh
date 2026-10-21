#!/usr/bin/env bash
set -euo pipefail
[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as the desktop user, not root' >&2; exit 1; }
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}/ai-lab/github-ssh.conf"
[[ -f "$config" && ! -L "$config" ]] || { echo 'ERROR: run make host-setup first' >&2; exit 1; }
cat <<'INSTRUCTIONS'
GitHub host-key verification is operator-controlled.
Before answering 'yes' to an unknown key, compare the displayed fingerprint:
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
The initial SSH -T may return 1 even if GitHub says authentication succeeded.
INSTRUCTIONS
# First interactive connection lets the operator inspect/approve the host key.
# An SSH -T exit code 1 alone does not mean authentication failed.
ssh -F "$config" -o ConnectTimeout=20 -T ai-lab-github || true
# Definitive check: authenticated Git operation with strict host-key checking.
bash "$DIR/verify.sh" --auth
