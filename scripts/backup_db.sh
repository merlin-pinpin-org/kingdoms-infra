#!/usr/bin/env bash
# Back up the MongoDB data of a target environment.
# Produces a gzipped archive in the backup directory.

set -euo pipefail

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

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ -f "${COMPOSE_FILE}" ]] || { echo "Missing compose file: ${COMPOSE_FILE}"; exit 1; }

mkdir -p "${BACKUP_DIR}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="${BACKUP_DIR}/${ENVIRONMENT}-${TIMESTAMP}.archive.gz"

cd "${ENV_DIR}"
docker compose exec -T "${MONGO_SERVICE}" mongodump --archive --gzip > "${ARCHIVE}"
echo "Backup written to ${ARCHIVE}"
