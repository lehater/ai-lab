#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "$EUID" -ne 0 ]] || { echo 'ERROR: run as the desktop user, not root' >&2; exit 1; }
for cmd in sudo docker mktemp; do
    command -v "$cmd" >/dev/null || { echo "ERROR: missing $cmd" >&2; exit 1; }
done
bash "$DIR/test-config.sh"
umask 077
tmp="$(mktemp -d)"
secret="$tmp/password"
backup="$tmp/backup.sql"
printf '%s\n' "$(cat /proc/sys/kernel/random/uuid)" > "$secret"
# Project names are unique, owned by this one test invocation and never user-supplied.
suffix="$(basename "$tmp" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')"
primary="ailabs2-${suffix}"
recovered="${primary}-restore"

compose() {
    local project="$1"
    shift
    sudo env S2_SECRET_FILE="$secret" docker compose \
        -f "$DIR/compose.yaml" --project-name "$project" "$@"
}

cleanup() {
    local status=$?
    trap - EXIT
    if (( status != 0 )); then
        echo 'S2.1 FAILED: diagnostic output follows (no password displayed).' >&2
        compose "$primary" ps >&2 || true
        compose "$primary" logs --tail=50 db >&2 || true
        compose "$recovered" ps >&2 || true
    fi
    # Only the test's unique projects and their volumes are removed.
    compose "$recovered" down --volumes --remove-orphans >/dev/null 2>&1 || {
        echo "ERROR: cleanup failed for $recovered; inspect it manually" >&2
        status=1
    }
    compose "$primary" down --volumes --remove-orphans >/dev/null 2>&1 || {
        echo "ERROR: cleanup failed for $primary; inspect it manually" >&2
        status=1
    }
    rm -rf "$tmp"
    if (( status == 0 )); then
        echo 'PASS: S2.1 secret, health, no published ports, persistence, logical backup/restore and cleanup.'
    fi
    exit "$status"
}
trap cleanup EXIT

echo "S2.1 disposable projects: $primary and $recovered"
compose "$primary" up -d --wait --wait-timeout 120
container="$(compose "$primary" ps -q db)"
[[ -n "$container" ]] || { echo 'ERROR: no database container' >&2; exit 1; }
[[ "$(sudo docker inspect --format '{{len .HostConfig.PortBindings}}' "$container")" == 0 ]] || {
    echo 'ERROR: service has published ports' >&2; exit 1;
}
compose "$primary" exec -T -u 0 db test -s /run/secrets/db_password
compose "$primary" exec -T db psql -v ON_ERROR_STOP=1 -U ai_lab_s2 -d ai_lab_s2 \
    -c "CREATE TABLE s2_probe (marker text PRIMARY KEY); INSERT INTO s2_probe VALUES ('persisted');"

# Compose down (without -v) removes the container, but preserves the named volume.
compose "$primary" down
compose "$primary" up -d --wait --wait-timeout 120
persisted="$(compose "$primary" exec -T db psql -tA -v ON_ERROR_STOP=1 \
    -U ai_lab_s2 -d ai_lab_s2 -c "SELECT count(*) FROM s2_probe WHERE marker='persisted';" | tr -d '\r')"
[[ "$persisted" == 1 ]] || { echo "ERROR: persisted data missing: $persisted" >&2; exit 1; }

# A logical database backup is consistent while Postgres is running.
compose "$primary" exec -T db pg_dump -U ai_lab_s2 -d ai_lab_s2 > "$backup"
[[ -s "$backup" ]] || { echo 'ERROR: empty database backup' >&2; exit 1; }

# Restore into a fresh project/volume, leaving the original untouched.
compose "$recovered" up -d --wait --wait-timeout 120
compose "$recovered" exec -T db psql -v ON_ERROR_STOP=1 -U ai_lab_s2 -d ai_lab_s2 < "$backup" >/dev/null
restored="$(compose "$recovered" exec -T db psql -tA -v ON_ERROR_STOP=1 \
    -U ai_lab_s2 -d ai_lab_s2 -c "SELECT count(*) FROM s2_probe WHERE marker='persisted';" | tr -d '\r')"
[[ "$restored" == 1 ]] || { echo "ERROR: restored data missing: $restored" >&2; exit 1; }
sudo docker image inspect postgres:17-alpine --format 'Test image ID: {{.Id}}'
