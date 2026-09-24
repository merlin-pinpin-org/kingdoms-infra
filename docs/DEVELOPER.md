# kingdoms-infra — developer guide

`kingdoms-infra` holds the infrastructure of the Kingdoms Discord bot
platform: Docker environments, CI/CD workflows, GitOps manifests and the
deployment scripts executed on the VPS runners.

Read the shared
[conventions](https://github.com/merlin-pinpin-org/kingdoms/blob/main/docs/CONVENTIONS.md)
and the
[operating model](https://github.com/merlin-pinpin-org/kingdoms/blob/main/docs/VIBEWORKFLOW.md)
in the `kingdoms` repo. This page covers what is specific to working *in
this repo*.

## Layout

| Path | Content |
| ---- | ------- |
| `AGENTS.md` | Short agent entry point (points here) |
| `envs/<env>/` | One directory per environment: `docker-compose.yml` + `state/` (the pinned state files synced to the `deploy/<env>` branch) |
| `deploy/<env>/` | Protected state branches (one per environment) pinning the image and deploy metadata — the GitOps source of truth (ADR-0018) |
| `.github/workflows/` | CI checks + the deploy chain (`deploy.yml` routing, `deploy-env.yml` reusable per-env deploy, `pin-state.yml`, `sync-state.yml`, `repin-on-config-change.yml`) |
| `scripts/` | `deploy.sh` (idempotent, health-gated), `restore_db.sh`, backup scripts |
| `docs/` | [ENVIRONMENTS.md](ENVIRONMENTS.md), [GITOPS.md](GITOPS.md), [DEPLOYMENT.md](DEPLOYMENT.md), [VPS-SETUP.md](VPS-SETUP.md) |

## Environments are data

An environment is defined by four pieces, all data — no per-env workflow:

- a directory `envs/<env>/` (compose manifest + `state/`),
- a state branch `deploy/<env>` (protected),
- a runner with the label `env-<env>`,
- a GitHub environment `<env>` (with its reviewers/protection).

Adding an environment = creating the directory, the branch, the runner and
the GitHub environment; the workflows pick it up automatically. `prod` is
protected (`PROTECTED_ENVS`): PR deploys never target it; only released
`vX.Y.Z` images are pinned there. See
[ENVIRONMENTS.md](ENVIRONMENTS.md).

## Checks

Anyone can run the local checks with a public clone, no credentials:

```bash
bash -n scripts/*.sh
shellcheck scripts/*.sh   # if available
docker compose -f envs/test/docker-compose.yml config
```

Run `bash -n` (and shellcheck when available) on every script before
pushing. Anything that cannot run in the dev sandbox (Compose boot, stack
healthchecks, backup/restore round-trips, entrypoint runs) is exercised by
the CI workflows instead.

## Deploy chain (summary)

1. `/deploy [env]` on a `kingdoms-services` PR (or a release) dispatches
   `pin-state` with the image and deploy metadata.
2. `pin-state.yml` merges `main` into `deploy/<env>` and writes the pin
   (`envs/<env>/state/kingdoms-bot.yml`) atomically (single-writer
   concurrency `deploy-state-<env>`, ADR-0018).
3. The push triggers `deploy.yml` → `deploy-env.yml`, which runs on the
   `env-<env>` self-hosted runner, applies the pinned state with
   `scripts/deploy.sh` and gates on health.
4. `sync-state.yml` propagates `main` to the state branches; config changes
   on `main` trigger a repin (never on `prod`).

Deployment is **GitOps-driven**: changes to the state branches are applied
by CI/CD, never by hand on the VPS. Deploy scripts must stay idempotent and
support rollback (`deploy.sh`, database restore via `restore_db.sh`).

## Workflow pitfalls (learned the hard way)

- A required status check never uses a `paths:` filter — it must report on
  every PR (fixed for `check-infra.yml`; applies to every workflow backing
  a required check).
- `paths:` filters on the deploy chain must include `scripts/deploy.sh`
  and the workflow files themselves, or a merge triggers no deploy.
- Dynamic `runs-on` needs
  `fromJSON(format('[\"self-hosted\", \"kingdoms\", \"env-{0}\"]', inputs.environment))`
  — `format()` alone yields a string, which becomes one literal label.
- Reusable workflows cannot elevate permissions: the caller grants
  `packages: read`.
- Deploy runs use the workflow file **from the state branch** — fixes to
  the deploy chain need sync propagation to take effect.
- `client_payload` of `repository_dispatch` is capped at 10 properties.

## Keeping docs in sync

Any infrastructure change must be reflected in the `kingdoms` documentation
(source of truth) before merge, and in this repo's own `docs/` pages
(ENVIRONMENTS, GITOPS, DEPLOYMENT) when they describe the changed behavior.
