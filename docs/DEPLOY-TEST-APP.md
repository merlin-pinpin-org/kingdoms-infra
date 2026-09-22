# Deploy test GitHub App setup (one-time)

`/deploy-test` (a PR comment on `kingdoms-services`) must trigger the
**Deploy test** workflow of this repository. GitHub Actions cannot listen to
another repository's events, so the trigger crosses repositories; it does so
with a **GitHub App** instead of a permanent personal access token:

- the app is installed on **`merlin-pinpin-org/kingdoms-infra` only**;
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
| Homepage URL | `https://github.com/merlin-pinpin-org/kingdoms` |
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

Install the app (`kingdoms-deployer`) on `merlin-pinpin-org/kingdoms-infra`
only — leave every other repository unchecked, especially
`kingdoms-services` and `kingdoms`.

## 3. Store its credentials on kingdoms-services

On `merlin-pinpin-org/kingdoms-services` (Settings → Secrets and variables →
Actions → New repository secret), add:

| Secret | Value |
| --- | --- |
| `KINGDOMS_DEPLOYER_APP_ID` | The App ID shown on the app's page |
| `KINGDOMS_DEPLOYER_APP_PRIVATE_KEY` | The `.pem` private key (download it when generated; the full file content, including the BEGIN/END lines) |

The `Deploy test (PR comment)` workflow reads these two secrets; nothing
else uses them. Once the app is installed and the secrets set, `/deploy-test`
comments on PRs of `kingdoms-services` dispatch this repository's
**Deploy test** workflow and deploy the PR image to the test VPS.

## 4. Restrict who may trigger Deploy test (recommended)

GitHub [workflow execution protections](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/actions-policies/workflow-execution-protections)
are built on the rulesets framework: they define, **before a run starts**,
which actors may trigger which workflows. This step is **defense-in-depth**:
the app already cannot do anything but dispatch `deploy-test.yml` (single
permission, single repository, and the prod workflow is not dispatchable).
Without a policy, anyone with write access can still trigger the workflow
manually from the Actions tab.

> **Prerequisite unblocked (2026-09):** third-party GitHub Apps can only be
> added to actor allow lists **when the repository belongs to an
> organization**. The repositories moved from the personal account
> `merlin-pinpin` to the `merlin-pinpin-org` organization, and the app has
> since recorded activity here (it dispatched the Deploy test run), so the
> actor picker now lists `kingdoms-deployer[bot]`. On the personal-account
> repository the picker did not list the app and this policy was deferred
> — this note records why.

To add the policy, on `merlin-pinpin-org/kingdoms-infra` (Settings →
Actions → Policies → New policy):

- **Name**: `deploy-test-dispatch`;
- **Target**: the workflow `.github/workflows/deploy-test.yml`;
- **Actor rule** (allow list): **`kingdoms-deployer[bot]`** only — add the
  human administrators too if they want a manual fallback (otherwise
  nobody can dispatch the workflow by hand);
- **Event rule** (allow list): `workflow_dispatch` and `push` — `push`
  keeps the test-config-change deploys on `main` working.

Result: only the app can dispatch **Deploy test** on demand; the
test-config-change deploys (push on `main`) keep working; no other human
or bot can trigger the workflow directly.

Order matters: enable this policy only **after** a first successful
`/deploy-test` (so the app has recorded activity and appears in the
picker), then run a second `/deploy-test` to verify the flow still passes —
the app is the actor of the dispatch, so an actor allow list without the
app would break `/deploy-test` entirely.

## 5. Grant kingdoms-infra access to the bot image package

The bot image package `ghcr.io/merlin-pinpin-org/kingdoms-services` is
owned by the **kingdoms-services** repository (its Docker workflow
publishes it). It is not public, and after the organization transfer a
package's access no longer extends to the other repositories: the
Deploy test job pulling it from the test VPS fails with
`error from registry: unauthorized`.

Two halves, both required:

- **Package side (GitHub UI, org owner):** on
  [the package settings](https://github.com/orgs/merlin-pinpin-org/packages/container/package/kingdoms-services/settings),
  **Manage Actions access** → *Add repository* → `kingdoms-infra` → role
  **Read** (pull only; the repo never pushes to this package). Do the
  same for the `kingdoms` repo only if a workflow there ever needs to
  pull the image.
- **Workflow side (in this repository):** `deploy-test.yml` (and
  `deploy-prod.yml`) log in to ghcr.io with the job's `GITHUB_TOKEN`
  (`permissions: packages: read`) before running `scripts/deploy.sh`,
  so the pull from the VPS is authenticated as this repository.

Without the package-side grant the token is not enough: GHCR checks
repository access on the package. Without the login step the pull is
anonymous and fails closed.

## Verify

1. Comment `/deploy-test` on any PR of `kingdoms-services`.
2. The PR gets a 🚀 comment, then a ✅ one.
3. A **Deploy test** run appears in this repository's Actions
   (triggered by `kingdoms-deployer[bot]`), runs on the self-hosted
   runner, and the bot on the test VPS restarts with the PR image.
