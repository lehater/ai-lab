#!/usr/bin/env bash
set -euo pipefail

# Start v2rayN in the current GNOME desktop session and wait for Xray.
[[ "$EUID" -ne 0 ]] || { echo "ERROR: run as desktop user, not root" >&2; exit 1; }
[[ -x /usr/bin/v2rayn ]] || { echo "ERROR: v2rayN is not installed" >&2; exit 1; }
[[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]] || {
  echo "ERROR: graphical session required for first v2rayN launch" >&2; exit 1;
}

listener_ready() {
  (echo > /dev/tcp/127.0.0.1/10808) >/dev/null 2>&1
}

if listener_ready; then
  echo "Xray already listening at 127.0.0.1:10808"
  exit 0
fi

if ! pgrep -x v2rayn >/dev/null 2>&1; then
  echo "Launching v2rayN in the current graphical session..."
  nohup /usr/bin/v2rayn </dev/null >/dev/null 2>&1 &
else
  echo "v2rayN is already running; waiting for Xray..."
fi

echo "If necessary, select and activate a proxy server in the v2rayN window."
for ((seconds=0; seconds<180; seconds++)); do
  if listener_ready; then
    echo "Xray listener ready at 127.0.0.1:10808"
    exit 0
  fi
  sleep 1
done
echo "ERROR: Xray did not become ready within 180 seconds." >&2
echo "Check v2rayN GUI, selected server, and its logs, then rerun Stage 0." >&2
exit 1
