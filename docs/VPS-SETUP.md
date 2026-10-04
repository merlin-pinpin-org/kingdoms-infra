# VPS setup guide

This guide installs the Kingdoms deployment server from scratch: a fresh
VPS instance becomes a fully automated GitOps deployment target. Each
step is a command to run — copy, paste, and move to the next one.

Audience: this page is written for non-developers. No prior Linux
knowledge is assumed; links to official documentation are provided for
every tool.

## What you are building

By the end of this guide the VPS will:

- run one or more **Kingdoms environments** (a full stack per
  environment: bot + MongoDB + Redis), auto-deployed by the pipelines;
- host one **GitHub Actions self-hosted runner per environment** that
  executes that environment's deployment jobs locally on the VPS
  (chosen in ADR-0007 review);
- keep database backups in a persistent directory that survives every
  deployment.

Secrets (the Discord bot token) are **not stored on the VPS at all**:
they live in GitHub *environment secrets* and the runner injects them
into each deployment.

**Environments and runners.** An environment is data: a directory under
`envs/` in `kingdoms-infra` (`test`, `prod`, and one personal
environment per rostered user — `drasah`, `merlin`, …; see
[ENVIRONMENTS.md](ENVIRONMENTS.md)). Each environment is served by
exactly **one runner carrying its `env-<name>` label** — the deploy
workflow routes a job to the right VPS by that label. One runner (one
VPS) per environment; nothing prevents several environments from
living on the same physical VPS (one runner each, `docker compose`
projects isolated per environment directory) or on separate VPS
instances — both are supported by the same setup steps.

## 0. Prerequisites

- A VPS instance (any provider: OVH, Scaleway, Hetzner, DigitalOcean…)
  with at least **2 GB of RAM** and **20 GB of disk**.
