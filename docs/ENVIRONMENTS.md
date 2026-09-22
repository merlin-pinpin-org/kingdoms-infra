# Environments

The Kingdoms platform runs the same stack in two environments. This page
is the environment matrix; the deployment procedure lives in
[DEPLOYMENT.md](DEPLOYMENT.md).

| | test | prod |
| --- | --- | --- |
| Manifest | `deploy/test/docker-compose.yml` | `deploy/prod/docker-compose.yml` |
| Bot image | `ghcr.io/...` commit-SHA tagged (`pr-<n>-sha-<sha>` for `/deploy-test`, `sha-<sha>` for main) | `ghcr.io/...` released tag `vX.Y.Z` via `KINGDOMS_BOT_IMAGE` |
| Image pull policy | `missing` | `always` |
| Host | VPS (runner) | VPS (runner) |
| Secrets | GitHub environment secrets (injected by the runner) | GitHub environment secrets |
| MongoDB exposed ports | 27017 | — |
| Redis exposed ports | 6379 | — |
| Redis persistence | volume | volume + AOF |
| Bot memory limit | — | 512M |
| Deploy trigger | Deploy test: on demand (`/deploy-test` PR comment via the GitHub App, or test-config change on main) | Deploy prod: released tag `vX.Y.Z` or manual by identified production deployers (not implemented yet) |
| Pre-deploy backup | mandatory | mandatory |
| Env template | — (secrets live in GitHub environment `test`) | — (GitHub environment `prod`) |
| Bot healthcheck | `/healthz` (compose + image) | `/healthz` (compose + image) |

## Configuration variables

Secrets are **never stored on the VPS**. They live in GitHub
*environment secrets* (Settings → Environments → `test` /
`prod` → Add environment secret) and the self-hosted runner injects them
into `docker compose` at deploy time. The manifests read them by name
and fail closed when one is missing.

| Variable | Description |
| -------- | ----------- |
| `DISCORD_TOKEN` | Discord bot token (required) |
| `MONGO_URI` | MongoDB connection string (overridden by compose inside the stack) |
| `MONGO_DB` | MongoDB database name |
| `REDIS_URI` | Redis connection string (overridden by compose inside the stack) |
| `LOG_LEVEL` | Python logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`) |
| `KINGDOMS_BOT_IMAGE` | **Prod only**: full bot image reference, e.g. `ghcr.io/merlin-pinpin-org/kingdoms-services:v0.1.0` |

The compose manifests override `MONGO_URI` and `REDIS_URI` so the bot always
targets the in-stack services.

## Access and trigger protections (as configured on GitHub, 2026-09)

Who may deploy what is enforced by GitHub at three layers. The
environments below gate **secret access and job execution**; the Actions
policy gates **who may trigger the workflows** (see
[DEPLOY-TEST-APP.md](DEPLOY-TEST-APP.md) §4).

| Protection | test | prod |
| --- | --- | --- |
| Deployment branch policy | `main`, `vibe/**` | `main` only |
| Required reviewers | — | `merlin-pinpin` (approval before any prod job consumes prod secrets) |
| Wait timer | — | — |
| Actions policy (who may trigger the workflow) | `deploy-test-dispatch`: `kingdoms-deployer[bot]` + admins (via REST API — the UI picker does not list third-party apps); events `workflow_dispatch`, `push` | not implemented yet (`deploy-prod.yml` exits early; the prod deploy path is designed for released tags and identified production deployers) |

Reading the matrix:

- **test** is open to feature branches (`vibe/**`) so the game designer can
  validate a PR live in Discord via `/deploy-test` before it merges. The
  dispatch always references `ref: main` on this repository, so the
  `vibe/**` branch-policy entry is tolerance, not the actual gate — the
  real gates are the Actions policy (who dispatches) and the
  `KINGDOMS_BOT_IMAGE` input (what image runs).
- **prod** deploys only from `main` (a released image, per ADR-0007) and
  requires an explicit human approval before the job starts. Even an
  accidental `workflow_dispatch` of `deploy-prod.yml` cannot consume prod
  secrets without a reviewer's approval.

## Deploying a test image from a services branch

The flow for validating code changes on the test environment (no manual
branch on this repository):

1. The code change lives on a `vibe/<slug>` branch of **kingdoms-services**,
   opened as a PR (draft while work remains).
2. The **Docker** workflow of kingdoms-services already builds the image on
   every PR push (`ghcr.io/merlin-pinpin-org/kingdoms-services:pr-<n>-sha-<sha>`).
3. A `/deploy-test` comment on the PR builds/publishes that exact image and
   dispatches this repository's **Deploy test** workflow with it via the
   `kingdoms-deployer` GitHub App (ephemeral token, Actions: write only).
4. **Deploy test** runs on the self-hosted runner (test VPS), pulls the
   authenticated image (package access: kingdoms-infra has role Read on the
   package — [DEPLOY-TEST-APP.md](DEPLOY-TEST-APP.md) §5), and restarts the
   bot with it. The health gate confirms the stack is healthy.

So: the image under test is always a PR image tagged by PR number and
commit SHA — never an untagged `latest`, never a hand-built local image on
the VPS. Rolling back is re-running `/deploy-test` on the previous PR, or
letting the next config-change deploy on `main` restore the default image
(`:main`).
