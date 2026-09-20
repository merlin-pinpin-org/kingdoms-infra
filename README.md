# kingdoms-infra

Infrastructure as code for the Kingdoms Discord bot platform: Docker
images, Docker Compose environments, CI/CD workflows, GitOps manifests and
deployment scripts.

## Related repositories

- [kingdoms](https://github.com/merlin-pinpin/kingdoms) — source of truth:
  architecture, ADRs, roadmap, mods documentation
- [kingdoms-services](https://github.com/merlin-pinpin/kingdoms-services) —
  all Python code (generic core, Discord platform, mods, YAML configs)

## Layout

| Path | Content |
| ---- | ------- |
| `deploy/` | Docker Compose manifests per environment (`dev`, `staging`, `prod`) |
| `.github/workflows/` | CI/CD pipelines (lint, test, build, deploy, infra checks) |
| `scripts/` | Deployment and database backup/restore scripts |
| `docs/` | Deployment, environments and GitOps guides |

## Local development

Prerequisites: Docker and Docker Compose.

```bash
cp deploy/dev/.env.example deploy/dev/.env
docker compose -f deploy/dev/docker-compose.yml up -d
```

This starts the bot (serving `/healthz`), MongoDB and Redis. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
for the full deployment guide and [docs/ENVIRONMENTS.md](docs/ENVIRONMENTS.md)
for the environment matrix.

## Deployment overview

Deployment is GitOps-driven: environments are defined by the versioned
manifests in `deploy/`, and changes are applied by CI/CD — never by hand on
the VPS. See [docs/GITOPS.md](docs/GITOPS.md).

## Contributing

See [AGENTS.md](AGENTS.md) for the working rules (English only, no secrets in
the repo, idempotent scripts with rollback). Every infrastructure change must
be reflected in the `kingdoms` documentation before merge.
