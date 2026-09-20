#!/usr/bin/env bash
# Restore the MongoDB data of a target environment from a gzipped archive.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(dev staging prod)
ENVIRONMENT="${1:-dev}"
ARCHIVE="${2:-}"
ENV_DIR="${REPO_ROOT}/deploy/${ENVIRONMENT}"
COMPOSE_FILE="${ENV_DIR}/docker-compose.yml"
MONGO_SERVICE="kingdoms-mongo"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}> <archive.gz>"
    exit 1
}

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ -n "${ARCHIVE}" && -f "${ARCHIVE}" ]] || { echo "Archive not found: ${ARCHIVE}"; usage; }
[[ -f "${COMPOSE_FILE}" ]] || { echo "Missing compose file: ${COMPOSE_FILE}"; exit 1; }

echo "Restoring ${ARCHIVE} to '${ENVIRONMENT}'."
read -r -p "This overwrites existing data. Continue? [y/N] " confirm
[[ "${confirm}" == "y" || "${confirm}" == "Y" ]] || { echo "Aborted."; exit 1; }

cd "${ENV_DIR}"
docker compose exec -T "${MONGO_SERVICE}" mongorestore --archive --gzip --drop < "${ARCHIVE}"
echo "Restore to '${ENVIRONMENT}' complete."
