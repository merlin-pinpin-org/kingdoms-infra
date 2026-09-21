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

Allow the `kingdoms` user to run Docker without sudo, then verify both
tools as that user (switch with `sudo -iu kingdoms` — its group
memberships are re-read on each switch):

```bash
sudo usermod -aG docker kingdoms
sudo -iu kingdoms
newgrp docker
docker run hello-world
docker compose version
```

Type `exit` (or `sudo -iu kingdoms` again) whenever a later step needs
your admin login back.

## 3. Prepare the Kingdoms directory

All repos and backups live under `/opt/kingdoms`. The **backups**
directory is the critical one: it must never be deleted by a deployment,
which is why it lives outside any git checkout.

```bash
sudo mkdir -p /opt/kingdoms/backups
sudo chown -R kingdoms:kingdoms /opt/kingdoms
```

Clone the infrastructure repository (the runner deploys from it; run
this as the `kingdoms` user, in `/opt/kingdoms`):

```bash
sudo -iu kingdoms
cd /opt/kingdoms
git clone https://github.com/merlin-pinpin/kingdoms-infra /opt/kingdoms/kingdoms-infra
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
runs them on this server. Installation is point-and-click on GitHub,
commands on the server.

1. On GitHub, open **Settings → Actions → Runners → New self-hosted
   runner** on the `merlin-pinpin/kingdoms-infra` repository, choose
   **Linux / x64**, and follow the displayed commands. They look like
   this (run them on the VPS, from `/opt/kingdoms`):

   ```bash
   cd /opt/kingdoms
   mkdir actions-runner && cd actions-runner
   curl -o actions-runner-linux-x64-2.xxx.tar.gz -L https://github.com/actions/runner/releases/download/v2.xxx/...
   tar xzf actions-runner-linux-x64-*.tar.gz
   ```

2. **Add the labels**: when configuring, make sure the runner carries
   the `kingdoms` label (it is what `cd.yml` targets):

   ```bash
   ./config.sh --url https://github.com/merlin-pinpin/kingdoms-infra --token <TOKEN_FROM_GITHUB> --labels kingdoms
   ```

3. Install the runner as a **system service** so it starts on boot
   ([docs](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service)):

   ```bash
   sudo ./svc.sh install kingdoms
   sudo ./svc.sh start
   ```

4. Verify: the runner must appear **Idle** (green) on the GitHub
   Runners page, with the `kingdoms` and `self-hosted` labels.

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

These names must match the `environment:` values in
`.github/workflows/cd.yml`. Note that step 3 already had you create the
`test` environment with its `DISCORD_TOKEN` secret — creating an
environment with one secret is a single operation in that screen.

## 6. First deployment

Everything is in place. Trigger the first deployment from GitHub:

1. Open the **Actions** tab of `kingdoms-infra`.
2. Select the **CD** workflow, click **Run workflow**, choose the `test`
   environment, run it.
3. Watch the job: it checks out the repository on the VPS, runs
   `scripts/deploy.sh test` (backup → apply → wait for the health
   gate → rollback on failure).

Verify on the VPS that the three services are healthy:

```bash
docker compose -f /opt/kingdoms/kingdoms-infra/deploy/test/docker-compose.yml ps
```

All three lines (`kingdoms-bot`, `kingdoms-mongo`, `kingdoms-redis`)
must show `(healthy)`. The bot now runs on the VPS and auto-updates on
every merge to `main`.

## 7. Daily operation

| Task | How |
| ---- | --- |
| Deploy a change | Merge a PR to `main` — the `test` stack updates automatically |
| Watch a deployment | Actions tab → **CD** workflow runs |
| Check the bot | `docker compose ... ps` (above) must show `(healthy)` |
| Read the bot logs | `docker compose -f .../deploy/test/docker-compose.yml logs -f kingdoms-bot` |
| Roll back | `./scripts/rollback.sh test` on the VPS, or revert the merge and let CD re-apply |
| Restore data | `./scripts/restore_db.sh test <archive> --yes` (see [DEPLOYMENT.md](DEPLOYMENT.md)) |
| Backups | `/opt/kingdoms/backups` — one per deployment, produced automatically |

## 8. Troubleshooting

- **The CD job stays queued**: the runner is offline — check it with
  `sudo ./svc.sh status` in `/opt/kingdoms/actions-runner`, restart
  with `sudo ./svc.sh start`.
- **`deploy.sh` says `DISCORD_TOKEN is not set`**: the GitHub
  environment `test` has no `DISCORD_TOKEN` secret (step 3) — add it and
  re-run the CD workflow.
- **The health gate fails and rolls back**: inspect
  `docker compose logs kingdoms-bot`; the most common causes are an
  invalid `DISCORD_TOKEN` or a GitHub package rate limit on image pull.
- **Permission denied from Docker**: you skipped
  `sudo usermod -aG docker kingdoms`, or the shell was opened before
  that command was run — switch to the user again with
  `sudo -iu kingdoms` so the group membership is re-read.

## 9. What comes next

- `staging` and `prod`: add their `DISCORD_TOKEN` secret in the matching
  GitHub environment (same as step 3); the runner already covers them.
- Production pins the bot image to a released tag (`vX.Y.Z`) at deploy
  time — see the `deploy-prod` job in `cd.yml` and
  [DEPLOYMENT.md](DEPLOYMENT.md).
- Monitoring (resource usage, alerts) is tracked in
  [kingdoms-infra#5](https://github.com/merlin-pinpin/kingdoms-infra/issues/5).
