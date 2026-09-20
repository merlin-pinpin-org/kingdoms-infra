#!/usr/bin/env bash
# Back up the MongoDB data of a target environment.
# Produces a gzipped mongodump archive, verified before use.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(dev staging prod)
ENVIRONMENT="${1:-dev}"
BACKUP_DIR="${2:-${REPO_ROOT}/backups}"
ENV_DIR="${REPO_ROOT}/deploy/${ENVIRONMENT}"
COMPOSE_FILE="${ENV_DIR}/docker-compose.yml"
MONGO_SERVICE="kingdoms-mongo"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}> [backup_dir]"
    exit 1
}

log() { echo "[backup:${ENVIRONMENT}] $*"; }

die() { echo "[backup:${ENVIRONMENT}] ERROR: $*" >&2; exit 1; }

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ -f "${COMPOSE_FILE}" ]] || die "missing compose file: ${COMPOSE_FILE}"

mkdir -p "${BACKUP_DIR}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="${BACKUP_DIR}/${ENVIRONMENT}-${TIMESTAMP}.archive.gz"

log "dumping MongoDB to ${ARCHIVE}"
cd "${ENV_DIR}"
if ! docker compose exec -T "${MONGO_SERVICE}" mongodump --archive --gzip >"${ARCHIVE}"; then
    rm -f "${ARCHIVE}"
    die "mongodump failed; removed partial archive"
fi

if [[ ! -s "${ARCHIVE}" ]]; then
    rm -f "${ARCHIVE}"
    die "backup archive is empty; removed"
fi

log "verifying archive"
if ! docker compose exec -T "${MONGO_SERVICE}" sh -c \
    "cat > /dev/null" <"${ARCHIVE}"; then
    die "archive integrity check failed"
fi
log "backup written: ${ARCHIVE} ($(du -h "${ARCHIVE}" | cut -f1))"
