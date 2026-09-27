# Deployment

This guide describes how the Kingdoms stack is deployed to each environment.

## Environments

Two environments, each defined by a Docker Compose manifest in `envs/` and
a pinned state on its `deploy/<env>` state branch (ADR-0018):

| Environment | Manifest | Purpose |
| ----------- | -------- | ------- |
| `test` | `envs/test/docker-compose.yml` | VPS; deployed on demand (`/deploy` PR comment via the kingdoms-deployer GitHub App, or test-config change on main). Commit-SHA-tagged images | validation environment |
| `prod` | `envs/prod/docker-compose.yml` | VPS; released `vX.Y.Z` images only, promoted after validation on `test` and approved by the `prod` environment reviewers |

Each environment runs the same services:

- `kingdoms-bot` — the Discord bot (image `ghcr.io/merlin-pinpin-org/kingdoms-services`,
  published by the `Docker` workflow of the `kingdoms-services` repo)
- `kingdoms-mongo` — MongoDB 7.0 (persistence)
- `kingdoms-redis` — Redis 7.2 (hot state)

## Prerequisites

- Docker and Docker Compose on the host
- GitHub **environments** for the target environment (Settings →
  Environments): the `DISCORD_TOKEN` **secret** at minimum; the `BOT_ADMINS`
  **variable** (bot operators, kingdoms-services#35) so `/status` can list
  them; `MONGO_DB`, `LOG_LEVEL`, `KINGDOMS_BOT_IMAGE` (prod),
  `KINGDOMS_DEPLOY_URL` (deployed-artifact link shown by `/status`,
  kingdoms-infra#37) are optional. The runner injects them at
  deploy time — no secret is ever stored on the VPS or in the repository
  ([GitHub environment secrets docs](https://docs.github.com/en/actions/reference/environments#environment-secrets)).

## Deploying

Deployment is **GitOps-driven**: the pinned state on the `deploy/<env>`
state branches is applied by the deploy chain (`deploy.yml` routing →
`deploy-env.yml` per-environment deploy) running on a **self-hosted runner
installed on the VPS** — see [VPS-SETUP.md](VPS-SETUP.md) for the
step-by-step server installation. Environments are data, not workflows:
per-environment gating is GitHub-native (the `<env>` GitHub environment
carries the required reviewers; the `deploy/<env>` branch ruleset decides
whether a pin needs a PR — approving a production deployment is merging
it):

- `test` — **deployed by state push** (ADR-0018): a `/deploy` (or
  `/deploy <env>`) PR comment in `kingdoms-services` builds the PR image
  (`pr-<id>-<timestamp>-<sha>`) and pins it in the `deploy/test` state
  branch via the **GitHub App** (ephemeral token — setup in
  [DEPLOY-TEST-APP.md](DEPLOY-TEST-APP.md));
  the push deploys the pinned image. A test-config change on `main`
  re-pins the latest `sha-<sha>` image first (never on `prod` —
  `PROTECTED_ENVS` in `deploy.yml`). The state file records the
  image, version label, deploy URL, deployer and time — Git history is
  the audit trail.
- `prod` — **deployed by state push** (ADR-0018): released `vX.Y.Z`
  images only, promoted by the [Promote
  release](https://github.com/merlin-pinpin-org/kingdoms-services/blob/main/.github/workflows/release.yml)
  workflow of `kingdoms-services` once the release has been validated
  on `test`; the Deploy environment run then waits for the `prod`
  environment reviewers before deploying. The branch ruleset requires a
  PR, so approving a prod deployment is merging it.

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

## Troubleshooting

A deployment that does not start or never finishes is almost always one of
a few known causes. **Diagnose before touching anything**: run `make doctor`
or `make diagnose-deploy-<env>` (`scripts/diagnose_deploy.sh <env>`,
`--json` for agents) — it walks the causes in order, links every stale run
to cancel, and exits 1 when something blocks. The full runbook (including
the concurrency-zombie trap behind the 2026-09-24 prod incident) lives in
[DEVELOPER.md](DEVELOPER.md) § "A deploy stays pending".

| Symptom | Cause | What to do |
| ------- | ----- | ---------- |
| Newer deploy runs stay `pending`, no deployment status, no notification, runner never asked | A stale `waiting`/`pending` run holds the `deploy-<env>` concurrency group forever | Cancel the stale run the diagnose script links ([DEVELOPER.md](DEVELOPER.md) runbook) |
| The run is `waiting` with a pending deployment | Environment approval: the required reviewers have not approved yet | Approve or dismiss the deployment in the GitHub UI |
| The deploy job is queued forever, `runner_name: null` | No runner carries the `env-<env>` label, or the runner is offline | Check the runner on the VPS (`sudo ./svc.sh status`, [VPS-SETUP.md](VPS-SETUP.md)) |
| The deploy fails: `DISCORD_TOKEN is not set` | The GitHub `<env>` environment secret is missing | Settings → Environments → `<env>`; the manifests fail closed on missing secrets |
| The deploy fails at the health gate and rolls back | A service never reports `healthy` within the timeout | Inspect `docker compose logs` on the VPS; the automatic rollback already restored the latest backup |
| The image pull fails: `unauthorized` | `kingdoms-infra` lost its Read role on the bot image package | [DEPLOY-TEST-APP.md](DEPLOY-TEST-APP.md) §5 (package Actions access) |
| A deploy-chain fix merged on `main` does not change behavior | Deploy runs use the workflow revision of the state branch | Wait for the state-branch propagation ([ENVIRONMENTS.md](ENVIRONMENTS.md) § "Keeping the state branches current") |

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

Rollback is a **state operation** (ADR-0018): a failed or rejected
deployment rolls the pinned state back — never the code on `main`,
never another repository.

`scripts/rollback.sh <env> [archive.gz] [--auto]`:

- **`--auto` (the deploy.sh recovery path)** — when the post-deploy
  health gate fails, the script reverts the last pin commit and pushes
  the revert to `deploy/<env>`: the push itself re-triggers the Deploy
  environment workflow, which re-applies the previous known-good image.
  No data is touched. On `deploy/prod` the push is rejected by the
  "Deploy PROD" ruleset (required PR) — by design; the script then
  restores the latest backup and fails loudly so a human opens the
  revert PR (the `Rollback state` workflow).
- **manual** — restores the most recent backup (or a given archive),
  interactive unless the archive is given with `--yes` semantics.

```bash
./scripts/rollback.sh test                              # latest backup, interactive
./scripts/rollback.sh test backups/test-...archive.gz  # specific archive
```

The `Rollback state` workflow (`.github/workflows/rollback.yml`) is the
deliberate path: a `repository_dispatch` from the post-deploy battery or
a manual dispatch reverts the pin and either pushes it directly
(`deploy/test`) or opens a revert PR (`deploy/prod`) for review.
