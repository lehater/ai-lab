#!/usr/bin/env bash
# Offline contract regression test. No sudo/network/host mutation.
set -euo pipefail
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
module="$(dirname "$here")"
installer="$module/setup.sh"
bash -n "$installer"
bash -n "$here/test-static.sh"

has() {
    grep -Fq -- "$1" "$installer" ||
        { printf 'Missing required installer invariant: %s\n' "$1" >&2; exit 1; }
}

has "CODEX_VERSION='0.163.0'"
has 'codex.js'
has 'sandbox -- /bin/true'
has 'kernel.apparmor_restrict_unprivileged_userns'
has 'bwrap-userns-restrict'
has 'apparmor_parser -r'
has 'Existing compatible Codex reused'
has 'run as the operator'
has 'Refusing unrecognized Codex launcher'

if grep -Eq 'sysctl -w|apparmor_restrict_unprivileged_userns=0|dangerously-bypass-approvals-and-sandbox|docker group|chmod 666 /var/run/docker.sock' "$installer"; then
    echo 'ERROR: installer contains a prohibited sandbox bypass or privilege escalation.' >&2
    exit 1
fi
printf '%s\n' 'PASS: optional Codex installer syntax and security invariants (offline).'
