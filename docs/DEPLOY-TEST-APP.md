# Deploy test GitHub App setup (one-time)

`/deploy-test` (a PR comment on `kingdoms-services`) must trigger the
**Deploy test** workflow of this repository. GitHub Actions cannot listen to
another repository's events, so the trigger crosses repositories; it does so
with a **GitHub App** instead of a permanent personal access token:

- the app is installed on **`merlin-pinpin/kingdoms-infra` only**;
- it holds a single permission: **Actions: write** — it cannot read code,
  comment, or push anything;
- the workflow in `kingdoms-services` mints an **ephemeral token** from it
  (valid for at most one hour, `actions/create-github-app-token@v3`), so no
  permanent credential ever leaves GitHub;
- `deploy-prod.yml` exposes no `workflow_dispatch` trigger, so the app is
  structurally unable to touch production;
- workflow execution rulesets (see below) restrict who may dispatch
  `deploy-test.yml`, so the app is the *only* actor that may trigger it
  on demand.

## 1. Create the app

As the developer (Settings → Developer settings → [New GitHub App](https://github.com/settings/apps/new)):

| Field | Value |
| --- | --- |
| GitHub App name | `kingdoms-deployer` |
| Homepage URL | `https://github.com/merlin-pinpin/kingdoms` |
| **Repository permissions** | **Actions: Read and write** — and nothing else |
| Where can this app be installed | **Only on this account** |

No webhook, no user permissions, no other repository permission.

On the app page, scroll down to the **Private keys** section and click
**Generate a private key**: a `.pem` file downloads immediately. GitHub
keeps only the public half — the private key **cannot be downloaded again**;
if you lose it, generate a new one (and update the secret below). Do not
confuse it with the *client secret*, which serves the OAuth user flow and
is not used here.

## 2. Install it on kingdoms-infra only

Install the app (`kingdoms-deployer`) on `merlin-pinpin/kingdoms-infra`
only — leave every other repository unchecked, especially
`kingdoms-services` and `kingdoms`.

## 3. Store its credentials on kingdoms-services

On `merlin-pinpin/kingdoms-services` (Settings → Secrets and variables →
Actions → New repository secret), add:

| Secret | Value |
| --- | --- |
| `KINGDOMS_DEPLOYER_APP_ID` | The App ID shown on the app's page |
| `KINGDOMS_DEPLOYER_APP_PRIVATE_KEY` | The `.pem` private key (download it when generated; the full file content, including the BEGIN/END lines) |

The `Deploy test (PR comment)` workflow reads these two secrets; nothing
else uses them. Once the app is installed and the secrets set, `/deploy-test`
comments on PRs of `kingdoms-services` dispatch this repository's
**Deploy test** workflow and deploy the PR image to the test VPS.

## 4. Restrict who may trigger Deploy test (optional, deferred)

GitHub [workflow execution protections](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/actions-policies/workflow-execution-protections)
are built on the rulesets framework: they define, **before a run starts**,
which actors may trigger which workflows. This step is **defense-in-depth
and optional**: the app already cannot do anything but dispatch
`deploy-test.yml` (single permission, single repository, and the prod
workflow is not dispatchable). Without a policy, repository admins can
still trigger the workflow manually from the Actions tab — acceptable
for the test environment.

To add it, on `merlin-pinpin/kingdoms-infra` (Settings → Actions →
Policies → New policy):

- **Target**: the workflow `.github/workflows/deploy-test.yml`;
- **Actor rule**: allow **`kingdoms-deployer[bot]`** (the app) — and the
  repository admins if they want a manual fallback;
- **Event rule**: allow `workflow_dispatch` and `push`.

Result: only the app can dispatch **Deploy test** on demand; the
test-config-change deploys (push on `main`) keep working; no human and no
other bot can trigger the workflow directly.

> **Known limitation (checked 2026-09): the custom GitHub App does not
> appear in the actor picker.** Even after the app has successfully
> triggered runs on this repository, `kingdoms-deployer[bot]` is not
> listed by the Actions policy "allowed actors" picker. The documented
> rule from the older rulesets picker applies the same way here: third
> party GitHub Apps can only be added to actor/bypass lists **when the
> repository belongs to an organization** — and `merlin-pinpin` is a
> personal account. Actor rules therefore work for users, repository
> roles, and GitHub-owned identities (`dependabot[bot]`, Copilot), but
> not for a user-created app on a personal-account repository.
>
> Consequence: **this policy is deferred.** Do not enable an actor rule
> on `deploy-test.yml` for now — allowing only humans would block the
> `/deploy-test` flow itself. The security properties hold without it:
> the app has a single permission (Actions: read and write) on a single
> repository (`kingdoms-infra`), the prod workflow is not dispatchable,
> and the deploy step requires the `test` environment secrets.
>
> Revisit if: the repositories move to a GitHub organization (the
> picker should then list the app), or GitHub ships UI support for
> third-party app actors on personal repositories.

## Verify

1. Comment `/deploy-test` on any PR of `kingdoms-services`.
2. The PR gets a 🚀 comment, then a ✅ one.
3. A **Deploy test** run appears in this repository's Actions
   (triggered by `kingdoms-deployer[bot]`), runs on the self-hosted
   runner, and the bot on the test VPS restarts with the PR image.
