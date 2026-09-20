#!/usr/bin/env bash
# Deploy the Kingdoms stack to a target environment (dev, staging, prod).
# Idempotent: safe to re-run on an already-deployed environment.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(dev staging prod)
ENVIRONMENT="${1:-dev}"
ENV_DIR="${REPO_ROOT}/deploy/${ENVIRONMENT}"
COMPOSE_FILE="${ENV_DIR}/docker-compose.yml"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}>"
    exit 1
}

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage
[[ -f "${COMPOSE_FILE}" ]] || { echo "Missing compose file: ${COMPOSE_FILE}"; exit 1; }

if [[ ! -f "${ENV_DIR}/.env" ]]; then
    echo "Missing ${ENV_DIR}/.env (copy it from .env.example and fill in secrets)."
    exit 1
fi

cd "${ENV_DIR}"
docker compose pull
docker compose up -d --remove-orphans
docker compose ps
echo "Deployment to '${ENVIRONMENT}' applied."
