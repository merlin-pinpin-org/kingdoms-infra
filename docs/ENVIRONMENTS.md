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
| Secrets | local `.env` (not committed) | host `.env` (not committed) | host `.env` / GitHub secrets |
| MongoDB exposed ports | 27017 | — | — |
| Redis exposed ports | 6379 | — | — |
| Redis persistence | volume | volume | volume + AOF |
| Bot memory limit | — | — | 512M |
| Deploy trigger | CD auto (merge to main) | CD manual (workflow_dispatch) | CD on tags (pinned image) |
| Pre-deploy backup | mandatory | mandatory | mandatory |
| Env template | `deploy/test/.env.example` | `deploy/staging/.env.example` | `deploy/prod/.env.example` |
| Bot healthcheck | `/healthz` (compose + image) | `/healthz` (compose + image) | `/healthz` (compose + image) |

## Configuration variables

All environments read their secrets from a `.env` file next to the compose
manifest (see `deploy/test/.env.example`):

| Variable | Description |
| -------- | ----------- |
| `DISCORD_TOKEN` | Discord bot token (required) |
| `MONGO_URI` | MongoDB connection string (overridden by compose inside the stack) |
| `MONGO_DB` | MongoDB database name |
| `REDIS_URI` | Redis connection string (overridden by compose inside the stack) |
| `LOG_LEVEL` | Python logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`) |
| `KINGDOMS_BOT_IMAGE` | **Prod only**: full bot image reference, e.g. `ghcr.io/merlin-pinpin/kingdoms-services:v0.1.0` |

The compose manifests override `MONGO_URI` and `REDIS_URI` so the bot always
targets the in-stack services; the `.env` values apply for out-of-stack use.
