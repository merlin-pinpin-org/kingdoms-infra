# kingdoms-infra

Infrastructure as code for the Kingdoms Discord bot platform: Docker
images, Docker Compose environments, CI/CD workflows, GitOps manifests and
deployment scripts.

## Related repositories

- [kingdoms](https://github.com/merlin-pinpin-org/kingdoms) — source of truth:
  architecture, ADRs, roadmap, mods documentation
- [kingdoms-services](https://github.com/merlin-pinpin-org/kingdoms-services) —
  all Python code (generic core, Discord platform, mods, YAML configs)

## Layout

| Path | Content |
| ---- | ------- |
| `deploy/` | Docker Compose manifests per environment (`test`, `staging`, `prod`) |
| `.github/workflows/` | CI/CD pipelines (lint, test, build, deploy, infra checks) |
| `scripts/` | Deployment and database backup/restore scripts |
| `docs/` | Deployment, environments, GitOps and VPS setup guides |

## Local development

Prerequisites: Docker and Docker Compose.

```bash
DISCORD_TOKEN=... docker compose -f envs/test/docker-compose.yml up -d
```

This starts the bot (serving `/healthz`), MongoDB and Redis. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
for the full deployment guide and [docs/ENVIRONMENTS.md](docs/ENVIRONMENTS.md)
for the environment matrix.

## Deployment overview

Deployment is GitOps-driven: environments are defined by the versioned
manifests in `deploy/`, and changes are applied by the CD pipeline
(`.github/workflows/cd.yml`) executed by a **self-hosted runner installed
on the VPS** — never applied by hand. The `test` environment auto-deploys
on every merge to `main`. See [docs/GITOPS.md](docs/GITOPS.md) for the
model and [docs/VPS-SETUP.md](docs/VPS-SETUP.md) for the complete
server installation guide (step by step, no Linux knowledge required).

## Contributing

See [docs/DEVELOPER.md](docs/DEVELOPER.md) for the developer guide
(environment model, checks, deploy chain) and [AGENTS.md](AGENTS.md) for
the agent entry points. Every infrastructure change must be reflected in
the `kingdoms` documentation before merge.
