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

- `kingdoms-bot` — the Discord bot (built from `docker/Dockerfile`)
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
./scripts/restore_db.sh dev backups/dev-<timestamp>.archive.gz
```

`restore_db.sh` asks for confirmation before overwriting data.

## Rollback

Rollback is done by reverting the offending commit on `main` (or deploying a
previous tag) and letting the pipeline re-apply the previous manifest, then
restoring the database from a backup if needed.
