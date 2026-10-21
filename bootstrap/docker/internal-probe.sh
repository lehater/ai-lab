#!/usr/bin/env bash
set -euo pipefail

# Controlled experiment only. Docker creates a temporary internal bridge
# and associated Docker-managed firewall rules; EXIT cleanup removes them.
# No Xray changes, published ports, persistent containers or sudo group edits.
[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as desktop user, not root' >&2; exit 1; }
for cmd in sudo docker; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing $cmd" >&2; exit 1; }
done
image='curlimages/curl:8.16.0'
name="ai-lab-internal-probe-$$"
network_id=''

cleanup() {
    status=$?
    trap - EXIT
    if [[ -n "$network_id" ]]; then
        if sudo docker network rm "$network_id" >/dev/null; then
            echo 'CLEANUP: temporary internal network removed.'
        else
            echo "ERROR: temporary network $network_id remains; remove it manually." >&2
            status=1
        fi
    fi
    exit "$status"
}
trap cleanup EXIT

# No hidden pull on the untested network. Download only via the already
# validated daemon registry proxy if the diagnostic image is absent.
if ! sudo docker image inspect "$image" >/dev/null 2>&1; then
    echo "Downloading diagnostic image: $image"
    sudo docker image pull "$image"
fi

echo '=== Create a temporary isolated Docker bridge (Docker-managed rules only) ==='
network_id="$(sudo docker network create --driver bridge --internal \
    --label ai-lab.diagnostic=temporary "$name")"
[[ -n "$network_id" ]] || { echo 'ERROR: no network ID returned' >&2; exit 1; }
internal="$(sudo docker network inspect "$network_id" --format '{{.Internal}}')"
[[ "$internal" == true ]] || { echo 'ERROR: network is not internal; refusing test' >&2; exit 1; }
sudo docker network inspect "$network_id" \
    --format 'network={{.Name}} internal={{.Internal}} gateway={{(index .IPAM.Config 0).Gateway}}'

echo '=== Test direct HTTPS from the internal-only network (expected blocked) ==='
if sudo docker run --rm --network "$network_id" \
    --cap-drop ALL --security-opt no-new-privileges \
    "$image" --noproxy '*' \
    --head --location --fail --silent --show-error \
    --connect-timeout 5 --max-time 15 \
    --output /dev/null --write-out 'direct HTTP status: %{http_code}\n' \
    https://github.com/; then
    echo 'FAIL: direct HTTPS unexpectedly succeeded from internal Docker network.' >&2
    exit 1
else
    echo 'OBSERVED: direct HTTPS to github.com failed from internal network (expected).'
fi

echo 'PASS: Docker internal bridge direct HTTPS probe (not a full egress or LAN security audit).'
