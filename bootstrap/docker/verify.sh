#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode="${1:---local}"
[[ "$mode" == --local || "$mode" == --pull ]] || { echo 'Usage: verify.sh [--local|--pull]' >&2; exit 2; }
for cmd in docker sudo systemctl dpkg-query; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing $cmd" >&2; exit 1; }
done
for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -qx 'install ok installed' || {
        echo "ERROR: missing Docker package: $pkg" >&2; exit 1;
    }
done
sudo systemctl is-active --quiet docker || { echo 'ERROR: Docker daemon not running' >&2; exit 1; }
expected="$(bash "$DIR/render.sh" daemon-proxy)"
actual="$(sudo cat /etc/systemd/system/docker.service.d/ai-lab-proxy.conf)"
[[ "$actual" == "$expected" ]] || { echo 'ERROR: Docker daemon proxy drop-in differs' >&2; exit 1; }
env_line="$(sudo systemctl show --property=Environment --value docker)"
[[ "$env_line" == *'HTTP_PROXY=http://127.0.0.1:10808'* && "$env_line" == *'HTTPS_PROXY=http://127.0.0.1:10808'* ]] || {
    echo 'ERROR: Docker daemon proxy not loaded by systemd' >&2; exit 1;
}
# No container publish is performed here. Verify standard plaintext Docker TCP ports remain closed.
if ss -lnt | grep -Eq ':(2375|2376)[[:space:]]'; then
    echo 'ERROR: Docker TCP management ports detected; inspect host configuration' >&2; exit 1
fi
sudo docker info --format 'Docker Engine {{.ServerVersion}}'
docker --version
docker compose version
echo 'S1-D Docker host and daemon proxy: PASS (no image pull or container network checked).'
if [[ "$mode" == --pull ]]; then
    bash "$DIR/../host/verify.sh" --local
    sudo docker run --rm --pull=always hello-world
    echo 'S1-D Docker registry pull and hello-world container: PASS.'
fi
