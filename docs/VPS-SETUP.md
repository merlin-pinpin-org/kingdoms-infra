# VPS setup guide

This guide installs the Kingdoms deployment server from scratch: a fresh
VPS instance becomes a fully automated GitOps deployment target. Each
step is a command to run — copy, paste, and move to the next one.

Audience: this page is written for non-developers. No prior Linux
knowledge is assumed; links to official documentation are provided for
every tool.

## What you are building

By the end of this guide the VPS will:

- run the Kingdoms stack (bot + MongoDB + Redis) for the `test`
  environment, auto-deployed on every merge to `main`;
- host a **GitHub Actions self-hosted runner** that executes the
  deployment jobs locally on the VPS (chosen in ADR-0007 review);
- keep database backups in a persistent directory that survives every
  deployment.

Secrets (the Discord bot token) are **not stored on the VPS at all**:
they live in GitHub *environment secrets* and the runner injects them
into each deployment. The other environments (`staging`, `prod`) reuse
the same runner — enabling one is just adding its secrets in GitHub.

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

The `test` environment needs its `DISCORD_TOKEN` — a one-time manual
step, done **on GitHub, not on the VPS**:

1. Open the `kingdoms-infra` repository on GitHub:
   **Settings → Environments → test** (create the environment if it does
   not exist yet).
2. Click **Add environment secret**, name it exactly `DISCORD_TOKEN` and
   paste the bot token from the
   [Discord developer portal](https://discord.com/developers/applications).
3. Done — the runner picks it up automatically at the next deployment
   ([GitHub environment secrets docs](https://docs.github.com/en/actions/reference/environments#environment-secrets)).

Nothing secret is ever written to the server.

## 4. Install the GitHub Actions self-hosted runner

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

- Then move to `/opt/kingdoms`; GitHub's commands create the runner
  folder wherever you stand:

  ```bash
  cd /opt/kingdoms
  ```

- Stay in that shell as `kingdoms` for the whole GitHub install.

**Then follow GitHub's instructions.** Open
**[Settings → Actions → Runners → New self-hosted runner](https://github.com/merlin-pinpin/kingdoms-infra/settings/actions/runners/new)**
on the `merlin-pinpin/kingdoms-infra` repository, choose **Linux /
x64**, and run the **Download** and **Configure** commands it displays.
Do not copy them here — the page always shows the current runner
version.

One thing GitHub does not pre-fill: when their Configure step has you
run `./config.sh`, pass the runner labels explicitly:

```bash
./config.sh ... --labels kingdoms,env-test
```

The labels tell the deploy workflows which runner may run which job:

- `kingdoms` — member of the Kingdoms fleet,
- `env-test` — this VPS hosts the `test` environment. One runner (one
  VPS) per environment: a future staging or prod VPS uses
  `env-staging`, `env-prod`, and so on.

When GitHub has you run `./svc.sh` (its **Install the runner as a
systemd service** instructions), run it from your admin login instead —
the `kingdoms` user cannot run sudo. Go back to your admin login:

```bash
exit
```

Then:

```bash
cd /opt/kingdoms/actions-runner
sudo ./svc.sh install kingdoms
sudo ./svc.sh start
```

Verify: the runner must appear **Idle** (green) on the GitHub
Runners page, with the `self-hosted`, `kingdoms` and `env-test` labels.

Security note (important): this runner executes the deployment jobs of a
**private-to-you** repository. Only repository administrators can add
runners; keep the repository private or restrict write access — anyone
with write access to `kingdoms-infra` could run code on this server
([GitHub guidance](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)).

## 5. Create the GitHub deployment environments

GitHub "environments" gate deployments (protected environments can
require manual approval). Open **Settings → Environments** on the
`kingdoms-infra` repository and create:

- `test` — no protection (auto-deployed on merge),
- `staging` — add reviewers when the environment is first used,
- `prod` — **required reviewers** only, protection rules recommended
  ([docs](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)).

These names must match the `environment:` values in the deploy workflows
(`.github/workflows/deploy-<env>.yml`). Note that step 3 already had you
create the `test` environment with its `DISCORD_TOKEN` secret — creating
an environment with one secret is a single operation in that screen.

## 6. First deployment

Everything is in place. Trigger the first deployment from GitHub:

1. Open the **Actions** tab of `kingdoms-infra`.
2. Select the **Deploy test** workflow, click **Run workflow**, run it
   on `main`.
3. Watch the job: it checks out the repository on the VPS, runs
   `scripts/deploy.sh test` (backup → apply → wait for the health
   gate → rollback on failure).

Verify on the VPS that the three services are healthy:

```bash
docker compose ls
docker ps --filter name=kingdoms
```

All three lines (`kingdoms-bot`, `kingdoms-mongo`, `kingdoms-redis`)
must show `(healthy)`. The bot now runs on the VPS and auto-updates on
every merge to `main`.

## 7. Daily operation

| Task | How |
| ---- | --- |
| Deploy a change | Merge a PR to `main` — the `test` stack updates automatically |
| Watch a deployment | Actions tab → **Deploy test** workflow runs |
| Check the bot | `docker ps --filter name=kingdoms` (above) must show `(healthy)` |
| Read the bot logs | `docker logs -f kingdoms-bot` |
| Roll back | automatic on a failed health gate; to go back further, revert the merge and let the deploy workflow re-apply |
| Restore data | handled by the pipeline's backup/restore scripts (see [DEPLOYMENT.md](DEPLOYMENT.md)) |
| Backups | `/opt/kingdoms/backups` — one per deployment, produced automatically |

## 8. Troubleshooting

- **The deploy job stays queued**: the runner is offline — check it with
  `sudo ./svc.sh status` in `/opt/kingdoms/actions-runner`, restart
  with `sudo ./svc.sh start`.
- **The runner never goes Idle / the service fails to start**: the most
  common cause is a wrong file owner — the download and `config.sh`
  steps must be run **as the `kingdoms` user** (`sudo -iu kingdoms`),
  because the service runs as that user. If the runner directory was
  created by another user, fix it with
  `sudo chown -R kingdoms:kingdoms /opt/kingdoms/actions-runner`, then
  `sudo ./svc.sh start` again. Also check
  `sudo journalctl -u actions.runner.kingdoms-... -e` for the service
  error.
- **`deploy.sh` says `DISCORD_TOKEN is not set`**: the GitHub
  environment `test` has no `DISCORD_TOKEN` secret (step 3) — add it and
  re-run the **Deploy test** workflow.
- **The health gate fails and rolls back**: inspect
  `docker logs kingdoms-bot`; the most common causes are an
  invalid `DISCORD_TOKEN` or a GitHub package rate limit on image pull.
- **Permission denied from Docker**: you skipped
  `sudo usermod -aG docker kingdoms`, or the shell was opened before
  that command was run — switch to the user again with
  `sudo -iu kingdoms` so the group membership is re-read.

## 9. What comes next

- `staging` and `prod`: add their `DISCORD_TOKEN` secret in the matching
  GitHub environment (same as step 3); the runner already covers them.
- Production pins the bot image to a released tag (`vX.Y.Z`) at deploy
  time — see the **Deploy prod** workflow
  (`.github/workflows/deploy-prod.yml`) and
  [DEPLOYMENT.md](DEPLOYMENT.md).
- Monitoring (resource usage, alerts) is tracked in
  [kingdoms-infra#5](https://github.com/merlin-pinpin/kingdoms-infra/issues/5).
