# Environments

The Kingdoms platform runs the same stack in three environments. This page
is the environment matrix; the deployment procedure lives in
[DEPLOYMENT.md](DEPLOYMENT.md).

| | dev | staging | prod |
| --- | --- | --- | --- |
| Manifest | `deploy/dev/docker-compose.yml` | `deploy/staging/docker-compose.yml` | `deploy/prod/docker-compose.yml` |
| Host | developer machine | VPS | VPS |
| Secrets | local `.env` (not committed) | host `.env` (not committed) | host `.env` / GitHub secrets |
| MongoDB exposed ports | 27017 | — | — |
| Redis exposed ports | 6379 | — | — |
| Redis persistence | volume | volume | volume + AOF |
| Bot memory limit | — | — | 512M |
| Deploy trigger | manual (`scripts/deploy.sh`) | CD pipeline | CD pipeline (tag) |

## Configuration variables

All environments read their secrets from a `.env` file next to the compose
manifest (see `deploy/dev/.env.example`):

| Variable | Description |
| -------- | ----------- |
| `DISCORD_TOKEN` | Discord bot token (required) |
| `MONGO_URI` | MongoDB connection string (overridden by compose inside the stack) |
| `MONGO_DB` | MongoDB database name |
| `REDIS_URI` | Redis connection string (overridden by compose inside the stack) |
| `LOG_LEVEL` | Python logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`) |

The compose manifests override `MONGO_URI` and `REDIS_URI` so the bot always
targets the in-stack services; the `.env` values apply for out-of-stack use.
