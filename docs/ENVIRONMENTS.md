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
| `BOT_ADMINS` | Comma-separated Discord user IDs of the bot operators (kingdoms-services#35), provisioned as an environment **variable**; empty means `/status` reports no operator |
| `KINGDOMS_DEPLOY_URL` | URL shown by the `/status` Deploy field: the `/deploy-test` deployment comment permalink, a tree link (`/tree/<sha>`) for main, the release URL for prod (empty → `n/a`) |
| `KINGDOMS_DEPLOY_LABEL` | Label shown by the `/status` Version field: `pr-<id>-<timestamp>-<sha>` for a PR deploy, `main@<sha>` for main, `vX.Y.Z` for a release (empty → package version) |
| `KINGDOMS_DEPLOY_RUN_URL` | URL of the deploy job shown by the `/status` Deploy field — injected by the deploy workflow itself (`github.server_url/repository/actions/runs/<run_id>`), so the running bot links the exact job that deployed it |
| `KINGDOMS_DEPLOY_INFRA_LABEL` | Short label of the deployed infra state (`deploy/<env>@<sha>`), shown by the `/status` Deploy field — injected by the deploy workflow |
| `KINGDOMS_DEPLOY_INFRA_URL` | Tree URL of the deployed infra state commit, the link behind `deploy/<env>@<sha>` |
| `KINGDOMS_DEPLOY_KIND` | Deploy kind for the typed `/status` links: `pr`, `main`, or `release` — written by the deploy pipelines in the pinned state file |
| `KINGDOMS_DEPLOY_REF` | Deploy reference for the typed link: PR number, short sha, or release tag |
| `KINGDOMS_DEPLOY_TREE_URL` | Tree URL behind the `tree` link of a main/release version |
| `KINGDOMS_DEPLOY_TS` | Unix timestamp of the deployed commit (relative Discord time in the Version field) |
| `KINGDOMS_DEPLOY_RUN_NUMBER` | Number of the deploy job — renders as `Deployment #<n>` in the Deploy field |
| `KINGDOMS_DEPLOY_RUN_TS` | Unix timestamp of the deploy job start (relative Discord time in the Deploy field) |

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

## Keeping the state branches current (pipeline propagation)

The state branches are cut from `main` once, then evolve on their own:
the pipelines only ever touch `deploy/state/<env>/kingdoms-bot.yml`, so
any change to a **deploy workflow, manifest or script merged on `main`
keeps running in its old revision on the state branch** until it is
propagated. A missed propagation is invisible — the deploy succeeds with
stale pipeline code (this is how `BOT_ADMINS` once read `secrets.*` on
`deploy/test` while `main` had moved to `vars.*` — `/status` showed no
admin).

Whenever a merge on `main` changes a deploy workflow, a `deploy/<env>/`
manifest or `scripts/deploy.sh`, it must be propagated to every state
branch. State branches carry their own state commits (and sync merges),
so this is a merge, not a fast-forward. Propagation is **automated**:

- the [Sync state branches](.github/workflows/sync-state.yml) workflow
  merges `main` into each `deploy/<env>` on every push to `main` (no-op
  when the state branch already contains `main`);
- the [Pin state](.github/workflows/pin-state.yml) workflow (the
  `/deploy-test` path) merges `main` in the same commit as the image pin,
  so a deployment can never run stale manifests either.

Adding an environment is adding it to both matrices. The manual
equivalent, for reference or recovery:

```
git fetch origin && git checkout deploy/<env>
git merge origin/main -m "deploy(<env>): sync state branch with main"
git push origin deploy/<env>
```

The sync push deploys with the unchanged pinned state — safe by design.
The `sync-state` workflow pushes with the `kingdoms-deployer` App token —
the same actor the deploy pipelines use to write the pinned state, and the
only non-admin actor in the `deploy/*` ruleset bypass lists.

**Single-writer design:** every writer to a `deploy/<env>` state branch
lives in this repository and shares one concurrency group,
`deploy-state-<env>` — pin-state.yml (image pins dispatched by the deploy
pipelines), sync-state.yml and the re-pin job of deploy-test.yml. GitHub
serializes them, so a pin can never race a sync (the historical "cannot
lock ref" failure); a pin also merges `main` into the state branch, so
deployments cannot run stale pipeline code. Known limit: only the latest
queued run of a group survives; a superseded sync is harmless — the next
push to `main` re-triggers it.

The rulesets (no force-push) keep the history auditable:
`git log main..deploy/<env>` shows exactly which state commits exist
beyond `main`. The [Branch and tag rules audit](#branch-and-tag-rules-audit)
workflow fails when a state branch drifts from `main`.

## Branch and tag rules (expected configuration)

The authoritative configuration lives on GitHub (Settings → Rules → Rule
sets); this table is the expected state, and the
**Branch and tag rules audit** workflow (`.github/workflows/rules-audit.yml`)
fails when reality drifts from it — run it on demand, or after every
ruleset change.

### kingdoms-infra

| Ref / scope | Ruleset | Rules | Required status checks |
| --- | --- | --- | --- |
| `main` | `main` | deletion, non-fast-forward, linear history, PR required (1 approval), status checks | the 6 infra checks (below) |
| `deploy/test` | `Deploy TEST` | deletion, non-fast-forward, linear history, status checks | the 6 infra checks (below) |
| `deploy/prod` (+ default branch) | `Deploy PROD` | deletion, non-fast-forward, linear history, PR required, status checks | the 6 infra checks (below) |

Infra required status checks (all three branch rulesets):

1. `Lint scripts and shell files`
2. `Validate compose manifests`
3. `Validate infrastructure files`
4. `Backup/restore round-trip test`
5. `Smoke test (test stack boot)`
6. `cla`

### kingdoms-services

| Ref / scope | Ruleset | Rules | Required status checks |
| --- | --- | --- | --- |
| `main` | `main` | deletion, non-fast-forward, linear history, PR required (1 approval), status checks | `Lint (ruff)`, `Typecheck (mypy strict)`, `Unit tests (pytest)`, `Validate and boot docker-compose.yml`, `Smoke test (bot image + MongoDB + Redis)`, `Discord smoke (real gateway via the CI/CD bot)`, `Build and test the image`, `Generate and check pydoc freshness`, `cla` |
| tags `v*.*.*` | `release-tags` | deletion, non-fast-forward | — |

The `release-tags` ruleset is **required for prod**: it lets anyone push a
`vX.Y.Z` tag (rulesets cannot block tag *creation* by name for non-admins),
but forbids deleting or force-updating one — a release is immutable once
cut. The Docker workflow publishes the `vX.Y.Z` image only for the
`v*.*.*` tag classifier.

### kingdoms

| Ref / scope | Ruleset | Rules | Required status checks |
| --- | --- | --- | --- |
| `main` | `main` | deletion, non-fast-forward, linear history, PR required (1 approval), status checks | `cla`, `check` (docs validation) |

## Access and trigger protections (as configured on GitHub, 2026-09)

Who may deploy what is enforced by GitHub at three layers. The
environments below gate **secret access and job execution**; the Actions
policy gates **who may trigger the workflows** (see
[DEPLOY-TEST-APP.md](DEPLOY-TEST-APP.md) §4).

| Protection | test | prod |
| --- | --- | --- |
| Deployment branch policy | `deploy/test` (state branch, ADR-0018), `main`, `vibe/**` | `deploy/prod` (state branch, ADR-0018) |
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
2. The **Docker** workflow of kingdoms-services builds the image on
   every PR push; `/deploy-test` publishes a timestamped tag
   (`pr-<id>-<timestamp>-<sha>`) from the PR head.
3. A `/deploy-test` comment on the PR builds/publishes that exact image and
   dispatches this repository's **Deploy test** workflow with it via the
   `kingdoms-deployer` GitHub App (ephemeral token, Actions: write only).
4. **Deploy test** runs on the self-hosted runner (test VPS), pulls the
   authenticated image (package access: kingdoms-infra has role Read on the
   package — [DEPLOY-TEST-APP.md](DEPLOY-TEST-APP.md) §5), and restarts the
   bot with it. The health gate confirms the stack is healthy.

So: the image under test is always a PR image tagged by PR number,
timestamp and commit SHA — never an untagged `latest`, never a hand-built
local image on the VPS. Rolling back is re-running `/deploy-test` on the
previous PR, or letting the next config-change deploy on `main` restore the
default image (`sha-<sha>` of main).

The `/deploy-test` dispatch also carries the **deploy URL** and the
**version label** so the bot's `/status` shows what is running
(kingdoms-infra#37): a PR deploy's URL is the permalink of the deployment
comment (label `pr-<id>-<timestamp>-<sha>`), a config-change deploy on

`main` points at the deployed source tree `/tree/<sha>` (label
`main@<sha>`), and a prod deploy points at the released `vX.Y.Z` GitHub
release (label `vX.Y.Z`).

The Deploy field additionally links the kingdoms-infra deploy job itself
(`KINGDOMS_DEPLOY_RUN_URL`).
