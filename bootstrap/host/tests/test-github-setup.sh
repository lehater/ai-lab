#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash -n "$DIR/github-setup.sh"
bash -n "$DIR/github-verify.sh"

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
export XDG_CONFIG_HOME="$HOME/.config"
export MOCK_LOG="$scratch/log"
export DISPLAY=':99'
unset WAYLAND_DISPLAY
mkdir -p "$HOME/.ssh" "$scratch/bin" "$MOCK_LOG"
chmod 700 "$HOME/.ssh"
printf '# untouched\n' > "$HOME/.ssh/config"
# Dummy fixture plus mocked ssh-keygen: no real key material is created in this test.
printf 'TEST-FIXTURE (not a credential)\n' > "$HOME/.ssh/id_ed25519"
printf 'ssh-ed25519 AAAAFAKE public-test-only\n' > "$HOME/.ssh/id_ed25519.pub"
before="$(sha256sum "$HOME/.ssh/id_ed25519")"

cat > "$scratch/bin/ssh-keygen" <<'MOCK'
#!/usr/bin/env bash
[[ "$1" == '-lf' ]] || exit 3
grep -q '^ssh-ed25519 ' "$2" || exit 4
printf '256 SHA256:mock test (ED25519)\n'
MOCK
cat > "$scratch/bin/xclip" <<'MOCK'
#!/usr/bin/env bash
[[ "$1" == '-selection' && "$2" == 'clipboard' ]] || exit 2
cat > "$MOCK_LOG/clipboard"
MOCK
cat > "$scratch/bin/xdg-open" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$1" > "$MOCK_LOG/browser"
MOCK
chmod +x "$scratch/bin"/*
export PATH="$scratch/bin:$PATH"

bash "$DIR/github-setup.sh" > "$scratch/output1"
bash "$DIR/github-setup.sh" > "$scratch/output2"
[[ "$(sha256sum "$HOME/.ssh/id_ed25519")" == "$before" ]]
[[ "$(cat "$HOME/.ssh/config")" == '# untouched' ]]
[[ "$(cat "$MOCK_LOG/browser")" == 'https://github.com/settings/keys' ]]
cmp "$MOCK_LOG/clipboard" "$HOME/.ssh/id_ed25519.pub"
grep -q 'Reusing existing SSH public key' "$scratch/output2"

# Incomplete pairs and symlinks must fail without writing new credentials.
mv "$HOME/.ssh/id_ed25519.pub" "$scratch/hold.pub"
if bash "$DIR/github-setup.sh" > "$scratch/output3" 2>&1; then
    echo 'FAIL: incomplete key pair was accepted' >&2; exit 1
fi
mv "$scratch/hold.pub" "$HOME/.ssh/id_ed25519.pub"
mv "$HOME/.ssh/id_ed25519.pub" "$scratch/hold.pub"
ln -s "$scratch/hold.pub" "$HOME/.ssh/id_ed25519.pub"
if bash "$DIR/github-setup.sh" > "$scratch/output4" 2>&1; then
    echo 'FAIL: symlinked public key was accepted' >&2; exit 1
fi
rm "$HOME/.ssh/id_ed25519.pub"
mv "$scratch/hold.pub" "$HOME/.ssh/id_ed25519.pub"

# With no key, a redirected/non-interactive process must never auto-create one.
export HOME="$scratch/emptyhome"
mkdir -p "$HOME"
if bash "$DIR/github-setup.sh" </dev/null > "$scratch/output5" 2>&1; then
    echo 'FAIL: non-interactive key generation was accepted' >&2; exit 1
fi
[[ ! -e "$HOME/.ssh/id_ed25519" ]]
echo 'PASS: SSH wizard reuse, clipboard/browser guidance, no overwrite, incomplete/symlink protection, interactive opt-in.'
