#!/usr/bin/env bash
set -euo pipefail

# Disposable acceptance experiment: an internal Docker network plus a
# systemd runtime socket restricted to the associated bridge interface.
# No permanent units, daemon/proxy edits, published ports or firewall policy.
[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as desktop user, not root' >&2; exit 1; }
for cmd in sudo docker curl ss systemctl mktemp; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing command: $cmd" >&2; exit 1; }
done

image='curlimages/curl:8.16.0'
unit='ai-lab-docker-proxy-probe'
socket_file="/run/systemd/system/$unit.socket"
service_file="/run/systemd/system/$unit.service"
port=11080
bridge_iface="br-alab-$$"
network_name="ai-lab-proxy-probe-$$"
network_id=''
units_written=false
tmp=''

cleanup() {
    local result=$?
    trap - EXIT INT TERM
    if [[ "$units_written" == true ]]; then
        sudo systemctl stop "$unit.socket" "$unit.service" >/dev/null 2>&1 || true
        if ! sudo rm -f "$socket_file" "$service_file"; then
            echo "ERROR: failed removing transient systemd units: $unit" >&2
            result=1
        fi
        if ! sudo systemctl daemon-reload; then
            echo 'ERROR: systemd daemon-reload after cleanup failed' >&2
            result=1
        fi
        if sudo test -e "$socket_file" || sudo test -e "$service_file"; then
            echo "ERROR: transient systemd unit files remain: $unit" >&2
            result=1
        else
            echo 'CLEANUP: transient systemd socket and service removed.'
        fi
    fi
    if [[ -n "$network_id" ]]; then
        if sudo docker network rm "$network_id" >/dev/null; then
            echo 'CLEANUP: temporary Docker internal network removed.'
        else
            echo "ERROR: network $network_id remains; remove it manually." >&2
            result=1
        fi
    fi
    if [[ -n "$tmp" ]]; then rm -rf "$tmp"; fi
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Pre-flight before any mutation: avoid clobbering a local unit, interface
# or another running probe.
for file in "$socket_file" "$service_file" \
    "/etc/systemd/system/$unit.socket" "/etc/systemd/system/$unit.service"; do
    if sudo test -e "$file" || sudo test -L "$file"; then
        echo "ERROR: existing unit path; refusing overwrite: $file" >&2; exit 1
    fi
done
if [[ "$(systemctl show --property=LoadState --value "$unit.socket")" != not-found ]]; then
    echo "ERROR: $unit.socket already registered in systemd" >&2; exit 1
fi
if [[ "$(systemctl show --property=LoadState --value "$unit.service")" != not-found ]]; then
    echo "ERROR: $unit.service already registered in systemd" >&2; exit 1
fi
[[ "${#bridge_iface}" -le 15 ]] || { echo 'ERROR: bridge interface name too long' >&2; exit 1; }
if [[ -e "/sys/class/net/$bridge_iface" ]]; then
    echo "ERROR: interface already exists: $bridge_iface" >&2; exit 1
fi
forwarder='/usr/lib/systemd/systemd-socket-proxyd'
[[ -x "$forwarder" ]] || {
    echo "ERROR: $forwarder not installed; check Ubuntu systemd packaging." >&2; exit 1
}
curl --noproxy '' --proxy http://127.0.0.1:10808 \
    --head --fail --silent --show-error --connect-timeout 5 --max-time 20 \
    --output /dev/null https://github.com/
if ! sudo docker image inspect "$image" >/dev/null 2>&1; then
    sudo docker image pull "$image"
fi

tmp="$(mktemp -d)"
echo '=== Create disposable Docker internal bridge ==='
network_id="$(sudo docker network create \
    --driver bridge --internal \
    --opt "com.docker.network.bridge.name=$bridge_iface" \
    --label ai-lab.diagnostic=temporary "$network_name")"
[[ -n "$network_id" ]] || { echo 'ERROR: failed to obtain new network ID' >&2; exit 1; }
internal="$(sudo docker network inspect "$network_id" --format '{{.Internal}}')"
[[ "$internal" == true ]] || { echo 'ERROR: network is not internal' >&2; exit 1; }
gateway="$(sudo docker network inspect "$network_id" \
    --format '{{(index .IPAM.Config 0).Gateway}}')"
[[ "$gateway" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    echo "ERROR: invalid IPv4 gateway: $gateway" >&2; exit 1;
}
[[ -d "/sys/class/net/$bridge_iface" ]] || {
    echo "ERROR: Docker did not create expected bridge interface: $bridge_iface" >&2; exit 1
}
echo "network=$network_name interface=$bridge_iface internal=$internal gateway=$gateway"

# BindToDevice= restricts inbound traffic to this Docker-owned bridge.
# systemd socket activation passes the restricted listener to proxyd;
# proxyd connects to the original loopback Xray HTTP proxy.
cat > "$tmp/$unit.socket" <<EOF
[Unit]
Description=Temporary AI Lab Docker bridge proxy experiment

[Socket]
ListenStream=$gateway:$port
BindToDevice=$bridge_iface
Accept=no
Service=$unit.service
EOF
cat > "$tmp/$unit.service" <<EOF
[Unit]
Description=Temporary AI Lab Docker bridge -> loopback Xray forwarder

[Service]
Type=notify
User=nobody
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
CapabilityBoundingSet=
AmbientCapabilities=
ExecStart=$forwarder 127.0.0.1:10808
EOF
# Mark for cleanup before the first write, even if installing one file fails.
units_written=true
sudo install -m 0644 "$tmp/$unit.socket" "$socket_file"
sudo install -m 0644 "$tmp/$unit.service" "$service_file"
sudo systemctl daemon-reload
sudo systemctl start "$unit.socket"
sudo systemctl is-active --quiet "$unit.socket" || {
    echo 'ERROR: temporary socket is not active' >&2; exit 1
}
echo '=== Bridge-scoped temporary listener ==='
sudo ss -lntp | grep -F "$gateway:$port" || {
    echo 'ERROR: expected bridge-scoped listener absent' >&2; exit 1
}

echo '=== HTTPS from internal container through bridge-scoped proxy ==='
sudo docker run --rm --network "$network_id" \
    --cap-drop ALL --security-opt no-new-privileges \
    "$image" --noproxy '' \
    --proxy "http://$gateway:$port" \
    --head --fail --silent --show-error \
    --connect-timeout 5 --max-time 25 \
    --output /dev/null --write-out 'proxy HTTP status: %{http_code}\n' \
    https://github.com/
echo 'PASS: internal Docker container HTTPS via bridge-scoped Xray forwarder.'

echo '=== Direct HTTPS to literal public IP (no DNS, expected blocked) ==='
# Only connectivity is tested; -k avoids making certificate validity of
# this diagnostic IP part of an egress result. No credentials are sent.
if sudo docker run --rm --network "$network_id" \
    --cap-drop ALL --security-opt no-new-privileges \
    "$image" --noproxy '*' --insecure \
    --head --silent --show-error \
    --connect-timeout 5 --max-time 12 \
    --output /dev/null --write-out 'direct-IP HTTP status: %{http_code}\n' \
    https://1.1.1.1/; then
    echo 'FAIL: internal Docker container reached external public IP directly.' >&2
    exit 1
else
    echo 'OBSERVED: direct HTTPS to literal public IP did not succeed.'
fi
echo 'PASS: forwarder-probe functional checks; LAN isolation NOT verified.'
