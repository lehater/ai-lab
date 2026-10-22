#!/usr/bin/env bash
# Optional Codex CLI setup for the lab-test n8n/MCP experiment only.
# Not an AI Lab host/bootstrap module and not an unattended login.
set -euo pipefail

CODEX_VERSION='0.163.0'
PREFIX="$HOME/.local/share/ai-lab-experiments/codex"
BIN_DIR="$HOME/.local/bin"
LAUNCHER="$PREFIX/node_modules/@openai/codex/bin/codex.js"
SHORTCUT="$BIN_DIR/codex"
PROXY='http://127.0.0.1:10808'

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

check_host() {
    [[ "$EUID" -ne 0 ]] || fail 'Run as the desktop operator, not root.'
    [[ -n "${HOME:-}" && "$HOME" == /* ]] || fail 'HOME must be an absolute user directory.'
    [[ -f /etc/os-release ]] || fail 'Missing /etc/os-release'
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 && "$(uname -m)" == x86_64 ]] ||
        fail 'Experimental installer targets Ubuntu 24.04 / x86_64 only.'
}

check_node() {
    command -v node >/dev/null && command -v npm >/dev/null ||
        fail 'Node.js/npm unavailable; run codex-setup.sh install'
    local node_version major
    node_version="$(node --version)"
    [[ "$node_version" =~ ^v([0-9]+)\. ]] || fail "Unexpected Node version: $node_version"
    major="${BASH_REMATCH[1]}"
    (( major >= 16 )) || fail "Node.js >=16 required, found $node_version"
    printf 'Node.js %s / npm %s\n' "$node_version" "$(npm --version)"
}

install_node_if_needed() {
    if command -v node >/dev/null && command -v npm >/dev/null; then
        check_node
        return
    fi
    [[ -f /etc/apt/apt.conf.d/80proxy ]] ||
        fail 'S0 APT proxy config missing; do not bootstrap system packages outside S0.'
    command -v sudo >/dev/null || fail 'sudo required to install missing nodejs/npm via Ubuntu APT.'
    echo 'Installing missing Node.js/npm from Ubuntu APT (host packages, explicit experimental prerequisite).'
    sudo apt-get update
    sudo apt-get install -y nodejs npm
    check_node
}

check_shortcut_safety() {
    if [[ -e "$SHORTCUT" || -L "$SHORTCUT" ]]; then
        [[ -L "$SHORTCUT" && "$(readlink -- "$SHORTCUT")" == "$LAUNCHER" ]] ||
            fail "Refusing to overwrite an existing Codex executable/symlink: $SHORTCUT"
    fi
}

verify() {
    check_host
    check_node
    check_shortcut_safety
    [[ -f "$LAUNCHER" ]] || fail "Missing experimental Codex package: $LAUNCHER"
    [[ -L "$SHORTCUT" ]] || fail "Missing Codex launcher: $SHORTCUT"
    local output
    output="$(node "$LAUNCHER" --version)" ||
        fail 'Codex failed to start; check Node and native npm optional dependencies.'
    [[ "$output" == "codex-cli $CODEX_VERSION" ]] ||
        fail "Expected codex-cli $CODEX_VERSION, received: $output"
    printf 'PASS: %s (%s)\n' "$output" "$LAUNCHER"
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo 'For this shell: export PATH="$HOME/.local/bin:$PATH"'
    elif [[ "$(command -v codex || true)" != "$SHORTCUT" ]]; then
        echo "WARNING: Another Codex is earlier in PATH: $(command -v codex || true)"
        echo 'For this shell: export PATH="$HOME/.local/bin:$PATH"'
    fi
    echo 'Authentication not checked. Start codex and sign in separately.'
}

install() {
    check_host
    check_shortcut_safety
    install_node_if_needed
    # Don't overwrite an unrelated installation. npm is scoped to the private
    # experiment prefix, not a root/global npm directory.
    if [[ -f "$LAUNCHER" && -L "$SHORTCUT" ]] &&
        [[ "$(node "$LAUNCHER" --version 2>/dev/null || true)" == "codex-cli $CODEX_VERSION" ]]; then
        echo 'Pinned experimental Codex already installed; no npm write required.'
        verify
        return
    fi
    mkdir -p -- "$PREFIX" "$BIN_DIR"
    command -v npm >/dev/null || fail 'npm missing after Node installation.'
    echo "Installing @openai/codex@$CODEX_VERSION to user-local experimental directory."
    echo 'npm uses S0 Xray proxy (127.0.0.1:10808). No global npm install or sudo.'
    # npm proxy env is scoped to this single command. Do not print credentials.
    HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" \
    http_proxy="$PROXY" https_proxy="$PROXY" \
    npm_config_proxy="$PROXY" npm_config_https_proxy="$PROXY" \
        npm --prefix "$PREFIX" install \
        --registry=https://registry.npmjs.org/ \
        --no-save --no-package-lock --no-audit --no-fund --ignore-scripts \
        "@openai/codex@$CODEX_VERSION"
    [[ -f "$LAUNCHER" ]] || fail 'npm completed but Codex launcher is missing.'
    if [[ ! -L "$SHORTCUT" ]]; then
        ln -s -- "$LAUNCHER" "$SHORTCUT"
    fi
    verify
}

case "${1:-help}" in
    install) install ;;
    verify) verify ;;
    help|-h|--help)
        cat <<'HELP'
Experimental Codex CLI setup for lab-test only:
  bash experiments/workflow-automation-n8n/codex-setup.sh install
  bash experiments/workflow-automation-n8n/codex-setup.sh verify

- Ubuntu 24.04 x86_64 only.
- Missing Node/npm installed via Ubuntu APT (may require sudo).
- Installs pinned @openai/codex@0.163.0 under ~/.local/share/ai-lab-experiments/codex.
- Adds ~/.local/bin/codex symlink only if safe.
- npm downloads use the existing S0 Xray proxy. No credentials in Git.
- Does not authenticate Codex or configure n8n MCP.
- Not part of S1/S2 Infrastructure Core, and no automatic host cleanup.
HELP
        ;;
    *) fail "Unknown command '$1'. Use help." ;;
esac
