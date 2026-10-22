#!/usr/bin/env bash
# Optional AI Lab developer workstation tool (never part of S0/S1/S1-D default).
# Ubuntu 24.04 amd64: pinned Codex CLI + scoped Linux sandbox/AppArmor setup.
set -euo pipefail

CODEX_VERSION='0.163.0'
PREFIX="$HOME/.local/share/ai-lab-devtools/codex"
EXPERIMENT_PREFIX="$HOME/.local/share/ai-lab-experiments/codex"
USER_BIN="$HOME/.local/bin"
SHORTCUT="$USER_BIN/codex"
PROXY='http://127.0.0.1:10808'
PROFILE_SOURCE='/usr/share/apparmor/extra-profiles/bwrap-userns-restrict'
PROFILE_TARGET='/etc/apparmor.d/bwrap-userns-restrict'

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }

require_host() {
    [[ "$EUID" -ne 0 ]] || fail 'Run as the operator, not root.'
    [[ -n "$HOME" && "$HOME" == /* ]] || fail 'Expected absolute HOME.'
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "$ID" == ubuntu && "$VERSION_ID" == '24.04' && "$(uname -m)" == x86_64 ]] ||
        fail 'This optional module targets only Ubuntu 24.04 x86_64.'
}

ensure_apt_packages() {
    local package
    local missing=()
    for package in "$@"; do
        dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed' ||
            missing+=("$package")
    done
    (("${#missing[@]}" == 0)) && return 0
    [[ -f /etc/apt/apt.conf.d/80proxy ]] ||
        fail 'S0 APT proxy configuration not found; run accepted S0 first.'
    note "Installing required Ubuntu packages: ${missing[*]}"
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
}

launcher_path() {
    local target
    [[ -L "$SHORTCUT" ]] || fail "Missing symlink $SHORTCUT (run setup)."
    target="$(readlink -- "$SHORTCUT")"
    case "$target" in
        "$PREFIX/node_modules/@openai/codex/bin/codex.js" | "$EXPERIMENT_PREFIX/node_modules/@openai/codex/bin/codex.js") ;;
        *) fail "Refusing unrecognized Codex launcher target: $target" ;;
    esac
    [[ -f "$target" ]] || fail "Codex launcher target missing: $target"
    printf '%s\n' "$target"
}

check_cli() {
    local launcher output
    command -v node >/dev/null || fail 'Node.js missing.'
    launcher="$(launcher_path)"
    output="$(node "$launcher" --version)" ||
        fail 'Codex could not start.'
    [[ "$output" == "codex-cli $CODEX_VERSION" ]] ||
        fail "Expected codex-cli $CODEX_VERSION, received $output"
    note "Codex: $output"
    note "Executable: $SHORTCUT -> $launcher"
    if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
        note 'PATH note: export PATH="$HOME/.local/bin:$PATH"'
    fi
}

install_cli() {
    # Reuse an already-working experiment-local 0.163.0 installation; do
    # not mutate the original n8n experiment or overwrite a user's Codex.
    if [[ -e "$SHORTCUT" || -L "$SHORTCUT" ]]; then
        check_cli
        note 'Existing compatible Codex reused; no package replacement.'
        return
    fi
    ensure_apt_packages nodejs npm
    command -v npm >/dev/null || fail 'npm missing.'
    mkdir -p -- "$PREFIX" "$USER_BIN"
    note "Installing pinned @openai/codex@$CODEX_VERSION to user-local prefix."
    HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" \
    http_proxy="$PROXY" https_proxy="$PROXY" \
    npm_config_proxy="$PROXY" npm_config_https_proxy="$PROXY" \
        npm --prefix "$PREFIX" install \
        --registry=https://registry.npmjs.org/ \
        --no-save --no-package-lock --no-audit --no-fund --ignore-scripts \
        "@openai/codex@$CODEX_VERSION"
    local target="$PREFIX/node_modules/@openai/codex/bin/codex.js"
    [[ -f "$target" ]] || fail "Installed package missing $target"
    [[ ! -e "$SHORTCUT" && ! -L "$SHORTCUT" ]] ||
        fail "Refusing to overwrite an existing executable at $SHORTCUT"
    ln -s -- "$target" "$SHORTCUT"
    check_cli
}

codex_sandbox_test() {
    # Invoke pinned/user-local package directly; no PATH modification needed.
    local launcher
    launcher="$(launcher_path)"
    node "$launcher" sandbox -- /bin/true
}

ensure_sandbox() {
    ensure_apt_packages bubblewrap
    if codex_sandbox_test >/dev/null 2>&1; then
        note 'PASS: Codex sandbox startup (no AppArmor changes required).'
        return
    fi

    # Only Ubuntu 24.04 with the restrictive setting receives the targeted
    # Ubuntu-provided AppArmor profile. Never disable the global policy.
    local userns_restriction
    userns_restriction="$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null || true)"
    [[ "$userns_restriction" == 1 ]] ||
        fail 'Sandbox test failed for a reason outside the documented restricted-AppArmor case. Investigate manually.'

    ensure_apt_packages apparmor-profiles apparmor-utils
    [[ -f "$PROFILE_SOURCE" ]] ||
        fail "Ubuntu AppArmor profile not found: $PROFILE_SOURCE"

    # Competing loaded profiles for bwrap require operator review rather
    # than layering a second attachment.
    if sudo aa-status | grep -Eq '^[[:space:]]+(bwrap|unpriv_bwrap)[[:space:]]*$'; then
        fail 'bwrap AppArmor profile is already loaded yet sandbox failed. Diagnose before changing policy.'
    fi
    if [[ -e "$PROFILE_TARGET" ]]; then
        cmp -s "$PROFILE_SOURCE" "$PROFILE_TARGET" ||
            fail "Existing profile differs from packaged profile: $PROFILE_TARGET"
    else
        # Refuse competing local policies that mention the bwrap executable.
        if sudo grep -RIl --exclude='bwrap-userns-restrict' --exclude-dir='cache' '/usr/bin/bwrap' /etc/apparmor.d 2>/dev/null | grep -q .; then
            fail 'Another local AppArmor policy references bwrap; manual review required.'
        fi
        sudo install -m 0644 -- "$PROFILE_SOURCE" "$PROFILE_TARGET"
    fi
    sudo apparmor_parser -r "$PROFILE_TARGET"
    [[ "$(sysctl -n kernel.apparmor_restrict_unprivileged_userns)" == 1 ]] ||
        fail 'AppArmor userns restriction unexpectedly changed.'
    codex_sandbox_test ||
        fail 'Codex sandbox still fails after loading profile; no unsandboxed fallback.'
    note 'PASS: Codex sandbox after loading scoped Ubuntu AppArmor profile.'
}

verify() {
    require_host
    check_cli
    command -v bwrap >/dev/null || fail 'bubblewrap not installed.'
    [[ "$(sysctl -n kernel.apparmor_restrict_unprivileged_userns 2>/dev/null)" == 1 ]] ||
        fail 'Global AppArmor user-namespace restriction is not enabled.'
    codex_sandbox_test || fail 'Codex Linux sandbox failed; see README troubleshooting.'
    note 'PASS: optional AI Lab Codex CLI and Linux sandbox.'
    note 'Authentication, editor integration and actual agent tasks are NOT verified by this command.'
}

require_host
case "${1:-help}" in
    setup)
        install_cli
        ensure_sandbox
        verify
        ;;
    verify) verify ;;
    help|-h|--help)
        cat <<'HELP'
Optional AI Lab Codex developer tool (Ubuntu 24.04 amd64 only):
  bash bootstrap/devtools/codex/setup.sh setup
  bash bootstrap/devtools/codex/setup.sh verify

- Pin @openai/codex 0.163.0; install under ~/.local/share/ai-lab-devtools.
- Reuse previously verified experiment-local 0.163.0 without replacement.
- Obtain Node/npm and bwrap only when missing, via S0's APT proxy.
- If sandbox test fails under Ubuntu 24.04 restrictive AppArmor, load only
  the official bwrap-userns-restrict profile. Never disable AppArmor globally.
- No ChatGPT login, MCP token, Docker socket access or VS Code install.
- Not invoked by any default S0/S1/S1-D targets.
HELP
        ;;
    *) fail "Unknown action '$1' (use setup or verify)." ;;
esac
