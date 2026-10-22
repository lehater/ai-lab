#!/usr/bin/env bash
# Disposable n8n on the existing S1-D Docker/Compose baseline.
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="ailab-n8n-mcp-spike"
SECRETS="$HERE/.env.local"
COMPOSE="$HERE/compose.yaml"
URL="http://127.0.0.1:5678"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

check_prereqs() {
  for cmd in sudo docker openssl curl; do
    command -v "$cmd" >/dev/null || fail "Missing command: $cmd"
  done
  sudo docker compose version >/dev/null || fail "Docker Compose unavailable"
}

check_secret_path() {
  [[ ! -L "$SECRETS" ]] || fail "Refusing symlink: $SECRETS"
  if [[ -e "$SECRETS" ]]; then
    [[ -f "$SECRETS" && -O "$SECRETS" ]] || fail "Private env must be an operator-owned regular file"
    [[ "$(stat -c %a "$SECRETS")" == "600" ]] || fail "Private env file must have mode 600"
    grep -Eq '^N8N_ENCRYPTION_KEY=[a-f0-9]{64}$' "$SECRETS" || fail "Invalid local encryption key file"
    [[ "$(grep -c '^N8N_ENCRYPTION_KEY=' "$SECRETS")" == "1" ]] || fail "Duplicate encryption key"
  fi
}

make_secret_if_missing() {
  check_secret_path
  if [[ ! -e "$SECRETS" ]]; then
    umask 077
    # No secret printed or put in process command-line arguments.
    local key
    key="$(openssl rand -hex 32)"
    printf 'N8N_ENCRYPTION_KEY=%s\n' "$key" > "$SECRETS"
    unset key
    chmod 600 "$SECRETS"
    echo 'Generated private local encryption key file (contents hidden).'
  fi
}

compose() {
  sudo docker compose --project-name "$PROJECT" --file "$COMPOSE" --env-file "$SECRETS" "$@"
}

verify_binding() {
  local binding
  binding="$(compose port n8n 5678)"
  [[ "$binding" == "127.0.0.1:5678" ]] || fail "Unexpected published binding: $binding (expected 127.0.0.1:5678)"
}

verify_health() {
  local attempt
  for ((attempt=1; attempt<=30; attempt++)); do
    if curl --noproxy '*' --fail --silent --max-time 3 "$URL/healthz" >/dev/null; then
      echo "PASS: n8n HTTP health endpoint at $URL/healthz"
      return
    fi
    sleep 2
  done
  fail "n8n health check failed; inspect ./lab.sh logs"
}

case "${1:-help}" in
  up)
    check_prereqs
    make_secret_if_missing
    compose config --quiet
    compose up --detach
    verify_binding
    verify_health
    echo "Operator setup: open $URL, create owner, then enable Settings > Instance-level MCP."
    ;;
  verify)
    check_prereqs
    check_secret_path
    [[ -f "$SECRETS" ]] || fail "Run ./lab.sh up first"
    compose config --quiet
    [[ -n "$(compose ps --quiet n8n)" ]] || fail "No n8n container running"
    verify_binding
    verify_health
    echo 'PASS: Compose config, container, loopback port and local health.'
    ;;
  ps)
    check_prereqs
    check_secret_path
    [[ -f "$SECRETS" ]] || fail "No experiment env; run up first"
    compose ps
    ;;
  logs)
    check_prereqs
    check_secret_path
    [[ -f "$SECRETS" ]] || fail "No experiment env; run up first"
    compose logs --tail=80 n8n
    ;;
  stop)
    check_prereqs
    check_secret_path
    [[ -f "$SECRETS" ]] || fail "No experiment env; nothing to stop"
    compose down
    echo 'Stopped only the experiment Compose project; persistent volume retained.'
    ;;
  clean)
    [[ "${2:-}" == "--destroy-experiment-data" ]] ||
      fail 'Explicit confirmation required: ./lab.sh clean --destroy-experiment-data'
    check_prereqs
    check_secret_path
    [[ -f "$SECRETS" ]] || fail "Missing local env file; refuse ambiguous cleanup"
    compose down --volumes --remove-orphans
    # Reject a claim of complete cleanup if any labeled project resource remains.
    [[ -z "$(sudo docker ps -aq --filter "label=com.docker.compose.project=$PROJECT")" ]] ||
      fail "Experiment container remains; inspect Docker"
    [[ -z "$(sudo docker volume ls -q --filter "label=com.docker.compose.project=$PROJECT")" ]] ||
      fail "Experiment volume remains; inspect Docker"
    [[ -z "$(sudo docker network ls -q --filter "label=com.docker.compose.project=$PROJECT")" ]] ||
      fail "Experiment network remains; inspect Docker"
    rm -- "$SECRETS"
    echo 'PASS: experiment containers, networks, volumes and local encryption key removed.'
    ;;
  static-test)
    bash "$HERE/tests/test-static.sh"
    ;;
  help|*)
    cat <<'HELP'
Usage: ./lab.sh <command>

  static-test                        Shell and isolation static checks (no Docker)
  up                                 Create private encryption key and start local n8n
  verify                             Check Compose, loopback binding, HTTP /healthz
  ps                                 Show experiment containers
  logs                               Show recent n8n logs (inspect/redact before sharing)
  stop                               Stop without deleting the n8n volume
  clean --destroy-experiment-data    Delete experiment containers, network, volume and key

Never use global Docker prune commands for this experiment.
Run Codex in the SAME VM as n8n; 127.0.0.1 is not remotely reachable.
HELP
    ;;
esac
