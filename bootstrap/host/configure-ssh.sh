#!/usr/bin/env bash
set -euo pipefail

[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as a regular user' >&2; exit 1; }
command -v ssh >/dev/null || { echo 'ERROR: openssh-client is required (S0)' >&2; exit 1; }
[[ -x /usr/bin/nc ]] || { echo 'ERROR: netcat-openbsd is required; run bootstrap.sh' >&2; exit 1; }

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ai-lab"
config="$config_dir/github-ssh.conf"
[[ ! -L "$config_dir" ]] || { echo "ERROR: refusing symlinked directory: $config_dir" >&2; exit 1; }
mkdir -p "$config_dir"
chmod 700 "$config_dir"
[[ ! -L "$config" ]] || { echo "ERROR: refusing symlinked file: $config" >&2; exit 1; }

# A dedicated alias/config avoids modifying ~/.ssh/config or existing Git remotes.
# The SSH server key is never fetched or trusted automatically.
expected=$(cat <<'CONFIG'
Host ai-lab-github
    HostName ssh.github.com
    Port 443
    User git
    ProxyCommand /usr/bin/nc -X connect -x 127.0.0.1:10808 %h %p
    StrictHostKeyChecking ask
CONFIG
)
if [[ -e "$config" ]]; then
    [[ -f "$config" && "$(cat "$config")" == "$expected" ]] || {
        echo "ERROR: existing config differs; refusing overwrite: $config" >&2
        exit 1
    }
    chmod 600 "$config"
    echo "Configuration already matches: $config"
else
    umask 077
    temp="$(mktemp "$config_dir/.github-ssh.XXXXXX")"
    trap 'rm -f "$temp"' EXIT
    printf '%s\n' "$expected" > "$temp"
    # Atomic, no-clobber creation: do not overwrite a concurrently created file.
    ln "$temp" "$config"
    rm -f "$temp"
    trap - EXIT
    echo "Created isolated SSH configuration: $config"
fi

resolved="$(ssh -G -F "$config" ai-lab-github)"
grep -qx 'hostname ssh.github.com' <<< "$resolved"
grep -qx 'port 443' <<< "$resolved"
grep -qx 'user git' <<< "$resolved"
grep -q '^proxycommand /usr/bin/nc -X connect -x 127.0.0.1:10808 ' <<< "$resolved"
echo 'SSH configuration syntax and routing: OK (not an authentication test).'
