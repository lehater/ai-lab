#!/usr/bin/env bash
set -euo pipefail

# Validates the default Docker Compose bridge with one ephemeral service.
# No published ports, custom networks, volumes or Docker group changes.
[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as desktop user, not root' >&2; exit 1; }
for cmd in sudo docker mktemp; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing command: $cmd" >&2; exit 1; }
done

tmp="$(mktemp -d)"
project="ailab-composesmoke-$$"
compose_file="$tmp/compose.yaml"
compose_created=false

cleanup() {
    result=$?
    trap - EXIT
    if [[ "$compose_created" == true ]]; then
        if ! sudo docker compose -f "$compose_file" --project-name "$project" down; then
            echo "ERROR: failed to remove temporary Compose project: $project" >&2
            result=1
        fi
    fi
    rm -rf "$tmp"
    if [[ "$result" == 0 ]]; then
        echo 'PASS: Docker Compose default bridge service and cleanup.'
    fi
    exit "$result"
}
trap cleanup EXIT

cat > "$compose_file" <<'YAML'
services:
  smoke:
    image: hello-world:latest
    restart: "no"
YAML

sudo docker compose -f "$compose_file" --project-name "$project" config --quiet

# Begin cleanup ownership before 'up': partial container/network creation
# must be torn down if the command fails.
compose_created=true
sudo docker compose -f "$compose_file" --project-name "$project" \
    up --abort-on-container-exit --exit-code-from smoke

network="$(sudo docker network inspect "${project}_default" \
    --format '{{.Driver}} {{.Internal}}')"
[[ "$network" == "bridge false" ]] || {
    echo "ERROR: unexpected Compose network configuration: $network" >&2
    exit 1
}
echo 'Docker Compose default network: bridge, internal=false; no published ports.'
