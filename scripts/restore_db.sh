#!/usr/bin/env bash
# Restore the MongoDB and Redis data of a target environment.
# MongoDB: restores a gzipped mongodump archive (refuses non-gzip files).
# Redis: restores an RDB snapshot by stopping the server, replacing the
# dump and restarting, so the old dataset is never loaded.
# Both artifacts must share the same <env>-<timestamp> prefix; restoring
# the MongoDB archive alone also works (the Redis dump is then optional
# if a matching .rdb file exists).

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(dev staging prod)
ENVIRONMENT="${1:-dev}"
MONGO_ARCHIVE="${2:-}"
CONFIRM="${3:-}"
COMPOSE_FILE="${REPO_ROOT}/deploy/${ENVIRONMENT}/docker-compose.yml"
MONGO_SERVICE="kingdoms-mongo"
REDIS_SERVICE="kingdoms-redis"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}> <archive.gz> [--yes]"
    echo "  Restores the MongoDB archive and, when a sibling .rdb file with the"
    echo "  same prefix exists, the Redis snapshot as well."
    exit 1
}

log() { echo "[restore:${ENVIRONMENT}] $*"; }

die() { echo "[restore:${ENVIRONMENT}] ERROR: $*" >&2; exit 1; }

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ -n "${MONGO_ARCHIVE}" && -f "${MONGO_ARCHIVE}" ]] || { echo "Archive not found: ${MONGO_ARCHIVE}"; usage; }
[[ "$(file -b --mime-type "${MONGO_ARCHIVE}")" == "application/gzip" ]] \
    || die "not a gzip archive: ${MONGO_ARCHIVE} (mongorestore expects --archive --gzip)"
[[ -f "${COMPOSE_FILE}" ]] || die "missing compose file: ${COMPOSE_FILE}"

REDIS_DUMP="${MONGO_ARCHIVE%.archive.gz}.rdb"
if [[ -f "${REDIS_DUMP}" ]]; then
    RESTORE_REDIS=1
else
    RESTORE_REDIS=0
    log "no sibling Redis snapshot (${REDIS_DUMP}); restoring MongoDB only"
fi

if [[ "${CONFIRM}" != "--yes" ]]; then
    echo "Restoring ${MONGO_ARCHIVE} to '${ENVIRONMENT}' — this overwrites existing data."
    [[ "${RESTORE_REDIS}" = "1" ]] && echo "Redis snapshot: ${REDIS_DUMP}"
    read -r -p "Continue? [y/N] " answer
    [[ "${answer}" == "y" || "${answer}" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

cd "$(dirname "${COMPOSE_FILE}")"

log "restoring MongoDB from ${MONGO_ARCHIVE}"
docker compose exec -T "${MONGO_SERVICE}" mongorestore --archive --gzip --drop <"${MONGO_ARCHIVE}"
log "MongoDB restore complete"

if [[ "${RESTORE_REDIS}" = "1" ]]; then
    log "restoring Redis from ${REDIS_DUMP}"
    docker compose stop "${REDIS_SERVICE}" >/dev/null
    docker compose cp "${REDIS_DUMP}" "${REDIS_SERVICE}:/data/dump.rdb"
    docker compose start "${REDIS_SERVICE}" >/dev/null
    until docker compose exec -T "${REDIS_SERVICE}" redis-cli ping | grep -q PONG; do
        sleep 1
    done
    log "Redis restore complete"
fi

log "restore complete"
