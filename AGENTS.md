# AGENTS.md

## Project

`kingdoms-infra` — Docker, CI/CD, GitOps manifests and deployment scripts
for the Kingdoms Discord bot platform.

## Repositories

- `kingdoms` (documentation, source of truth): architecture, workflows, ADRs,
  mods documentation, `ROADMAP.md`, `docs/DEPENDENCIES.md`
- `kingdoms-services`: core, Discord platform, mods, YAML configs
- `kingdoms-infra` (this repo): Docker, CI/CD, GitOps manifests, deployment
  scripts

## Rules for AI agents

- **Read first:** [kingdoms/docs/VIBEWORKFLOW.md](https://github.com/merlin-pinpin/kingdoms/blob/main/docs/VIBEWORKFLOW.md)
  describes the operating model (roles, session loop, approvals).
- All code, comments, documentation, commit messages, PR titles and PR
  descriptions are written in **English**.
- Merges to `main`, tags and releases are gated by the repository rulesets
  and required checks (enforced by GitHub, not by this document).
- Never commit secrets: credentials live only in GitHub **environment
  secrets** (injected by the CD runner at deploy time); nothing secret is
  stored on the VPS or in the repository.
- Deployment is **GitOps-driven**: changes to `deploy/` are applied by
  CI/CD, never by hand on the VPS.
- Deployment scripts must be **idempotent** and support rollback
  (`scripts/deploy.sh`, database restore via `scripts/restore_db.sh`).
- Any infrastructure change must be reflected in `kingdoms` documentation
  (source of truth) before merge.
- Verify all shell scripts with `bash -n` and shellcheck (if available)
  before pushing.
- **A required status check never uses a `paths:` filter**: it must report
  on every PR, or GitHub blocks the merge of the PRs it silently skipped
  (fixed for `check-infra.yml`; applies to every workflow backing a
  required check).
- **Sandbox limits are covered by GitHub Actions**: anything that cannot run
  in the dev sandbox (Docker Compose boot, `compose config`, stack
  healthchecks, backup/restore round-trips, entrypoint runs) must be
  exercised by a CI workflow instead. When a check cannot run locally, add
  or extend the workflow that validates it — never leave it unverified.
- Keep the documentation in `kingdoms` in sync: a change without its doc
  update is incomplete. Reference issues fully qualified
  (e.g. `kingdoms-infra#2`) since cross-repo references are common.
- Link PRs to their issue with a closing keyword in the description
  (`Closes #N`).
- **PR draft status is the merge-readiness signal** (see
  `kingdoms/docs/VIBEWORKFLOW.md`): always open PRs as drafts; mark a PR
  ready for review only when, from your point of view, it can be merged
  (checks green, implementation complete, self-review done, docs updated);
  keep or return it to draft (`gh pr ready --undo`) while work remains.
- **Issue templates are mandatory**: blank issues are disabled on this
  repository. Create every issue from the template matching its kind
  (`gh issue create --template Feature|Bug|Sub-task|Task|Documentation`) and
  keep the required sections (`## Objective`, `## Context`,
  `## Specifications`, `## Acceptance criteria`, `## Dependencies`). The
  "Validate issue" workflow flags non-compliant issues `invalid` —
  recreate them properly rather than editing around the flag.
- **Anyone can run the local checks** (`bash -n`, shellcheck on scripts,
  `docker compose config`): they require public clones only, no
  credentials.
- Authorized contributors (per the GitHub environment protection rules)
  can deploy to the **test** environment; higher environments are gated by
  their own deployment triggers.

## Session checklist (do this by default)

At the end of every session:

1. **Docs vs code**: update the docs in `kingdoms` that describe what you
   changed (architecture, ADRs, infra docs).
2. **Issues**: make sure the issues you touched reflect reality — acceptance
   criteria, state, and the `## Dependencies` checkboxes.
3. **Labels**: every issue you open must carry exactly one `size/*`
   (XS/S/M/L/XL), one `priority/P0-P3` and a `phase-N` label, plus a
   `## Dependencies` section (see
   [kingdoms/docs/SKILLS/update-dependencies.md](https://github.com/merlin-pinpin/kingdoms/blob/main/docs/SKILLS/update-dependencies.md)).
4. **Dependency graph**: `kingdoms/docs/DEPENDENCIES.md` regenerates from
   issue `## Dependencies` sections via
   `kingdoms/scripts/sync_dependencies.py`; verify after issue edits that
   the graph matches intent.

## Roadmap and dependencies

`ROADMAP.md` and `docs/DEPENDENCIES.md` live in the `kingdoms` repo and are
synced by the skills
[Update roadmap](https://github.com/merlin-pinpin/kingdoms/blob/main/docs/SKILLS/update-roadmap.md)
and
[Update dependencies](https://github.com/merlin-pinpin/kingdoms/blob/main/docs/SKILLS/update-dependencies.md):
the sync scripts (`scripts/sync_roadmap.py`,
`scripts/sync_dependencies.py`) run locally against the GitHub issues and
the regenerated files are committed to a `kingdoms` PR branch. Do not edit
these files manually — change the issue state or its `## Dependencies`
section instead. Priorities (`priority/P0-P3` labels) come from
critical-path analysis maintained by that script — do not set them by hand
unless the analysis is wrong.

## See also

- [kingdoms/AGENTS.md](https://github.com/merlin-pinpin/kingdoms/blob/main/AGENTS.md)
- [kingdoms/docs/ARCHITECTURE.md](https://github.com/merlin-pinpin/kingdoms/blob/main/docs/ARCHITECTURE.md)
- [kingdoms/ROADMAP.md](https://github.com/merlin-pinpin/kingdoms/blob/main/ROADMAP.md)
- [kingdoms/docs/DEPENDENCIES.md](https://github.com/merlin-pinpin/kingdoms/blob/main/docs/DEPENDENCIES.md) — dependency graph, critical path, priorities
