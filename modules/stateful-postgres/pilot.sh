#!/usr/bin/env bash
# Minimal S2 integration check: backup and restore to a SEPARATE Docker volume.
# No generic platform tests, global cleanup, or mutation of other Compose projects.
set -Eeuo pipefail
cd "$(dirname -- "${BASH_SOURCE[0]}")"

PROJECT=ai-lab-s2-pg-pilot
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
dc() { sudo docker compose --project-name "${PROJECT}" "$@"; }
restore_dc() { sudo docker compose --project-name "${RESTORE_PROJECT}" --profile restore "$@"; }

require_operator() {
  (( EUID != 0 )) || fail 'Run as normal operator, not root.'
  command -v docker >/dev/null || fail 'Docker/Compose baseline missing.'
}
require_private() {
  [[ -f .env && ! -L .env ]] || fail 'Missing or symlinked .env; run init.'
  [[ -f private/db_password.txt && ! -L private/db_password.txt ]] ||
    fail 'Missing or symlinked private password; run init.'
  [[ -d private/backups && ! -L private && ! -L private/backups ]] ||
    fail 'Unsafe or missing private backup directory.'
}
init() {
  command -v openssl >/dev/null || fail 'openssl missing.'
  [[ ! -L .env && ! -L private && ! -L private/backups ]] ||
    fail 'Refusing symlinked configuration.'
  (umask 077; mkdir -p private/backups)
  chmod 0700 private private/backups
  if [[ ! -e private/db_password.txt && ! -L private/db_password.txt ]]; then
    (umask 077; openssl rand -hex 32 > private/db_password.txt)
  fi
  [[ -f private/db_password.txt && ! -L private/db_password.txt ]] ||
    fail 'Refusing nonregular password file.'
  chmod 0600 private/db_password.txt
  if [[ ! -e .env ]]; then
    (umask 077; cp .env.example .env)
  fi
  [[ -f .env && ! -L .env ]] || fail 'Invalid .env.'
  chmod 0600 .env
  echo 'Local password and .env prepared (not in Git).'
}
test_restore() {
  require_private
  # Configuration validation, not a re-test of Compose persistence semantics.
  dc --profile restore config -q

  dc up -d --wait db
  dc exec -T db psql -X -v ON_ERROR_STOP=1 -U ai_lab_pilot -d ai_lab_pilot \
    -c 'CREATE TABLE IF NOT EXISTS ai_lab_s2_proof (id INT PRIMARY KEY, value TEXT NOT NULL);'
  dc exec -T db psql -X -v ON_ERROR_STOP=1 -U ai_lab_pilot -d ai_lab_pilot \
    -c "INSERT INTO ai_lab_s2_proof VALUES (1, 'restorable') ON CONFLICT (id) DO UPDATE SET value=EXCLUDED.value;"

  local backup recovered
  backup="$(mktemp private/backups/backup-XXXXXXXX.dump)"
  if ! dc exec -T db pg_dump -Fc -U ai_lab_pilot -d ai_lab_pilot > "${backup}"; then
    rm -f -- "${backup}"
    fail 'Backup command failed.'
  fi
  [[ -s "${backup}" ]] || fail 'Backup is empty.'
  printf 'Backup generated: %s\n' "${backup}"

  # A unique Compose project gives its restore-db service a NEW named volume.
  # Never restore over the source database.
  RESTORE_PROJECT="${PROJECT}-restore-$$"
  restore_dc up -d --wait restore-db
  restore_dc exec -T restore-db pg_restore -U ai_lab_pilot -d ai_lab_pilot \
    --no-owner --no-privileges < "${backup}"
  recovered="$(restore_dc exec -T restore-db psql -X -v ON_ERROR_STOP=1 \
    -U ai_lab_pilot -d ai_lab_pilot -At \
    -c 'SELECT value FROM ai_lab_s2_proof WHERE id=1;')"
  [[ "${recovered}" == restorable ]] || fail 'Restored data differs.'
  echo 'PASS: backup restored and independently read in separate fresh volume.'

  # Narrow cleanup: restore project only. Primary DB and dump are preserved.
  restore_dc down --volumes
  echo 'Restore-only fixture removed; primary project and local dump retained.'
}
cleanup() {
  require_private
  [[ "${AI_LAB_ALLOW_PILOT_TEARDOWN:-}" == YES ]] ||
    fail 'Set AI_LAB_ALLOW_PILOT_TEARDOWN=YES to remove only this pilot project.'
  dc down --volumes
  echo 'Only primary pilot project volumes removed; backup and local secret retained.'
}
require_operator
case "${1:-}" in
  init) init ;;
  test) test_restore ;;
  cleanup) cleanup ;;
  *) echo 'Usage: bash pilot.sh init|test|cleanup' >&2; exit 2 ;;
esac
