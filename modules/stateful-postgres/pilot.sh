#!/usr/bin/env bash
# S2 disposable Compose/stateful data pilot; cannot touch unrelated Docker projects.
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"
PROJECT=ai-lab-s2-pg-pilot
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
dc() { sudo docker compose --project-name "${PROJECT}" "$@"; }
restore_dc() { sudo docker compose --project-name "${RESTORE_PROJECT}" --profile restore "$@"; }
ensure_operator() {
  (( EUID != 0 )) || fail "Run as ordinary VM operator; scoped Docker commands use sudo."
  command -v docker >/dev/null || fail "Docker missing: follow S1-D runbook first."
  command -v python3 >/dev/null || fail "Python3 missing."
}
ensure_inputs() {
  [[ -f .env && ! -L .env ]] || fail "Missing ordinary .env; run bash pilot.sh init."
  [[ -f private/db_password.txt && ! -L private/db_password.txt ]] ||
    fail "Missing private password file; run bash pilot.sh init."
  [[ ! -L private && ! -L private/backups ]] || fail "Private paths cannot be symlinks."
}
do_init() {
  command -v openssl >/dev/null || fail "openssl missing."
  [[ ! -L private && ! -L private/backups && ! -L .env ]] || fail "Refusing symlinked local configuration."
  (umask 077; mkdir -p private/backups)
  chmod 0700 private private/backups
  if [[ ! -e private/db_password.txt && ! -L private/db_password.txt ]]; then
    (umask 077; openssl rand -hex 32 > private/db_password.txt)
  fi
  [[ -f private/db_password.txt && ! -L private/db_password.txt ]] ||
    fail "Password must be a regular file, not a symlink."
  chmod 0600 private/db_password.txt
  if [[ ! -e .env ]]; then
    (umask 077; cp .env.example .env)
  fi
  [[ -f .env && ! -L .env ]] || fail "Invalid .env."
  chmod 0600 .env
  printf '%s\n' "Prepared isolated untracked .env, secret and backup directory."
  printf '%s\n' "Review POSTGRES_IMAGE in .env and record digest before production/replay claims."
}
check_compose() {
  dc --profile restore config --format json | python3 -c '
import json,sys
c=json.load(sys.stdin)
ss=c.get("services",{})
assert "db" in ss and "restore-db" in ss, "missing services"
for name in ("db","restore-db"):
    assert not ss[name].get("ports"), f"{name}: published ports are forbidden"
    assert ss[name].get("environment",{}).get("POSTGRES_PASSWORD_FILE")=="/run/secrets/db_password"
assert ss["db"]["volumes"][0]["source"]=="primary_data"
assert ss["restore-db"]["volumes"][0]["source"]=="restore_data"
assert c.get("secrets",{}).get("db_password"), "file-backed Docker secret missing"
print("Compose render: PASS (no published ports, distinct persistent volumes, password file)")
'
}
check_ports() {
  local cid
  cid="$(dc ps -q db)"
  [[ -n "${cid}" ]] || fail "db container missing"
  sudo docker inspect --format '{{json .NetworkSettings.Ports}}' "${cid}" |
    python3 -c 'import json,sys; ports=json.load(sys.stdin); assert not any(ports.values()), f"Host ports exposed: {ports}"; print("No Docker host ports published: PASS")'
}
db_query() {
  dc exec -T db psql -X -v ON_ERROR_STOP=1 -U ai_lab_pilot -d ai_lab_pilot "$@"
}
do_test() {
  ensure_inputs
  check_compose
  dc up -d --wait db
  check_ports

  db_query -c "CREATE TABLE IF NOT EXISTS ai_lab_s2_proof (id INTEGER PRIMARY KEY, value TEXT NOT NULL);"
  db_query -c "INSERT INTO ai_lab_s2_proof (id, value) VALUES (1, 'persisted') ON CONFLICT (id) DO UPDATE SET value=EXCLUDED.value;"

  # A container restart is not enough: recreate the container while retaining named volume.
  dc up -d --force-recreate --wait db
  check_ports
  local observed
  observed="$(db_query -At -c 'SELECT value FROM ai_lab_s2_proof WHERE id=1;')"
  [[ "${observed}" == persisted ]] || fail "Named volume did not survive container recreation."
  echo "Named-volume persistence after forced recreation: PASS"

  local backup
  (umask 077; mkdir -p private/backups)
  chmod 0700 private private/backups
  backup="$(mktemp private/backups/pilot-XXXXXXXX.dump)"
  if ! dc exec -T db pg_dump -Fc -U ai_lab_pilot -d ai_lab_pilot > "${backup}"; then
    rm -f -- "${backup}"
    fail "pg_dump failed; incomplete backup removed."
  fi
  [[ -s "${backup}" ]] || fail "Backup file empty."

  # Fresh Compose project → fresh named volume. Never restore into the primary volume.
  RESTORE_PROJECT="${PROJECT}-restore-$(date +%s)-$$"
  printf 'Restore project: %s (separate fresh volume)\n' "${RESTORE_PROJECT}"
  restore_dc up -d --wait restore-db
  restore_dc exec -T restore-db pg_restore -U ai_lab_pilot -d ai_lab_pilot --no-owner --no-privileges < "${backup}"
  local recovered
  recovered="$(restore_dc exec -T restore-db psql -X -At -v ON_ERROR_STOP=1 -U ai_lab_pilot -d ai_lab_pilot -c 'SELECT value FROM ai_lab_s2_proof WHERE id=1;')"
  [[ "${recovered}" == persisted ]] || fail "Recovery into separate volume does not match seed data."
  echo "Backup → isolated fresh-volume restore: PASS"

  # Only the uniquely generated recovery fixture is discarded, never primary data.
  restore_dc down --volumes --remove-orphans
  echo "Restore-only project cleanup: PASS"
  printf 'Backup retained locally for operator review (gitignored): %s\n' "${backup}"
  echo "PRIMARY database remains running; cleanup requires separate explicit consent."
}
do_cleanup() {
  ensure_inputs
  [[ "${AI_LAB_ALLOW_PILOT_TEARDOWN:-}" == YES ]] ||
    fail "Set AI_LAB_ALLOW_PILOT_TEARDOWN=YES only after reviewing this pilot's volumes."
  dc down --volumes --remove-orphans
  echo "Dedicated pilot Compose project stopped; its named volumes removed."
  echo "Local .env, secret and backups retained for separate operator-controlled deletion."
}
main() {
  ensure_operator
  case "${1:-}" in
    init) do_init ;;
    config) ensure_inputs; check_compose ;;
    test) do_test ;;
    cleanup) do_cleanup ;;
    *) printf 'Usage: bash pilot.sh {init|config|test|cleanup}\n' >&2; exit 2 ;;
  esac
}
main "$@"
