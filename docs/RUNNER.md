# Runner cheat-sheet — install & uninstall

Every command, in order, nothing else. One runner per environment,
always in `/opt/kingdoms/runners/<env>/` (replace `<env>` throughout:
`test`, `prod`, `drasah`, …).

Context: `principal` = your admin login on the VPS (sudo),
`kingdoms` = the service user that owns `/opt/kingdoms`.

## Install

```bash
# 0. on GitHub (not on the VPS): open the Runners page and copy the
#    Download command + registration token
#    Settings → Actions → Runners → New self-hosted runner (Linux / x64)

# 1. as kingdoms — download and configure
sudo -iu kingdoms
mkdir -p /opt/kingdoms/runners/<env> && cd /opt/kingdoms/runners/<env>
# paste GitHub's Download command here (versioned tarball + tar -xzf)
./config.sh --url https://github.com/merlin-pinpin-org/kingdoms-infra \
            --token <TOKEN> --labels kingdoms,env-<env>
exit

# 2. as principal — install and start the service
cd /opt/kingdoms/runners/<env>
sudo ./svc.sh install kingdoms
sudo ./svc.sh start
```

Verify: the runner shows **Idle** (green) on the GitHub Runners page,
with labels `self-hosted`, `kingdoms`, `env-<env>`.

## Uninstall

```bash
# 1. as principal — stop and remove the service
cd /opt/kingdoms/runners/<env>
sudo ./svc.sh uninstall

# 2. as kingdoms — deregister the runner from GitHub
#    (use a fresh registration token from the Runners page)
sudo -iu kingdoms
cd /opt/kingdoms/runners/<env>
./config.sh remove --token <TOKEN>
exit

# 3. as principal — optionally remove the directory
sudo rm -rf /opt/kingdoms/runners/<env>
```

## Quick checks

```bash
# service status (as principal, in the runner directory)
cd /opt/kingdoms/runners/<env> && sudo ./svc.sh status
# service logs
sudo journalctl -u actions.runner.kingdoms-...-<env> -e
# registered runners on the repo (from anywhere with gh)
gh api /repos/merlin-pinpin-org/kingdoms-infra/actions/runners --jq '.runners[] | {name, status, labels: [.labels[].name]}'
```

Full narrative guide with security context: [VPS-SETUP.md](VPS-SETUP.md).
