#!/usr/bin/env bash
# S2 optional-host controller bootstrap; intentionally independent of S0/S1/S1-D.
set -Eeuo pipefail

ANSIBLE_CORE_VERSION='2.21.5'
ANSIBLE_BIN="${HOME}/.local/bin/ansible-playbook"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

(( EUID != 0 )) || fail 'Run as the normal Ubuntu operator, not root.'
[[ -r /etc/os-release ]] || fail 'Missing /etc/os-release.'
# shellcheck source=/dev/null
source /etc/os-release
[[ "${ID:-}" == ubuntu && "${VERSION_ID:-}" == '24.04' && "$(uname -m)" == x86_64 ]] ||
  fail 'This first slice supports Ubuntu 24.04 amd64 only.'
[[ -x /usr/bin/python3.12 ]] || fail 'Python 3.12 is required for ansible-core 2.21.'
[[ -d "${HOME}" ]] || fail 'HOME directory unavailable.'

if ! command -v pipx >/dev/null 2>&1; then
  printf '%s\n' 'Installing pipx from the configured signed Ubuntu APT repositories...'
  sudo apt-get update
  sudo apt-get install --no-install-recommends -y pipx python3-venv
fi

if [[ -e "${ANSIBLE_BIN}" || -L "${ANSIBLE_BIN}" ]]; then
  [[ -x "${ANSIBLE_BIN}" ]] || fail 'Existing Ansible entrypoint is not executable; operator review required.'
  version_output="$("${ANSIBLE_BIN}" --version)"
  first_line="${version_output%%$'\n'*}"
  [[ "${first_line}" == *"[core ${ANSIBLE_CORE_VERSION}]"* ]] ||
    fail "Ansible entrypoint already exists but is not core ${ANSIBLE_CORE_VERSION}; do not overwrite it."
  printf 'Existing pinned Ansible controller found: %s\n' "${first_line}"
else
  printf '%s\n' 'Installing ansible-core into a user-owned isolated pipx environment...'
  pipx install --python /usr/bin/python3.12 "ansible-core==${ANSIBLE_CORE_VERSION}"
  [[ -x "${ANSIBLE_BIN}" ]] ||
    fail 'pipx completed but expected ~/.local/bin/ansible-playbook is unavailable.'
fi

version_output="$("${ANSIBLE_BIN}" --version)"
  first_line="${version_output%%$'\n'*}"
[[ "${first_line}" == *"[core ${ANSIBLE_CORE_VERSION}]"* ]] ||
  fail "Expected Ansible ${ANSIBLE_CORE_VERSION}, got: ${first_line}"
printf 'Controller bootstrap: READY (%s)\n' "${first_line}"
printf '%s\n' 'Use ~/.local/bin/ansible-playbook or export PATH="$HOME/.local/bin:$PATH".'
printf '%s\n' 'This is local validation only, not S2/lab-test acceptance.'
