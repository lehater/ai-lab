#!/usr/bin/env bash
set -euo pipefail

# Diagnostics only: no daemon edits, firewall changes, published ports or
# persistent containers. Do not interpret this as a LAN isolation test.
image='curlimages/curl:8.16.0'
[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as desktop user, not root' >&2; exit 1; }
for cmd in sudo docker ss awk; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing $cmd" >&2; exit 1; }
done

echo '=== Host TCP listeners on proxy port 10808 ==='
sudo ss -lntp | awk 'NR == 1 || $4 ~ /:10808$/'
echo '=== Default Docker bridge gateway ==='
sudo docker network inspect bridge \
    --format 'network={{.Name}} driver={{.Driver}} gateway={{(index .IPAM.Config 0).Gateway}}'

echo "=== Obtain diagnostic curl image via Docker daemon: $image ==="
sudo docker image pull "$image"
sudo docker image inspect "$image" --format 'image={{.Id}}'

echo '=== Test HTTPS through host.docker.internal:10808 from a bridge container ==='
if sudo docker run --rm --network bridge \
    --add-host host.docker.internal:host-gateway \
    --cap-drop ALL --security-opt no-new-privileges \
    "$image" --noproxy '' \
    --proxy http://host.docker.internal:10808 \
    --head --location --fail --silent --show-error \
    --connect-timeout 5 --max-time 20 \
    --output /dev/null --write-out 'proxy HTTP status: %{http_code}\n' \
    https://github.com/; then
    echo 'OBSERVED: bridge container can access HTTPS through the specified host proxy.'
else
    echo 'OBSERVED: bridge container cannot use the specified host proxy in this test.'
fi

echo '=== Test direct HTTPS (proxy bypass) from the bridge container ==='
if sudo docker run --rm --network bridge \
    --cap-drop ALL --security-opt no-new-privileges \
    "$image" --noproxy '*' \
    --head --location --fail --silent --show-error \
    --connect-timeout 5 --max-time 20 \
    --output /dev/null --write-out 'direct HTTP status: %{http_code}\n' \
    https://github.com/; then
    echo 'WARNING: direct bridge-container HTTPS egress succeeded without the proxy.'
else
    echo 'OBSERVED: direct bridge-container HTTPS failed in this test.'
fi

echo 'DIAGNOSTICS COMPLETE: these observations are not proof of LAN isolation.'