- Ubuntu Server **26.04 LTS** as the operating system (the commands below
  assume it; see [Ubuntu Server download](https://ubuntu.com/download/server)).
- The SSH key or root password the provider gave you.

Why Ubuntu 26.04 LTS: it is the current long-term support release
(security updates until 2031), and every tool below documents it first.

## 1. First login and initial hardening

Connect to the server from your terminal (the provider shows the IP
address; on Windows, use the built-in
[PowerShell SSH client](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_overview)).
The default login depends on the provider: it is often `root`, but on
Ubuntu images you usually get a sudo user named after the distribution
(e.g. `ubuntu`) — use whichever you were given:

```bash
ssh ubuntu@YOUR_SERVER_IP
```

Every privileged command in this guide starts with `sudo` and is run
from that first login — it works the same whether your login is `root`
or a sudo user.

Update the system:

```bash
sudo apt update && sudo apt upgrade -y
```

Create a dedicated user for the Kingdoms deployment (never run services
as root — see the
[Ubuntu Server security guide](https://documentation.ubuntu.com/server/how-to/security/introduction/)).
The `kingdoms` user has **no password**: it never logs in over SSH and
cannot run `sudo` — every privileged step of this guide is run from
your admin login instead:

```bash
sudo adduser --disabled-password --gecos "" kingdoms
```

Install the firewall and allow only SSH (the stack does not expose any
public port — Discord is an *outbound* connection):

```bash
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw enable
```

Defence in depth on the test environment: the MongoDB and Redis ports of
`envs/test/docker-compose.yml` are published on **loopback only**
(`127.0.0.1:27017`, `127.0.0.1:6379`) — operator debugging from the VPS
works, but even with the firewall misconfigured the databases are not
reachable from the network. Production does not publish the ports at all.

## 2. Install Docker and Docker Compose

Install Docker from the official repository (the
[official install docs](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
describe the same steps with explanations):

```bash
# Add Docker's official GPG key
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Engine and the Compose plugin
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Allow the `kingdoms` user to run Docker without sudo:

```bash
sudo usermod -aG docker kingdoms
```

Switch to that user to verify both tools — the switch re-reads its group
memberships, so no `newgrp` is needed:

```bash
sudo -iu kingdoms
```

```bash
docker run hello-world
docker compose version
```

Go back to your admin login when a later step needs it:

```bash
exit
```

## 3. Prepare the Kingdoms directory

The `/opt/kingdoms` directory holds the persistent data: the database
**backups** (the critical one: it must never be deleted by a deployment,
which is why it lives outside the runner's work directory) and the
GitHub runner itself (next step). No repository is ever cloned manually
on the VPS — every deployment is performed by the runner, which checks
the repository out in its own work directory.

```bash
sudo mkdir -p /opt/kingdoms/backups
sudo chown -R kingdoms:kingdoms /opt/kingdoms
```

When this VPS will host **several environments**, create one backups
subdirectory per environment now (the deploy scripts write each
environment's backups under `/opt/kingdoms/backups/<env>/`):

```bash
# for each environment this VPS will host (example: test + two personal):
sudo mkdir -p /opt/kingdoms/backups/{test,drasah,merlin}
sudo chown -R kingdoms:kingdoms /opt/kingdoms
```

Every environment needs its `DISCORD_TOKEN` — a one-time manual step,
done **on GitHub, not on the VPS**, repeated per environment (each
environment has its own bot):

1. Open the `kingdoms-infra` repository on GitHub:
   **Settings → Environments → <name>** (create the environment if it
   does not exist yet — `test`, `prod`, and one per rostered user).
2. Click **Add environment secret**, name it exactly `DISCORD_TOKEN` and
   paste that environment's bot token from the
   [Discord developer portal](https://discord.com/developers/applications).
   Add the `BOT_ADMINS` environment **variable** too (comma-separated
   Discord user IDs of that bot's operators).
3. Done — the runner picks it up automatically at the next deployment
   ([GitHub environment secrets docs](https://docs.github.com/en/actions/reference/environments#environment-secrets)).

Nothing secret is ever written to the server.

## 4. Install the GitHub Actions self-hosted runner

Just want the raw command sequence? The condensed install / uninstall
cheat-sheet lives in [RUNNER.md](RUNNER.md).

The runner is the piece that receives deployment jobs from GitHub and
runs them on this server. GitHub gives you the exact install commands;
this guide only prepares the ground so theirs work as-is.

**Preparation (run once, on the VPS):**

- Use the **`kingdoms`** user for everything runner-related. It owns
  `/opt/kingdoms`, it is in the `docker` group (so deployments work
  without sudo), and the runner service will run as that user.
- Switch to it — a user switch resets the current directory:

  ```bash
  sudo -iu kingdoms
  ```

- Then create the runner directory — **one directory per environment,
  always under `/opt/kingdoms/runners/<env>/`** (never a loose
  `actions-runner` at the root) — and move into it; GitHub's commands
  create the runner files wherever you stand:

  ```bash
  # for each environment this VPS hosts (example: the test environment):
  mkdir -p /opt/kingdoms/runners/test && cd /opt/kingdoms/runners/test
  ```

- Stay in that shell as `kingdoms` for the whole download + configure.

**Then follow GitHub's instructions.** Open
**[Settings → Actions → Runners → New self-hosted runner](https://github.com/merlin-pinpin-org/kingdoms-infra/settings/actions/runners/new)**
on the `merlin-pinpin-org/kingdoms-infra` repository, choose **Linux /
x64**, and run the **Download** and **Configure** commands it displays.
Do not copy them here — the page always shows the current runner
version.

The full sequence, exactly as it runs on the VPS — **one runner per
environment, each in its own `/opt/kingdoms/runners/<env>/` directory**
(example: the test environment):

**1. Configure — as the `kingdoms` user, inside the runner directory.**
GitHub's registration token is displayed on the same Runners page
(the `--token` value):

```bash
sudo -iu kingdoms
cd /opt/kingdoms/runners
curl -o actions-runner-linux-x64-<VERSION>.tar.gz -L \
     https://github.com/actions/runner/releases/download/v<VERSION>/actions-runner-linux-x64-<VERSION>.tar.gz
# <VERSION> = whatever GitHub's Runners page currently shows (e.g. 2.337.0)
mkdir -p test && cd test
tar xzf ../actions-runner-linux-x64-<VERSION>.tar.gz
./config.sh --url https://github.com/merlin-pinpin-org/kingdoms-infra --token <TOKEN> --labels kingdoms,env-test
```

**2. Install and start the service — as your admin login (`principal`).**
The `kingdoms` user cannot run sudo; go back to your admin login, then:

```bash
exit                                   # back to the admin login
cd /opt/kingdoms/runners/test
sudo ./svc.sh install kingdoms
sudo ./svc.sh start
```

The tarball is downloaded **once** to
`/opt/kingdoms/runners/actions-runner-linux-x64-<VERSION>.tar.gz`, next
to the environment directories, and shared: each new environment just
extracts it into its own directory. The `svc.sh` service names differ
per runner (`svc.sh install` derives the service name from the runner
directory), so several runner services coexist cleanly on one VPS.

Verify: the runner must appear **Idle** (green) on the GitHub
Runners page, with the `self-hosted`, `kingdoms` and its `env-<name>`
labels. The labels tell the deploy workflows which runner may run
which job:

- `kingdoms` — member of the Kingdoms fleet,
- `env-<name>` — this runner hosts the `<name>` environment. One
  runner per environment, period: the test VPS uses `env-test`, the
  prod VPS `env-prod`, a personal environment's VPS `env-drasah`,
  `env-merlin`, and so on.

**Several environments on the same VPS:** repeat the whole sequence
once per environment, each in its own `/opt/kingdoms/runners/<env>/`
directory with its own `env-<name>` label (example: `runners/drasah`
with `--labels kingdoms,env-drasah`). The tarball does not need
re-downloading — reuse the one already in `/opt/kingdoms/runners/`.

**Uninstall a runner** — the reverse sequence: stop and remove the
service **as your admin login**, then deregister the runner **as
`kingdoms`** (a fresh `--token` from the Runners page works for the
removal too):

```bash
# 1. admin login:
cd /opt/kingdoms/runners/<env>
sudo ./svc.sh uninstall
# 2. kingdoms user:
sudo -iu kingdoms
cd /opt/kingdoms/runners/<env>
./config.sh remove --token <TOKEN>
# 3. optionally remove the now-empty runner directory:
exit
sudo rm -rf /opt/kingdoms/runners/<env>
```

Security note (important): this runner executes the deployment jobs of a
**private-to-you** repository. Only repository administrators can add
runners; keep the repository private or restrict write access — anyone
with write access to `kingdoms-infra` could run code on this server
([GitHub guidance](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)).

## 5. Create the GitHub deployment environments

GitHub "environments" gate deployments (protected environments can
require manual approval). Open **Settings → Environments** on the
`kingdoms-infra` repository and create (one GitHub environment per environment directory under
`envs/`):

- `test` — no protection (deploys on config change and `/deploy`),
- `prod` — **required reviewers** only (the Deploy environment run waits
  for their approval before any prod job consumes prod secrets)
  ([docs](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)),
- one per rostered user (`drasah`, `merlin`, …) — the personal
  environments: no required reviewers (the user's sandbox), branch
  policy on `deploy/<alias>`; they deploy automatically via the
  autopin (see [ENVIRONMENTS.md](ENVIRONMENTS.md)).

These names must match the `environment:` value of the reusable deploy
workflow (`deploy-env.yml`), one per environment directory under `envs/`.
Note that step 3 already had you create the `test` environment with its
`DISCORD_TOKEN` secret — creating an environment with one secret is a
single operation in that screen.

One optional step remains to enable on-demand deployments of a pull
request (`/deploy` comment on a `kingdoms-services` PR): creating the
**kingdoms-deployer GitHub App** and its workflow execution ruleset — see
[DEPLOY-TEST-APP.md](DEPLOY-TEST-APP.md). Without it, the test stack still
deploys on every test-config change on `main`.

## 6. First deployment

Everything is in place. Trigger the first deployment from GitHub:

1. Open the **Actions** tab of `kingdoms-infra`.
2. Select the **Deploy environment** workflow, click **Run workflow**,
   and pass the environment to deploy (`test` — or any environment
   this VPS hosts).
3. Watch the job: it checks out the repository on the VPS, runs
   `scripts/deploy.sh <env>` (backup → apply → wait for the health
   gate → rollback on failure). The backup step is skipped on the very
   first deployment (an empty VPS has no stack to back up yet); every
   later deployment backs up first, unconditionally.

Verify on the VPS that the environment's services are healthy:

```bash
docker ps --filter name=kingdoms
```

The environment's `kingdoms-bot`, `kingdoms-mongo` and `kingdoms-redis`
must all show `(healthy)`. The stack auto-updates on every deployment
of its environment (test: merges to `main`; personal envs: pushes to
their `vibe/<alias>/main` integration branch, via the autopin).

## 7. Daily operation

| Task | How |
| ---- | --- |
| Deploy a change | test: merge a PR to `main`; a personal env: push to its `vibe/<alias>/main` — the stack updates automatically |
| Watch a deployment | Actions tab → **Deploy environment** workflow runs |
| Check the bot | `docker ps --filter name=kingdoms` (above) must show `(healthy)` |
| Read the bot logs | `docker logs -f kingdoms-bot` (one set per environment) |
| Diagnose an environment | `make diagnose-env-<env>` or `make doctor` from a clone — FLAG lines report every link of the chain |
| Roll back | automatic on a failed health gate — the pin revert re-applies the previous image (test: direct push; prod: revert PR, the ruleset requires review) |
| Restore data | handled by the pipeline's backup/restore scripts (see [DEPLOYMENT.md](DEPLOYMENT.md)) |
| Backups | `/opt/kingdoms/backups` — one per deployment, produced automatically |

## 8. Troubleshooting

- **A deploy stays pending and nothing notifies**: run
  `make doctor` (or `make diagnose-deploy-<env>`) from a clone **before
  checking the runner** — in the 2026-09-24 prod incident the runner was
  healthy and idle the whole time; a run left `waiting` on an older
  workflow version held the `deploy-prod` concurrency group
  (details: [DEVELOPER.md](DEVELOPER.md)).
- **The deploy job stays queued**: the runner is offline — check it with
  `sudo ./svc.sh status` in the runner's directory
  (`/opt/kingdoms/runners/<env>`),
  restart with `sudo ./svc.sh start`.
- **The runner never goes Idle / the service fails to start**: the most
  common cause is a wrong file owner — the download and `config.sh`
  steps must be run **as the `kingdoms` user** (`sudo -iu kingdoms`),
  because the service runs as that user. If the runner directory was
  created by another user, fix it with
  `sudo chown -R kingdoms:kingdoms <runner-directory>`, then
  `sudo ./svc.sh start` again. Also check
  `sudo journalctl -u actions.runner.kingdoms-... -e` for the service
  error. The journal unit name is derived from the runner directory
  (`/opt/kingdoms/runners/<env>` → one unit per environment).
- **`deploy.sh` says `DISCORD_TOKEN is not set`**: the GitHub
  environment of the deployed env has no `DISCORD_TOKEN` secret
  (step 3) — add it and re-run the **Deploy environment** workflow for
  that env.
- **The health gate fails and rolls back**: inspect
  `docker logs kingdoms-bot`; the most common causes are an
  invalid `DISCORD_TOKEN` or a GitHub package rate limit on image pull.
- **Permission denied from Docker**: you skipped
  `sudo usermod -aG docker kingdoms`, or the shell was opened before
  that command was run — switch to the user again with
  `sudo -iu kingdoms` so the group membership is re-read.

## 9. What comes next

- `prod` on its own VPS: redo this guide there with the `env-prod`
  label and add the `DISCORD_TOKEN` secret in the matching GitHub
  environment (same as step 3). The prod deployment is not implemented
  yet — see the **Deploy prod** workflow log for the list of variables
  to create first.
- A personal environment on this VPS: create its runner
  (`env-<alias>` label, step 4) and its GitHub environment with its
  secrets (step 3/5) — the autopin deploys it on every push to that
  user's `vibe/<alias>/main` integration branch, no command needed.
- Production deploys only released tags (`vX.Y.Z`), manually by identified
  production deployers — see the **Deploy prod** workflow
  (`.github/workflows/deploy.yml`) and
  [DEPLOYMENT.md](DEPLOYMENT.md).
- Monitoring (resource usage, alerts) is tracked in
  [kingdoms-infra#5](https://github.com/merlin-pinpin-org/kingdoms-infra/issues/5).
