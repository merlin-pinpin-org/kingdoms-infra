#!/usr/bin/env bash
# Deploy the Kingdoms stack to a target environment (test, prod).
# Idempotent, with mandatory pre-deploy backup and post-deploy health gate.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(test prod)
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

# Secrets come from the CD pipeline environment (GitHub environment
# secrets); nothing secret is stored on the VPS. Compose substitution
# fails closed on a missing DISCORD_TOKEN.
[[ -n "${DISCORD_TOKEN:-}" ]] \
    || die "DISCORD_TOKEN is not set (provide it via the GitHub environment secrets)"

# Desired state (ADR-0018): when a state file exists in this checkout,
# it is the source of truth for the deployed image and deploy URL —
# the deploy workflow checks out the state branch commit, so the
# pinned values cannot drift or be spoofed via workflow inputs.
STATE_FILE="${REPO_ROOT}/deploy/state/${ENVIRONMENT}/kingdoms-bot.yml"
if [[ -f "${STATE_FILE}" ]]; then
    pinned_image="$(grep -E '^image:' "${STATE_FILE}" | head -1 | cut -d' ' -f2-)"
    pinned_url="$(grep -E '^deploy_url:' "${STATE_FILE}" | head -1 | cut -d' ' -f2-)"
    [[ -n "${pinned_image:-}" ]] || die "state file ${STATE_FILE} has no image"
    export KINGDOMS_BOT_IMAGE="${pinned_image}"
    [[ -n "${pinned_url:-}" ]] || pinned_url=""
    export KINGDOMS_DEPLOY_URL="${pinned_url}"
    log "state: image=${KINGDOMS_BOT_IMAGE} deploy_url=${KINGDOMS_DEPLOY_URL:-<none>}"
fi

cd "${ENV_DIR}"

# Idempotence note: this script manages the full stack lifecycle. Running
# `docker compose pull` before `up` is safe: it only refreshes images.

log "pulling images"
docker compose pull --quiet

# Mandatory backup before any deployment — except the very first one:
# on a fresh VPS the stack does not exist yet, so there is nothing to
# back up (backup_db.sh fails closed on a non-running MongoDB).
if docker compose config --services >/dev/null 2>&1 \
    && docker compose ps --status running --format json 2>/dev/null \
        | grep -q "${MONGO_SERVICE}"; then
    log "running mandatory pre-deploy backup"
    "${REPO_ROOT}/scripts/backup_db.sh" "${ENVIRONMENT}" \
        || die "pre-deploy backup failed: aborting deployment"
else
    log "stack not running yet (first deployment?): skipping the backup"
fi

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
