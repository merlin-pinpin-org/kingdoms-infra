# Environments

The Kingdoms platform runs the same stack in two environments. This page
is the environment matrix; the deployment procedure lives in
[DEPLOYMENT.md](DEPLOYMENT.md).

| | test | prod |
| --- | --- | --- |
| Manifest | `deploy/test/docker-compose.yml` | `deploy/prod/docker-compose.yml` |
| Bot image | `ghcr.io/...` pinned by the state branch: `pr-<id>-<timestamp>-<sha>` for `/deploy-test`, `sha-<sha>` for main | `ghcr.io/...` released tag `vX.Y.Z` via `KINGDOMS_BOT_IMAGE` |
| Image pull policy | `missing` | `always` |
| Host | VPS (runner) | VPS (runner) |
| Secrets | GitHub environment secrets (injected by the runner) | GitHub environment secrets |
| MongoDB exposed ports | 27017 | — |
| Redis exposed ports | 6379 | — |
| Redis persistence | volume | volume + AOF |
| Bot memory limit | — | 512M |
| Deploy trigger | Push to the `deploy/test` state branch (written by the GitHub App from a `/deploy-test` PR comment, or re-pinned by a test-config change on main) | Push to the `deploy/prod` state branch (written by the release pipeline; the branch ruleset requires a PR — approving a prod deploy is merging it) |
| Pre-deploy backup | mandatory | mandatory |
| Env template | — (secrets live in GitHub environment `test`) | — (GitHub environment `prod`) |
| State branch | `deploy/test` (ADR-0018) | `deploy/prod` (ADR-0018) |
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
| `BOT_ADMINS` | Comma-separated Discord user IDs of the bot operators (kingdoms-services#35). Provision it as an environment **secret** or **variable** — the deploy workflow accepts either; empty means `/status` reports no operator |
| `KINGDOMS_DEPLOY_URL` | URL shown by the `/status` Deploy field: the PR's `/deploy-test` comment permalink, a commit link for main, the release URL for prod (empty → `n/a`) |
| `KINGDOMS_DEPLOY_LABEL` | Label shown by the `/status` Version field: `pr-<id>-<timestamp>-<sha>` for a PR deploy, `main@<sha>` for main, `vX.Y.Z` for a release (empty → package version) |
| `MONGO_URI` | MongoDB connection string (overridden by compose inside the stack) |
| `MONGO_DB` | MongoDB database name |
| `REDIS_URI` | Redis connection string (overridden by compose inside the stack) |
| `LOG_LEVEL` | Python logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`) |
| `KINGDOMS_BOT_IMAGE` | **Prod only**: full bot image reference, e.g. `ghcr.io/merlin-pinpin-org/kingdoms-services:v0.1.0` |

The compose manifests override `MONGO_URI` and `REDIS_URI` so the bot always
targets the in-stack services.

## Adding an environment (ADR-0018 checklist)

A new environment `<name>` is a four-item checklist — no workflow fork,
no script change:

1. **Manifest**: `deploy/<name>/docker-compose.yml` on `main` (copy the
   test one; the image is pinned by state, never a floating tag).
2. **Runner label**: the environment VPS's self-hosted runner carries
   `env-<name>` (see [VPS-SETUP.md](VPS-SETUP.md)) — one runner per VPS.
3. **State branch**: `deploy/<name>` with the initial state commit
   (`deploy/state/<name>/kingdoms-bot.yml`); the deploy workflow reads
   the pinned image from it.
4. **Branch ruleset + workflow**: protect `deploy/<name>` (no force-push,
   no deletion; PR required for prod-like environments), and add a
   `deploy-<name>.yml` workflow from the same template as `deploy-test.yml`
   (trigger: push on `deploy/<name>` paths `deploy/state/**`; runner label
   `env-<name>`; GitHub environment `<name>` with its secrets).

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

The `/deploy-test` dispatch also carries the **deploy URL** (the PR link) so
the bot's `/status` shows what is running (kingdoms-infra#37): a deploy from
`/deploy-test` points at the PR, a config-change deploy on `main` points at
the deployed commit, and a prod deploy points at the released `vX.Y.Z` tag.
