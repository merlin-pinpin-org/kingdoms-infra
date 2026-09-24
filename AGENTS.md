# AGENTS.md

`kingdoms-infra` — Docker, CI/CD, GitOps manifests and deployment scripts
for the Kingdoms Discord bot platform.

## Read first

- [kingdoms/docs/CONVENTIONS.md](https://github.com/merlin-pinpin-org/kingdoms/blob/main/docs/CONVENTIONS.md)
  — conventions shared by the three repositories (language,
  humans-never-code, secrets, PR lifecycle, issues, checks).
- [kingdoms/docs/VIBEWORKFLOW.md](https://github.com/merlin-pinpin-org/kingdoms/blob/main/docs/VIBEWORKFLOW.md)
  — operating model (roles, session loop, approvals).
- [docs/DEVELOPER.md](docs/DEVELOPER.md) — this repo's layout, environment
  model, checks, deploy chain, workflow pitfalls.

## Repositories

- `kingdoms` (documentation, source of truth)
- `kingdoms-services`: core, Discord platform, mods, YAML configs
- `kingdoms-infra` (this repo): Docker, CI/CD, GitOps, deploy scripts

## Local rules

- Deployment is **GitOps-driven**: state branches are applied by CI/CD,
  never by hand on the VPS; deploy scripts stay idempotent with rollback.
- Ops manage environments and secrets in the GitHub web UI only; the agent
  never handles secret values.
- Verify scripts with `bash -n` and shellcheck (if available) before
  pushing; sandbox-limited checks are covered by CI workflows.
- Any infrastructure change is reflected in the `kingdoms` docs (source
  of truth) before merge.
- Issue templates: `## Objective` / `## Context` / `## Specifications` /
  `## Acceptance criteria` / `## Dependencies` (blank issues disabled).
