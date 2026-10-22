#!/usr/bin/env bash
# Read-only structural and negative-guard smoke. No root, APT or package changes.
set -Eeuo pipefail

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
(( EUID != 0 )) || fail 'Run as unprivileged operator on lab-test.'
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export ANSIBLE_CONFIG="${ROOT}/ansible.cfg"
export PATH="${HOME}/.local/bin:${PATH}"
INV="${ROOT}/inventory/local.yml"
BOOK="${ROOT}/playbooks/ripgrep.yml"
PLAY="${HOME}/.local/bin/ansible-playbook"
INVENTORY="${HOME}/.local/bin/ansible-inventory"

[[ -x "${PLAY}" && -x "${INVENTORY}" ]] ||
  fail 'Pinned user-level Ansible missing; run bash controller-setup.sh.'
version_output="$("${PLAY}" --version)"
version_first_line="${version_output%%$'\n'*}"
[[ "${version_first_line}" == *'[core 2.21.5]'* ]] ||
  fail 'Controller must be pinned Ansible Core 2.21.5.'
bash -n "${ROOT}/controller-setup.sh"
bash -n "${ROOT}/tests/test-offline.sh"

# Inventory validation intentionally checks exactly one managed host.
inventory_json="$("${INVENTORY}" -i "${INV}" --list)"
python3 -c '
import json, sys
inv = json.load(sys.stdin)
hosts = inv.get("ai_lab_local", {}).get("hosts", [])
if hosts != ["localhost"]:
    raise SystemExit(f"Expected only localhost, found: {hosts!r}")
print("Inventory localhost: PASS")
' <<<"${inventory_json}"

"${PLAY}" -i "${INV}" "${BOOK}" --syntax-check
list_hosts="$("${PLAY}" -i "${INV}" "${BOOK}" --list-hosts)"
[[ "${list_hosts}" == *'localhost'* && "${list_hosts}" == *'hosts (1)'* ]] ||
  fail 'Target list must contain exactly one localhost.'

# Negative test: removal MUST refuse when the operator did not opt in.
# No --become or sudo is involved. No package removal is possible here.
set +e
rejection="$("${PLAY}" -i "${INV}" "${BOOK}" \
    -e ai_lab_ripgrep_action=absent 2>&1)"
status=$?
set -e
[[ "${status}" -ne 0 ]] ||
  fail 'Unapproved removal unexpectedly succeeded.'
[[ "${rejection}" == *'Deletion is disabled by default'* ]] ||
  fail "Negative test failed for another reason, not approval guard: ${rejection}"

printf '%s\n' 'PASS: syntax, localhost-only inventory and default removal refusal.'
printf '%s\n' 'NOT TESTED: actual installation, reboot, teardown, idempotence, security and lab-test S2 acceptance.'
