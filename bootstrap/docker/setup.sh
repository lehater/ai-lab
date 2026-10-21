#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
proxy='http://127.0.0.1:10808'
repo_key='/etc/apt/keyrings/docker.asc'
repo_source='/etc/apt/sources.list.d/docker.sources'
proxy_dropin='/etc/systemd/system/docker.service.d/ai-lab-proxy.conf'
packages=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
conflicts=(docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc)
expected_key='9DC858229FC7DD38854AE2D88D81803C0EBFCD88'

[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as desktop user (not root)' >&2; exit 1; }
. /etc/os-release
[[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 && "$(dpkg --print-architecture)" == amd64 ]] || {
    echo 'ERROR: this candidate supports Ubuntu 24.04 amd64 only' >&2; exit 1;
}
[[ -f /etc/apt/apt.conf.d/80proxy ]] || { echo 'ERROR: configure Stage 0 APT proxy first' >&2; exit 1; }
for command_name in bash sudo curl git dpkg-query apt-get systemctl; do
    command -v "$command_name" >/dev/null || { echo "ERROR: missing prerequisite: $command_name" >&2; exit 1; }
done
bash "$DIR/../host/verify.sh" --local
if ! command -v gpg >/dev/null; then
    echo "Installing GnuPG for Docker APT signing-key fingerprint verification..."
    sudo apt-get update
    sudo apt-get install -y gnupg
fi
for package in "${conflicts[@]}"; do
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
        echo "ERROR: conflicting package $package is installed; manual review required (nothing removed)" >&2
        exit 1
    fi
done

# Never overwrite an unknown APT repository or a pre-existing daemon override.
for target in "$repo_key" "$repo_source" "$proxy_dropin"; do
    if sudo test -L "$target"; then
        echo "ERROR: refusing symlink: $target" >&2; exit 1
    fi
done
if sudo test -f /etc/docker/daemon.json && sudo grep -q '"proxies"' /etc/docker/daemon.json; then
    echo 'ERROR: daemon.json has existing proxy settings; manual review required' >&2; exit 1
fi

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
curl --noproxy '' --proxy "$proxy" -fsSL --max-time 45 \
    https://download.docker.com/linux/ubuntu/gpg -o "$scratch/docker.asc"
actual_key="$(gpg --batch --show-keys --with-colons "$scratch/docker.asc" 2>/dev/null | awk -F: '$1=="fpr" {print $10; exit}')"
[[ "$actual_key" == "$expected_key" ]] || {
    echo "ERROR: Docker repository signing key fingerprint mismatch: $actual_key" >&2; exit 1
}
bash "$DIR/render.sh" sources > "$scratch/docker.sources"
bash "$DIR/render.sh" daemon-proxy > "$scratch/ai-lab-proxy.conf"

# Verify existing files match byte-for-byte; never overwrite local modifications.
for pair in "$scratch/docker.asc:$repo_key" "$scratch/docker.sources:$repo_source" "$scratch/ai-lab-proxy.conf:$proxy_dropin"; do
    source_file="${pair%%:*}"
    target="${pair#*:}"
    if sudo test -e "$target" && ! sudo cmp -s "$source_file" "$target"; then
        echo "ERROR: existing file differs; refusing overwrite: $target" >&2; exit 1
    fi
done

if ! sudo test -e "$repo_key"; then
    sudo install -d -m 0755 /etc/apt/keyrings
    sudo install -m 0644 "$scratch/docker.asc" "$repo_key"
fi
if ! sudo test -e "$repo_source"; then
    sudo install -m 0644 "$scratch/docker.sources" "$repo_source"
fi

missing=()
for package in "${packages[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
        missing+=("$package")
    fi
done
if (( ${#missing[@]} )); then
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
fi

new_dropin=false
if ! sudo test -e "$proxy_dropin"; then
    sudo install -d -m 0755 /etc/systemd/system/docker.service.d
    sudo install -m 0644 "$scratch/ai-lab-proxy.conf" "$proxy_dropin"
    new_dropin=true
fi
sudo systemctl daemon-reload
if [[ "$new_dropin" == true ]] && sudo systemctl is-active --quiet docker; then
    sudo systemctl restart docker
fi
sudo systemctl enable --now docker
bash "$DIR/verify.sh" --local
echo 'S1-D candidate: Docker Engine/Compose and daemon proxy configured; container networking/LAN security not yet verified.'
