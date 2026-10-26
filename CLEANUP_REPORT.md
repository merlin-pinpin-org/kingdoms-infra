# Runner disk cleanup report

## Disk before
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           763M   30M  734M   4% /run
/dev/sda1        38G   25G   14G  66% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           1.9G   52K  1.9G   1% /tmp
/dev/sda13      989M  151M  772M  17% /boot
/dev/sda15      105M  6.3M   99M   7% /boot/efi
none            1.0M     0  1.0M   0% /run/credentials/serial-getty@ttyS0.service
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-networkd.service

## /opt/kingdoms breakdown (top 40)
6.5G	/opt/kingdoms/runners
6.5G	/opt/kingdoms
2.2G	/opt/kingdoms/runners/test
2.1G	/opt/kingdoms/runners/merlin
2.1G	/opt/kingdoms/runners/drasah
38M	/opt/kingdoms/backups
23M	/opt/kingdoms/backups/drasah
7.6M	/opt/kingdoms/backups/merlin
6.4M	/opt/kingdoms/backups/test

## Runner _diag size before
30M	/opt/kingdoms/runners/drasah/_diag

## Deleting runner _diag logs and _temp files older than 3 days
find: ‘/opt/kingdoms/runners/drasah/_temp’: No such file or directory

## _work dirs (report only, never deleted)
682M	/opt/kingdoms/runners/drasah/_work/_update
38M	/opt/kingdoms/runners/drasah/_work/kingdoms-infra
2.3M	/opt/kingdoms/runners/drasah/_work/_actions
52K	/opt/kingdoms/runners/drasah/_work/_temp
16K	/opt/kingdoms/runners/drasah/_work/_PipelineMapping
12K	/opt/kingdoms/runners/drasah/_work/_update.sh
4.0K	/opt/kingdoms/runners/drasah/_work/_tool

## Docker usage before
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          117       6         13.44GB   11.32GB (84%)
Containers      21        21        90.11kB   0B (0%)
Local Volumes   9         5         1.354GB   827.3MB (61%)
Build Cache     0         0         0B        0B
Total reclaimed space: 0B
Total reclaimed space: 0B
Total:	0B

## Docker usage after prune
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          117       6         13.44GB   11.32GB (84%)
Containers      21        21        90.11kB   0B (0%)
Local Volumes   9         5         1.354GB   827.3MB (61%)
Build Cache     0         0         0B        0B

## Old deploy images (keeping the pinned one)
grep: envs/drasah/state/kingdoms-bot.yml: No such file or directory
pinned image tag: NOT FOUND
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191551-cdce8d2
Error response from daemon: conflict: unable to delete ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191551-cdce8d2 (must be forced) - container 7fbb3f6e11f1 is using its referenced image 77fc1cc1ec05
skip ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191551-cdce8d2 (in use or error)

## Disk after
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           763M   30M  734M   4% /run
/dev/sda1        38G   25G   14G  66% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           1.9G   52K  1.9G   1% /tmp
/dev/sda13      989M  151M  772M  17% /boot
/dev/sda15      105M  6.3M   99M   7% /boot/efi
none            1.0M     0  1.0M   0% /run/credentials/serial-getty@ttyS0.service
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-networkd.service
