#!/usr/bin/env bash
# Read-only local VS Code role syntax + refusal of unauthorized deletion.
set -Eeuo pipefail
(( EUID != 0 )) || { echo 'Run as normal operator' >&2; exit 1; }
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export ANSIBLE_CONFIG="${ROOT}/ansible.cfg"
export PATH="${HOME}/.local/bin:${PATH}"
PLAY="${HOME}/.local/bin/ansible-playbook"
BOOK="${ROOT}/playbooks/vscode.yml"
[[ -x "${PLAY}" ]] || { echo 'Missing pinned ansible-playbook' >&2; exit 1; }
"${PLAY}" "${BOOK}" --syntax-check
hosts="$("${PLAY}" "${BOOK}" --list-hosts)"
[[ "${hosts}" == *'localhost'* && "${hosts}" == *'hosts (1)'* ]] ||
 { echo 'Unexpected host targets' >&2; exit 1; }

# Does not run sudo / change packages; deletion guard must reject before APT.
set +e
out="$("${PLAY}" "${BOOK}" -e ai_lab_vscode_action=absent 2>&1)"
rc=$?
set -e
[[ "${rc}" -ne 0 && "${out}" == *'Set ai_lab_vscode_allow_remove=true'* ]] ||
 { printf 'Unexpected removal guard result:\n%s\n' "${out}" >&2; exit 1; }
echo 'PASS: VS Code playbook syntax, localhost-only target, removal consent guard.'
echo 'NOT TESTED: key download, package install, idempotence, GUI and real cleanup.'
