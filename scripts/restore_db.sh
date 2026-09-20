#!/usr/bin/env bash
# Restore the MongoDB data of a target environment from a gzipped archive.
# Refuses to restore a non-gzip file; asks for confirmation unless --yes.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(dev staging prod)
ENVIRONMENT="${1:-dev}"
ARCHIVE="${2:-}"
CONFIRM="${3:-}"
COMPOSE_FILE="${REPO_ROOT}/deploy/${ENVIRONMENT}/docker-compose.yml"
MONGO_SERVICE="kingdoms-mongo"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}> <archive.gz> [--yes]"
    exit 1
}

log() { echo "[restore:${ENVIRONMENT}] $*"; }

die() { echo "[restore:${ENVIRONMENT}] ERROR: $*" >&2; exit 1; }

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ -n "${ARCHIVE}" && -f "${ARCHIVE}" ]] || { echo "Archive not found: ${ARCHIVE}"; usage; }
[[ "$(file -b --mime-type "${ARCHIVE}")" == "application/gzip" ]] \
    || die "not a gzip archive: ${ARCHIVE} (mongorestore expects --archive --gzip)"
[[ -f "${COMPOSE_FILE}" ]] || die "missing compose file: ${COMPOSE_FILE}"

if [[ "${CONFIRM}" != "--yes" ]]; then
    echo "Restoring ${ARCHIVE} to '${ENVIRONMENT}' — this overwrites existing data."
    read -r -p "Continue? [y/N] " answer
    [[ "${answer}" == "y" || "${answer}" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

log "restoring ${ARCHIVE}"
cd "$(dirname "${COMPOSE_FILE}")"
docker compose exec -T "${MONGO_SERVICE}" mongorestore --archive --gzip --drop <"${ARCHIVE}"
log "restore complete"
