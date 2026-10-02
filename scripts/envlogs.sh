#!/usr/bin/env bash
# Dump the logs of a target environment's stack, with time and service
# filters. Runs ON the environment's runner (called by
# .github/workflows/env-logs.yml) and writes the result to stdout and to
# the LOG_OUT file when set — it is read-only: never deploys, never
# pulls, never touches the pinned state or the data.
#
# Usage: envlogs.sh <env> [--service <name>] [--since <30m|2h|1d>]
#                  [--from <ISO8601>] [--to <ISO8601>] [--tail <N>]
#   --service   one service of the compose stack (default: all services)
#   --since     relative window from now (docker --since syntax: 30m, 2h, 1d)
#   --from/--to absolute window (ISO8601, docker --since/--until)
#   --tail      last N lines per service (default 200)
# --since and --from are mutually exclusive; --to requires --from.
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(test prod)
ENVIRONMENT="${1:-}"
[[ -n "${ENVIRONMENT}" ]] || { echo "Usage: $0 <${ENVIRONMENTS[*]}> [--service <name>] [--since <30m>] [--from <iso>] [--to <iso>] [--tail <n>]" >&2; exit 1; }
shift

SERVICE=""
SINCE=""
FROM=""
TO=""
TAIL="200"
while [[ $# -gt 0 ]]; do
    case "${1}" in
        --service) SERVICE="${2:?}"; shift 2 ;;
        --since)   SINCE="${2:?}"; shift 2 ;;
        --from)    FROM="${2:?}"; shift 2 ;;
        --to)      TO="${2:?}"; shift 2 ;;
        --tail)    TAIL="${2:?}"; shift 2 ;;
        *) echo "unknown option: ${1}" >&2; exit 1 ;;
    esac
done

log() { echo "[envlogs:${ENVIRONMENT}] $*" >&2; }
die() { echo "[envlogs:${ENVIRONMENT}] ERROR: $*" >&2; exit 1; }

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || die "unknown environment: ${ENVIRONMENT}"
[[ -z "${SINCE}" || -z "${FROM}" ]] || die "--since and --from are mutually exclusive"
[[ -z "${TO}" || -n "${FROM}" ]] || die "--to requires --from"

COMPOSE_FILE="${REPO_ROOT}/envs/${ENVIRONMENT}/docker-compose.yml"
[[ -f "${COMPOSE_FILE}" ]] || die "missing compose file: ${COMPOSE_FILE}"
cd "${REPO_ROOT}/envs/${ENVIRONMENT}"

ARGS=(--tail "${TAIL}" --timestamps)
[[ -n "${SINCE}" ]] && ARGS+=(--since "${SINCE}")
[[ -n "${FROM}" ]]  && ARGS+=(--since "${FROM}")
[[ -n "${TO}" ]]    && ARGS+=(--until "${TO}")

if [[ -n "${SERVICE}" ]]; then
    # Fail loudly on a typo instead of silently dumping nothing.
    docker compose config --services | grep -qx "${SERVICE}" \
        || die "unknown service '${SERVICE}' (services: $(docker compose config --services | tr '\n' ' '))"
    log "dumping logs of service ${SERVICE} (window: ${SINCE:-${FROM:-all}}, tail ${TAIL})"
    docker compose logs "${ARGS[@]}" "${SERVICE}"
else
    log "dumping logs of all services (window: ${SINCE:-${FROM:-all}}, tail ${TAIL})"
    docker compose logs "${ARGS[@]}"
fi
