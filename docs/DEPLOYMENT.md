# Deployment

This guide describes how the Kingdoms stack is deployed to each environment.

## Environments

Three environments, each defined by a Docker Compose manifest in `deploy/`:

| Environment | Manifest | Purpose |
| ----------- | -------- | ------- |
| `test` | `deploy/test/docker-compose.yml` | VPS; auto-deploys on test-config change on main, `/deploy-test` PR comment, or manual dispatch (validation environment) |
| `prod` | `deploy/prod/docker-compose.yml` | VPS; deploys on prod-config change on main — **not implemented yet** (the workflow fails with the setup instructions) |

Each environment runs the same services:

- `kingdoms-bot` — the Discord bot (image `ghcr.io/merlin-pinpin/kingdoms-services`,
  published by the `Docker` workflow of the `kingdoms-services` repo)
- `kingdoms-mongo` — MongoDB 7.0 (persistence)
- `kingdoms-redis` — Redis 7.2 (hot state)

## Prerequisites

- Docker and Docker Compose on the host
- GitHub **environment secrets** for the target environment (Settings →
  Environments): `DISCORD_TOKEN` at minimum; `MONGO_DB`, `LOG_LEVEL`,
  `KINGDOMS_BOT_IMAGE` (prod) are optional. The runner injects them at
  deploy time — no secret is ever stored on the VPS or in the repository
  ([GitHub environment secrets docs](https://docs.github.com/en/actions/reference/environments#environment-secrets)).

## Deploying

Deployment is **GitOps-driven**: changes to `deploy/` are applied by the
CD pipelines running on a **self-hosted runner installed on the VPS** —
see [VPS-SETUP.md](VPS-SETUP.md) for the step-by-step server installation.
There is **one workflow per environment**
(`.github/workflows/deploy-<env>.yml`), so GitHub policies can gate who
may deploy each environment independently. `test` deploys on every test
configuration change on `main`, on a `/deploy-test` PR comment in
`kingdoms-services` (which builds and deploys the PR image), or manually;
`prod` deploys on prod configuration changes on `main` and is **not
implemented yet** — the workflow fails with the list of GitHub environment
variables to create first.

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

For a manual, reproducible deployment (test only, e.g. on the VPS):

```bash
DISCORD_TOKEN=... ./scripts/deploy.sh test
```

`scripts/deploy.sh` is idempotent: re-running it on a deployed environment
converges to the manifest state.

## Database backup and restore

```bash
./scripts/backup_db.sh test              # writes backups/test-<timestamp>.archive.gz
./scripts/restore_db.sh test backups/test-<timestamp>.archive.gz --yes
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
./scripts/rollback.sh test                              # latest backup, interactive
./scripts/rollback.sh test backups/test-...archive.gz  # specific archive
```

Rollback is also the automatic recovery path of `deploy.sh`: when the
post-deploy health gate fails, the deployment rolls back to the latest
backup without human intervention.
