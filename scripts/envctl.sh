#!/usr/bin/env bash
# Control the Kingdoms stack of a target environment (test, prod):
# start | stop | restart | status | reset. Runs ON the environment's
# runner (called by .github/workflows/env-control.yml) and dumps the
# result; it never deploys, never pulls, never touches the pinned state.
#
# reset is DESTRUCTIVE: it stops the stack and deletes the data volumes
# (mongo_data, redis_data). Double gate before it can run:
#   1. the env-reset roster capability (self env only; ops anywhere),
#   2. the env itself opts in: x-kingdoms-env-resettable: true in its
#      compose manifest (an allowlist — prod never carries the flag, and
#      a new environment without it fails closed).
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mapfile -t ENVIRONMENTS < <(cd "${REPO_ROOT}/envs" && ls -d */ 2>/dev/null | tr -d '/')
[[ ${#ENVIRONMENTS[@]} -gt 0 ]] || { echo "ERROR: no environment found under envs/" >&2; exit 1; }
COMMANDS=(start stop restart status reset)

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
    reset)
        # Allowlist: only manifests carrying x-kingdoms-env-resettable: true.
        resettable="$(docker compose --progress quiet config --format json \
            | python3 -c 'import json,sys; print(json.load(sys.stdin).get("x-kingdoms-env-resettable") == True)')"
        [[ "$resettable" == true ]] \
            || die "reset is not allowed on this environment (no x-kingdoms-env-resettable flag in its compose manifest)"
        log "RESETTING: stopping the stack and deleting the data volumes"
        docker compose down --volumes
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
