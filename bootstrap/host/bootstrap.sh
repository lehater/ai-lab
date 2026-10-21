#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as the desktop user, not root' >&2; exit 1; }
[[ "$(dpkg --print-architecture)" == amd64 ]] || { echo 'ERROR: amd64 required' >&2; exit 1; }
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || {
    echo 'ERROR: Ubuntu 24.04 is required for the current S1 candidate' >&2; exit 1;
}
for cmd in git ssh curl sudo dpkg-query apt-get; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing prerequisite: $cmd (run S0 first)" >&2; exit 1; }
done
[[ -f /etc/apt/apt.conf.d/80proxy ]] || {
    echo 'ERROR: S0 APT proxy config is missing; run Stage 0 first' >&2; exit 1;
}

# S0 owns the proxy itself. Do not modify its configuration or user credentials.
if ! dpkg-query -W -f='${Status}' netcat-openbsd 2>/dev/null | grep -qx 'install ok installed'; then
    echo 'Installing netcat-openbsd via the S0-configured APT proxy...'
    sudo apt-get update
    sudo apt-get install -y netcat-openbsd
fi
bash "$DIR/configure-ssh.sh"
bash "$DIR/verify.sh"
echo 'S1 SSH transport candidate configured. SSH identity/enrollment still requires owner action.'
