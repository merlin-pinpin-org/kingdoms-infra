# Deployment

This guide describes how the Kingdoms stack is deployed to each environment.

## Environments

Three environments, each defined by a Docker Compose manifest in `deploy/`:

| Environment | Manifest | Purpose |
| ----------- | -------- | ------- |
| `dev` | `deploy/dev/docker-compose.yml` | Local development |
| `staging` | `deploy/staging/docker-compose.yml` | Pre-production validation |
| `prod` | `deploy/prod/docker-compose.yml` | Production |

Each environment runs the same services:

- `kingdoms-bot` — the Discord bot (image `ghcr.io/merlin-pinpin/kingdoms-services`,
  published by the `Docker` workflow of the `kingdoms-services` repo)
- `kingdoms-mongo` — MongoDB 7.0 (persistence)
- `kingdoms-redis` — Redis 7.2 (hot state)

## Prerequisites

- Docker and Docker Compose on the host
- A `.env` file in the environment directory (copy from `.env.example`,
  fill in real credentials). Real credentials live only on the VPS or in
  GitHub secrets — never in the repository.

## Deploying

Deployment is **GitOps-driven**: changes to `deploy/` are applied by the
CI/CD pipeline (`.github/workflows/cd.yml`), never by hand on the VPS.

Every deployment enforces two safety gates:

1. **Pre-deploy backup (mandatory)**: `scripts/deploy.sh` runs
   `scripts/backup_db.sh` *before* touching the stack and aborts the
   deployment if the backup fails.
2. **Post-deploy health gate**: after `docker compose up`, the script waits
   for every service to report `healthy`; if a service fails the gate, the
   script triggers an automatic rollback (`scripts/rollback.sh --auto`).
   The bot serves a liveness endpoint (`GET /healthz`, port 8000) for the
   whole lifetime of the process; the compose healthcheck probes it and the
   gate reports a crash-looping bot as `unhealthy`.

For a manual, reproducible local deployment (dev only):

```bash
cp deploy/dev/.env.example deploy/dev/.env
./scripts/deploy.sh dev
```

`scripts/deploy.sh` is idempotent: re-running it on a deployed environment
converges to the manifest state.

## Database backup and restore

```bash
./scripts/backup_db.sh dev                # writes backups/dev-<timestamp>.archive.gz
./scripts/restore_db.sh dev backups/dev-<timestamp>.archive.gz --yes
```

The round trip is continuously verified: the CI job
`Backup/restore round-trip test` seeds reference data, backs it up, wipes
the database, restores the archive and asserts the restored documents are
identical to the reference (count + full document diff).

`restore_db.sh` refuses non-gzip archives and asks for confirmation unless
`--yes` is passed. Every backup is checked for emptiness and gzip integrity
before being accepted.

## Rollback

`scripts/rollback.sh <env>` restores the most recent backup of the
environment (or a given archive), reverts the `deploy/` manifests to the
previous committed revision when git is available, and re-applies the
stack:

```bash
./scripts/rollback.sh dev                              # latest backup, interactive
./scripts/rollback.sh dev backups/dev-...archive.gz    # specific archive
```

Rollback is also the automatic recovery path of `deploy.sh`: when the
post-deploy health gate fails, the deployment rolls back to the latest
backup without human intervention.
