#!/usr/bin/env bash
set -euo pipefail
proxy="http://127.0.0.1:10808"
echo "=== PACKAGE ==="
dpkg-query -W -f='${Package} ${Version} ${Status}\n' v2rayn
echo "=== XRAY LISTENER ==="
ss -lnt | grep ':10808 '
if command -v curl >/dev/null 2>&1; then
  echo "=== HTTP ==="
  curl --noproxy "" --proxy "$proxy" -fsS -o /dev/null -w 'HTTP %{http_code}\n' --max-time 25 https://github.com
  echo "=== SOCKS5 ==="
  curl --noproxy "" --proxy socks5h://127.0.0.1:10808 -fsS -o /dev/null -w 'HTTP %{http_code}\n' --max-time 25 https://github.com
else
  echo "=== HTTP (wget) ==="
  wget -q --spider -T 25 -e use_proxy=yes -e https_proxy="$proxy" https://github.com
  echo "HTTP OK"
fi
echo "Proxy verification PASSED."
