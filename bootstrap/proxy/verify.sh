#!/usr/bin/env bash
set -euo pipefail

PROXY="http://127.0.0.1:10808"

echo "=== PACKAGE ==="
dpkg-query -W -f='${Package} ${Version} ${Status}\n' v2rayn

echo "=== XRAY LISTENER ==="
ss -lnt | grep ':10808 '

echo "=== HTTP ==="
curl --noproxy "" --proxy "$PROXY" \
    -fsS -o /dev/null \
    -w 'HTTP %{http_code}\n' \
    --max-time 15 \
    https://github.com

echo "=== SOCKS5 ==="
curl --noproxy "" \
    --proxy socks5h://127.0.0.1:10808 \
    -fsS -o /dev/null \
    -w 'HTTP %{http_code}\n' \
    --max-time 15 \
    https://github.com

echo "Proxy verification PASSED."
