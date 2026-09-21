# Environments

The Kingdoms platform runs the same stack in three environments. This page
is the environment matrix; the deployment procedure lives in
[DEPLOYMENT.md](DEPLOYMENT.md).

| | test | staging | prod |
| --- | --- | --- | --- |
| Manifest | `deploy/test/docker-compose.yml` | `deploy/staging/docker-compose.yml` | `deploy/prod/docker-compose.yml` |
| Bot image | `ghcr.io/...:main` | `ghcr.io/...:main` | `ghcr.io/...` tag pinned via `KINGDOMS_BOT_IMAGE` |
| Image pull policy | `missing` | `always` | `always` |
| Host | VPS (runner) | VPS (runner) | VPS (runner) |
| Secrets | GitHub environment secrets (injected by the runner) | GitHub environment secrets | GitHub environment secrets |
| MongoDB exposed ports | 27017 | — | — |
| Redis exposed ports | 6379 | — | — |
| Redis persistence | volume | volume | volume + AOF |
| Bot memory limit | — | — | 512M |
| Deploy trigger | Deploy test: auto (merge to main) or manual | Deploy staging: manual (workflow_dispatch) | Deploy prod: on tags (pinned image) |
| Pre-deploy backup | mandatory | mandatory | mandatory |
| Env template | — (secrets live in GitHub environment `test`) | — (GitHub environment `staging`) | — (GitHub environment `prod`) |
| Bot healthcheck | `/healthz` (compose + image) | `/healthz` (compose + image) | `/healthz` (compose + image) |

## Configuration variables

Secrets are **never stored on the VPS**. They live in GitHub
*environment secrets* (Settings → Environments → `test` / `staging` /
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
| `KINGDOMS_BOT_IMAGE` | **Prod only**: full bot image reference, e.g. `ghcr.io/merlin-pinpin/kingdoms-services:v0.1.0` |

The compose manifests override `MONGO_URI` and `REDIS_URI` so the bot always
targets the in-stack services.
