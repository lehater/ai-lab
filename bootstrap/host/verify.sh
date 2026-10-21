#!/usr/bin/env bash
set -euo pipefail

mode="${1:---local}"
[[ "$mode" == --local || "$mode" == --auth ]] || {
    echo 'Usage: verify.sh [--local|--auth]' >&2; exit 2;
}
config="${XDG_CONFIG_HOME:-$HOME/.config}/ai-lab/github-ssh.conf"
[[ -f "$config" && ! -L "$config" ]] || {
    echo "ERROR: missing or unsafe SSH config: $config" >&2; exit 1;
}
[[ "$(stat -c '%a' "$config")" == 600 ]] || {
    echo "ERROR: expected SSH config mode 600: $config" >&2; exit 1;
}
[[ -x /usr/bin/nc ]] || { echo 'ERROR: netcat-openbsd is missing' >&2; exit 1; }
resolved="$(ssh -G -F "$config" ai-lab-github)"
grep -qx 'hostname ssh.github.com' <<< "$resolved"
grep -qx 'port 443' <<< "$resolved"
grep -qx 'user git' <<< "$resolved"
grep -q '^proxycommand /usr/bin/nc -X connect -x 127.0.0.1:10808 ' <<< "$resolved"

curl --noproxy '' --proxy http://127.0.0.1:10808 -fsSIL --max-time 25 -o /dev/null https://github.com/
echo 'S1 local config and proxied HTTPS: PASS (SSH authentication not checked).'

if [[ "$mode" == --auth ]]; then
    echo 'Checking authenticated Git SSH transport; requires registered user key and verified host key.'
    printf -v ssh_cmd 'ssh -F %q -o ConnectTimeout=20 -o StrictHostKeyChecking=yes' "$config"
    GIT_SSH_COMMAND="$ssh_cmd" git ls-remote ai-lab-github:lehater/ai-lab.git HEAD >/dev/null
    echo 'S1 GitHub SSH authentication: PASS.'
fi
