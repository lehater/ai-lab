#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for script in "$DIR"/{bootstrap.sh,configure-ssh.sh,verify.sh}; do bash -n "$script"; done
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch"
export XDG_CONFIG_HOME="$scratch/config"
mkdir -p "$HOME/.ssh" "$scratch/bin"
printf '# preserved\n' > "$HOME/.ssh/config"
# A mock checks only our file-generation behavior, not actual OpenSSH parsing.
# Live configuration parsing and authenticated networking require lab-test.
cat > "$scratch/bin/ssh" <<'MOCK'
#!/usr/bin/env bash
[[ "$1" == -G && "$2" == -F && "$4" == ai-lab-github ]] || exit 7
file="$3"
grep -qx 'Host ai-lab-github' "$file"
grep -q 'HostName ssh.github.com' "$file"
grep -q 'Port 443' "$file"
grep -q 'User git' "$file"
grep -q 'ProxyCommand /usr/bin/nc -X connect -x 127.0.0.1:10808 %h %p' "$file"
printf 'hostname ssh.github.com\nport 443\nuser git\nproxycommand /usr/bin/nc -X connect -x 127.0.0.1:10808 ssh.github.com 443\n'
MOCK
chmod 755 "$scratch/bin/ssh"
export PATH="$scratch/bin:$PATH"

bash "$DIR/configure-ssh.sh" >/dev/null
config="$XDG_CONFIG_HOME/ai-lab/github-ssh.conf"
[[ -f "$config" && "$(stat -c '%a' "$config")" == 600 ]]
checksum="$(sha256sum "$config")"
bash "$DIR/configure-ssh.sh" >/dev/null
[[ "$(sha256sum "$config")" == "$checksum" ]]
[[ "$(cat "$HOME/.ssh/config")" == '# preserved' ]]

printf '\n# conflicting user change\n' >> "$config"
if bash "$DIR/configure-ssh.sh" >/dev/null 2>&1; then
    echo 'FAIL: a conflicting user config was overwritten' >&2; exit 1
fi
[[ "$(tail -n 1 "$config")" == '# conflicting user change' ]]
echo 'PASS: shell syntax, mocked config rendering, idempotency, safe conflict refusal.'
