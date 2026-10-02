#!/usr/bin/env bash
# Control the Kingdoms stack of a target environment (test, prod):
# start | stop | restart | status. Runs ON the environment's runner
# (called by .github/workflows/env-control.yml) and dumps the result;
# it never deploys, never pulls, never touches the pinned state.
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(test prod)
COMMANDS=(start stop restart status)

ENVIRONMENT="${1:-}"
COMMAND="${2:-}"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}> <${COMMANDS[*]}>"
    exit 1
}

log() { echo "[envctl:${ENVIRONMENT}] $*"; }
die() { echo "[envctl:${ENVIRONMENT}] ERROR: $*" >&2; exit 1; }

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ " ${COMMANDS[*]} " == *" ${COMMAND} "* ]] || usage

COMPOSE_FILE="${REPO_ROOT}/envs/${ENVIRONMENT}/docker-compose.yml"
[[ -f "${COMPOSE_FILE}" ]] || die "missing compose file: ${COMPOSE_FILE}"

cd "${REPO_ROOT}/envs/${ENVIRONMENT}"

case "${COMMAND}" in
    start)
        log "starting the stack (no pull, no recreate)"
        docker compose start
        ;;
    stop)
        log "stopping the stack"
        docker compose stop
        ;;
    restart)
        log "restarting the stack (no pull, no recreate)"
        docker compose restart
        ;;
    status)
        log "stack status"
        ;;
esac

echo
echo "=== docker compose ps ==="
docker compose ps
echo
log "done (${COMMAND})"
