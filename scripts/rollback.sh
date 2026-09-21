#!/usr/bin/env bash
# Roll back the Kingdoms stack to its last known-good state.
# Restores the most recent backup (or a given archive) and reverts the
# compose manifest to the previously deployed revision when git is available.

set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS=(test prod)
ENVIRONMENT="${1:-test}"
ARCHIVE="${2:-}"
MODE="${3:-}"
BACKUP_DIR="${BACKUP_DIR:-${REPO_ROOT}/backups}"

usage() {
    echo "Usage: $0 <${ENVIRONMENTS[*]}> [archive.gz] [--auto]"
    echo "  BACKUP_DIR=<dir> overrides the backup directory (default: <repo>/backups)."
    echo "  Without an archive, restores the most recent backup of the environment."
    echo "  --auto skips confirmation (used by deploy.sh after a failed health gate)."
    exit 1
}

log() { echo "[rollback:${ENVIRONMENT}] $*"; }

die() { echo "[rollback:${ENVIRONMENT}] ERROR: $*" >&2; exit 1; }

[[ " ${ENVIRONMENTS[*]} " == *" ${ENVIRONMENT} "* ]] || usage

if [[ -z "${ARCHIVE}" || ! -f "${ARCHIVE}" ]]; then
    if [[ -n "${ARCHIVE}" ]]; then
        die "archive not found: ${ARCHIVE}"
    fi
    LATEST="$(ls -1t "${BACKUP_DIR}/${ENVIRONMENT}-"*.archive.gz 2>/dev/null | head -n 1 || true)"
    [[ -n "${LATEST}" ]] || die "no backup found in ${BACKUP_DIR}; nothing to roll back to"
    ARCHIVE="${LATEST}"
fi

log "rolling back to ${ARCHIVE}"

if [[ "${MODE}" != "--auto" ]]; then
    echo "This overwrites the current state of '${ENVIRONMENT}'."
    read -r -p "Continue? [y/N] " answer
    [[ "${answer}" == "y" || "${answer}" == "Y" ]] || { echo "Aborted."; exit 1; }
fi

if command -v git >/dev/null 2>&1 && git -C "${REPO_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "reverting deploy/ manifests to the previous committed revision"
    git -C "${REPO_ROOT}" checkout HEAD~1 -- deploy/ 2>/dev/null \
        && log "manifests reverted to HEAD~1" \
        || log "no previous manifest revision found; keeping current manifests"
fi

"${REPO_ROOT}/scripts/restore_db.sh" "${ENVIRONMENT}" "${ARCHIVE}" --yes
log "rollback complete"
