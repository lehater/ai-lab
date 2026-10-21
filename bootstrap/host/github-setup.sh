#!/usr/bin/env bash
set -euo pipefail

[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as a regular user, not root' >&2; exit 1; }
command -v ssh-keygen >/dev/null || { echo 'ERROR: openssh-client is required' >&2; exit 1; }
ssh_dir="$HOME/.ssh"
private="$ssh_dir/id_ed25519"
public="$private.pub"
[[ ! -L "$ssh_dir" && ! -L "$private" && ! -L "$public" ]] || {
    echo 'ERROR: SSH key path is symlinked; manual review required' >&2; exit 1;
}
mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"
if [[ -e "$private" || -e "$public" ]]; then
    [[ -f "$private" && -f "$public" ]] || {
        echo 'ERROR: incomplete existing SSH key pair; refusing to replace either file' >&2; exit 1;
    }
    echo "Reusing existing SSH public key: $public"
else
    [[ -t 0 ]] || { echo 'ERROR: key generation requires an interactive terminal' >&2; exit 1; }
    read -r -p "Create a new Ed25519 SSH key at $private? [y/N] " answer
    [[ "$answer" == y || "$answer" == Y ]] || {
        echo 'Cancelled; no SSH key created.'; exit 0;
    }
    # ssh-keygen prompts for a passphrase; never silently create an unencrypted key.
    ssh-keygen -t ed25519 -a 100 -f "$private" -C 'ai-lab'
fi
[[ -f "$private" && -f "$public" ]] || { echo 'ERROR: SSH key pair is incomplete' >&2; exit 1; }
ssh-keygen -lf "$public" >/dev/null || { echo 'ERROR: invalid SSH public key' >&2; exit 1; }
chmod 600 "$private"
chmod 644 "$public"

echo
printf '%s\n' '=== PUBLIC KEY (safe to share with GitHub) ==='
cat "$public"
echo
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null; then
    wl-copy --type text/plain < "$public" && echo 'Public key copied to Wayland clipboard.' || echo 'Clipboard unavailable; copy the key shown above.'
elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null; then
    xclip -selection clipboard < "$public" && echo 'Public key copied to X11 clipboard.' || echo 'Clipboard unavailable; copy the key shown above.'
else
    echo 'Clipboard tool unavailable; copy the public key shown above.'
fi

url='https://github.com/settings/keys'
echo "GitHub SSH key settings: $url"
if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && command -v xdg-open >/dev/null; then
    if xdg-open "$url" >/dev/null 2>&1; then
        echo 'Sent GitHub settings URL to the desktop browser.'
    else
        echo 'Browser could not be opened; use the URL printed above.'
    fi
else
    echo 'No detected desktop browser session; open the URL manually.'
fi
cat <<'INSTRUCTIONS'
Add ONLY the public key to GitHub (New SSH key → Authentication Key).
Existing SSH keys and Git remotes were not changed.
A browser may need its own proxy settings even when APT/curl work.
Then run: make github-verify
INSTRUCTIONS

if [[ -t 0 ]]; then
    read -r -p "After adding the public key, press Enter to verify SSH (or type 'skip'): " answer
    if [[ "$answer" != skip ]]; then
        DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        bash "$DIR/github-verify.sh"
    else
        echo 'SSH verification postponed. Run: make github-verify'
    fi
fi
