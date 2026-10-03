#!/usr/bin/env bash
# Control the Kingdoms stack of a target environment (test, prod):
# start | stop | restart | status. Runs ON the environment's runner
# (called by .github/workflows/env-control.yml) and dumps the result;
# it never deploys, never pulls, never touches the pinned state.
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
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

# Same substitution inputs as deploy.sh: the pinned image comes from the
# state file (compose fails closed without it), DISCORD_TOKEN from the
# GitHub environment secrets. Control commands never change the state.
STATE_FILE="${REPO_ROOT}/envs/${ENVIRONMENT}/state/kingdoms-bot.yml"
if [[ -f "${STATE_FILE}" ]]; then
    pinned_image="$(grep -E '^image:' "${STATE_FILE}" | head -1 | cut -d' ' -f2-)"
    [[ -n "${pinned_image:-}" ]] || die "state file ${STATE_FILE} has no image"
    export KINGDOMS_BOT_IMAGE="${pinned_image}"
fi
[[ -n "${DISCORD_TOKEN:-}" ]] \
    || die "DISCORD_TOKEN is not set (provide it via the GitHub environment secrets)"

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
