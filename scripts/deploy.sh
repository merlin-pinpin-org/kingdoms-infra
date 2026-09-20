#!/usr/bin/env bash
# Deploy the Kingdoms stack to a target environment (test, staging, prod).
# Idempotent, with mandatory pre-deploy backup and post-deploy health gate.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(test staging prod)
ENVIRONMENT="${1:-test}"
ENV_DIR="${REPO_ROOT}/deploy/${ENVIRONMENT}"
COMPOSE_FILE="${ENV_DIR}/docker-compose.yml"
MONGO_SERVICE="kingdoms-mongo"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-90}"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}>"
    exit 1
}

log() { echo "[deploy:${ENVIRONMENT}] $*"; }

die() { echo "[deploy:${ENVIRONMENT}] ERROR: $*" >&2; exit 1; }

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ -f "${COMPOSE_FILE}" ]] || die "missing compose file: ${COMPOSE_FILE}"

if [[ ! -f "${ENV_DIR}/.env" ]]; then
    die "missing ${ENV_DIR}/.env (copy it from .env.example and fill in secrets)"
fi

cd "${ENV_DIR}"

# Idempotence note: this script manages the full stack lifecycle. Running
# `docker compose pull` before `up` is safe: it only refreshes images.

log "pulling images"
docker compose pull --quiet

# Mandatory backup before any deployment
log "running mandatory pre-deploy backup"
"${REPO_ROOT}/scripts/backup_db.sh" "${ENVIRONMENT}" \
    || die "pre-deploy backup failed: aborting deployment"

log "applying the stack"
docker compose up -d --remove-orphans

log "waiting for services to become healthy (${HEALTH_TIMEOUT}s)"
DEADLINE=$(( $(date +%s) + HEALTH_TIMEOUT ))
for service in kingdoms-bot "${MONGO_SERVICE}" kingdoms-redis; do
    if ! docker compose config --services | grep -q "^${service}$"; then
        continue
    fi
    until docker compose ps --format json "${service}" 2>/dev/null \
        | grep -q '"Health":"healthy"'; do
        if (( $(date +%s) > DEADLINE )); then
            log "service ${service} failed to become healthy; rolling back"
            "${REPO_ROOT}/scripts/rollback.sh" "${ENVIRONMENT}" --auto || true
            die "service ${service} unhealthy after ${HEALTH_TIMEOUT}s"
        fi
        sleep 3
    done
    log "service ${service} is healthy"
done

log "deployment to '${ENVIRONMENT}' applied and healthy"
