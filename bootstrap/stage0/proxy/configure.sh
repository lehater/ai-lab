#!/usr/bin/env bash
set -euo pipefail
[[ "$EUID" -ne 0 ]] || { echo "Run as the desktop user, not root" >&2; exit 1; }
[[ -x /usr/bin/v2rayn ]] || { echo "v2rayN is not installed" >&2; exit 1; }
dir="$HOME/.config/autostart"
mkdir -p "$dir"
cat > "$dir/v2rayn.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=v2rayN
Exec=/usr/bin/v2rayn
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
chmod 644 "$dir/v2rayn.desktop"
echo "v2rayN autostart configured for subsequent GNOME logins."
