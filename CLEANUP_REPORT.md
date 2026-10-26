# Runner disk cleanup report

## Disk before
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           763M   30M  734M   4% /run
/dev/sda1        38G   38G  100M 100% /
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
6.7G	/opt/kingdoms/runners
6.7G	/opt/kingdoms
2.3G	/opt/kingdoms/runners/drasah
2.2G	/opt/kingdoms/runners/test
2.1G	/opt/kingdoms/runners/merlin
38M	/opt/kingdoms/backups
23M	/opt/kingdoms/backups/drasah
7.6M	/opt/kingdoms/backups/merlin
6.4M	/opt/kingdoms/backups/test

## Runner _diag size before
189M	/opt/kingdoms/runners/drasah/_diag

## Deleting runner _diag logs and _temp files older than 3 days
/opt/kingdoms/runners/drasah/_diag/Worker_20261010-112416-utc.log
/opt/kingdoms/runners/drasah/_diag/Worker_20261014-171304-utc.log
/opt/kingdoms/runners/drasah/_diag/Worker_20261008-170119-utc.log
/opt/kingdoms/runners/drasah/_diag/Worker_20261008-213320-utc.log
/opt/kingdoms/runners/drasah/_diag/Worker_20261012-044825-utc.log
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
Images          252       6         25.86GB   22.18GB (85%)
Containers      23        23        106.5kB   0B (0%)
Local Volumes   9         9         1.354GB   0B (0%)
Build Cache     0         0         0B        0B
Deleted Containers:
b0f6983402241cd74aa72361849d2fdb57a0f6a93a504f3b96ff40e4998ffb6b
65c9c97370380b0c4f62cb21a105e7b530acacf85ff1e0ea217e2fab9116ad70

Total reclaimed space: 16.38kB
Deleted Images:
untagged: sha256:46f15cf64fdef63e483dcda99e74e3d51c017b1175547b6bb874152ee2391aad
deleted: sha256:46f15cf64fdef63e483dcda99e74e3d51c017b1175547b6bb874152ee2391aad
deleted: sha256:6510e071eecd994fb187c15f126d424a293006669f590da800ca4a06564ae7d0
deleted: sha256:0f9c6fbe6068dff1b109e29c4c4fcb7c616b80a1de5870aa9d12e0b3fa65fba8

Total reclaimed space: 180.6MB
Total:	0B

## Docker usage after prune
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          251       6         25.67GB   22GB (85%)
Containers      21        21        90.11kB   0B (0%)
Local Volumes   9         5         1.354GB   827.3MB (61%)
Build Cache     0         0         0B        0B

## Old deploy images (keeping the pinned one)
grep: envs/drasah/state/kingdoms-bot.yml: No such file or directory
pinned image tag: NOT FOUND
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191520-cdce8d2
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191520-cdce8d2
Deleted: sha256:6c4e823775ea9c9c483d2267bfe6479c56fd2e06082398378c3eccb4900586e5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191551-cdce8d2
Error response from daemon: conflict: unable to delete ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191551-cdce8d2 (must be forced) - container dd73f3ef5203 is using its referenced image 77fc1cc1ec05
skip ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026191551-cdce8d2 (in use or error)
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026190400-fdc411b
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026190400-fdc411b
Deleted: sha256:6cb421f10a3516c54969c3aac75ed3f602bfec7e68caea1863ac769537f81352
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026190446-fdc411b
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026190446-fdc411b
Deleted: sha256:0c671d4104f22efa8606904fda23a51e260a58e5b095135ea96454906fb87efd
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026184602-25d572d
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026184602-25d572d
Deleted: sha256:c625105a547b34e28d42bf99446a1f8e543b9fe7e4600024a6147253eaa3e573
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026184518-03e013b
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026184518-03e013b
Deleted: sha256:c0b207a01683ee18adbc89688d5d10771514d07c9dd78d5bc8d5c47a039ac468
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026183302-f91d106
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026183302-f91d106
Deleted: sha256:6171f20344fc302cd44fdee371fc0bd61170f88bdba80b83f5536ccbf1d2f72a
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026183147-f91d106
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026183147-f91d106
Deleted: sha256:c2ea651686df65938858ab5629ff910172e664cb21cbbe6d8d4a9ba405d36033
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026171034-978f95e
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026171034-978f95e
Deleted: sha256:f4a2c4f76b2fa8e8faf94c6b33b7f60b9762053432db7283704d17ac0efa080c
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026170336-2292f4c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026170336-2292f4c
Deleted: sha256:404a71b03cc2b0b8a8ed05387785cafcb4ab6cbbef96c10f74a4ff487914b4e2
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026170013-247298f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026170013-247298f
Deleted: sha256:0f6dcf5407e7a98a25b58a23394625ea7247244e9a22fe23a269c1463bc896d2
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026162408-6e446b7
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026162408-6e446b7
Deleted: sha256:277c46b305b4f1b61f2e1d92b6c48eb838e6e94e454379feeaa8eb21372c7f59
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026161318-bad0411
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026161318-bad0411
Deleted: sha256:49c5ed8b7a8fa6d5fbe9e3f86dd1fc02abd1e0ccd04fcfa66144da4ea5d56e58
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026121917-6bee5ed
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026121917-6bee5ed
Deleted: sha256:23ef2dbf7494c8e4e196e23cfc74355a7f8267721d521991a013511f005c9c78
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026113804-7191d4d
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026113804-7191d4d
Deleted: sha256:4ecdc8d071d191bf3c5b2ebb81f2ec41f9c219d3b0ac3b10278696bce2c95e6c
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026112343-de0d79e
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026112343-de0d79e
Deleted: sha256:39bf1477d9f0f93a1016680ef088cbf5235f88896fe4c97c18eee658c3559f12
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026105119-a0be592
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026105119-a0be592
Deleted: sha256:610866aefd0652b5576bf935e07b39475992f13ad3f7a1203b9c42a72a46db33
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026102838-a764afa
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026102838-a764afa
Deleted: sha256:30a3f3cad78c1ecd55c3b59dea226988b4bd76a8a1bd5f1666e2edda6fc7e39f
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026094946-c5728bb
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026094946-c5728bb
Deleted: sha256:97cdf584c16b5ab937d729c919d9fb241cfba463a87e654c8fa01515a23d8854
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026094859-95b7890
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026094859-95b7890
Deleted: sha256:4ffc37886834779ee1df87ed01ec73727f30ac86012f7fcd182241c0693dca0a
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026093038-4edb6a8
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026093038-4edb6a8
Deleted: sha256:7461f6c5df0b3a4aca4856e1cc57126a25978285970aa33f9fc2f077ed17a061
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026092014-312ef49
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026092014-312ef49
Deleted: sha256:354c5e504063b328dd44965a5267cf65201dd6552fc0e8703cebd495e02b50f7
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026091714-b9db33f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026091714-b9db33f
Deleted: sha256:284f149fb23118e59c20bac93df897669d8a301b29b246ed317590388e541ac4
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026082926-a407367
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026082926-a407367
Deleted: sha256:87a5b6010ed83611ab993d3d643b2a4b4e1d622a0cc4e05a0778ac661e3ef1eb
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026080153-4fb5857
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026080153-4fb5857
Deleted: sha256:eed8ead498ce6083f53bcd378f7a33c3212434e862737a6f078e8dd8921961a6
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026073423-8e0a3f7
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026073423-8e0a3f7
Deleted: sha256:d8bf66a65fd9094f3fe0c74e73fcfed1d20a057686b3714ae4af6b6312535534
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026065600-4e3458e
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261026065600-4e3458e
Deleted: sha256:ecaec0d2dee079dbde414204d21c618f2cd4a9734c734db6fbabec0cf707de90
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025234904-b767bb8
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025234904-b767bb8
Deleted: sha256:96941258dbf057e525979aef699c9baf98463542268ce6152bfd879f51cbb82b
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025233625-749e766
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025233625-749e766
Deleted: sha256:864e8f08c65e7560bccc3e563044232856306989a6751685a06bcc7b268b9ca1
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025230625-9e13342
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025230625-9e13342
Deleted: sha256:b6217cc6c9c1050bbe8f37cf942a3a205832a3eedbe5fd14c66f81585d44baa8
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025221040-37d6348
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025221040-37d6348
Deleted: sha256:9daa83b540b6ccc3a5307578d49df77a469f89035a69de54c375e503aa63b3fa
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025220935-c86f1da
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025220935-c86f1da
Deleted: sha256:fe213c18c897029630a927ac7a568a553fee2f4ae53e68c2f5dd077f1806577f
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025213952-7c8fed4
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025213952-7c8fed4
Deleted: sha256:5c2cdb37ec619cee170a63981f7b7de14fedea26974bb125fc6fdfecfd788442
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025203826-cc4cf8b
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025203826-cc4cf8b
Deleted: sha256:f1c94348d0b695c358a015e56ce49b16675e4e734cc9fb2089f2716050be1799
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025200657-bfd719e
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025200657-bfd719e
Deleted: sha256:3bd9ba9b4ac4879cef273c315cc30e107a73e767794819cbf7becdd91c53587e
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025192043-f8f2371
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025192043-f8f2371
Deleted: sha256:408f36dd667df30b82bb2483dee3c4e0c5798e7240ff4972bd32d44b7a6a7c32
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025150403-4e78f8b
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025150403-4e78f8b
Deleted: sha256:d439db9291c8a7fd2d31b8420f527c95ade2e90ac6ff1f93a84a46e6ca8810ea
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025150102-19465af
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025150102-19465af
Deleted: sha256:ee8714953833446ee89a9d1e02d032b765e0142a44901a9779ebcb5a3bad88bf
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025140630-8e11882
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025140630-8e11882
Deleted: sha256:0352f5f6ecdbbd02164ae5e56f3073c044b93a16d19ed2bdd347f8a4722413b3
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025134403-edd7392
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025134403-edd7392
Deleted: sha256:a323a3e6dd5ae55a4426747ea1daf69ccaf48a42a5d4e0d3bfcb28eb170570be
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025134353-049ff4c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025134353-049ff4c
Deleted: sha256:8608ee6bd49f7049033f6273bbde02164aa8e01cb4364353f51428222f5850e5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025115536-32ad42d
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025115536-32ad42d
Deleted: sha256:4f1926db631013587056ab318636efbf953832fba6d0bd1a97b272f0e4c7ea34
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025101634-bfdd91c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025101634-bfdd91c
Deleted: sha256:4946b474f1581a34d7c0811b8cd79b774d9b37b4fb0447ed9ebc5017acab3ef9
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025095618-9de8d5e
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025095618-9de8d5e
Deleted: sha256:782646c8c41e937781c3b8e80d97a9fa0a67a09f010fbfa08bb328fe57967284
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025093643-146f9a4
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261025093643-146f9a4
Deleted: sha256:cca96fe4240c3fcfa45adbc674a3e377f82dbcd4e434781221dda62b7301db96
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024181634-f76ae64
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024181634-f76ae64
Deleted: sha256:273d350423b6738e732cbdece6cb21c5f57e55f56a1738170feee321b3c7cf7e
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024172749-9be7ded
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024172749-9be7ded
Deleted: sha256:1241820c2edd472db7391d04bbedd642e32d99cf8bc9b26abeb2daba67d72bf2
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024171128-840d1a7
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024171128-840d1a7
Deleted: sha256:44d087e3a9fdc2716d0dd58bd80ae7f32cff4ae82b742ec9d51d25a46dd408e9
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024140635-b03b233
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024140635-b03b233
Deleted: sha256:843f7c4ce96943ffcb3f61efbfeaebeb7fc54fe2bb6d127877392ca3a07c33ff
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024135457-f8d55ec
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024135457-f8d55ec
Deleted: sha256:efcd6f02e2911d27abb2f4dfd9060aeae1d9fcc2b9d7313ebac12b71b01e3a94
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024121439-6f6cedb
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024121439-6f6cedb
Deleted: sha256:d0168c4753ee7a60d28ee995ed726a74327579d67cdf4ae346d9bc5bf81953a9
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024120903-b2dba10
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024120903-b2dba10
Deleted: sha256:1221cbc89008d24ba7199e1a74ace495f53b0c13e25452250e8d31bec00bfb59
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024115426-9c7d895
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024115426-9c7d895
Deleted: sha256:b466442d88efb6aa4d52cdd90b6253c45d53e21dec2107fe1b2dd8bbe91d2369
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024112659-e5a7213
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024112659-e5a7213
Deleted: sha256:b1ddaae7a239a8d9f91ace119824320b59cf026801decf7dca2ee3d62f19adea
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024111432-7da729d
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024111432-7da729d
Deleted: sha256:dc41a5996146e6442c1cd2a008168dd71f37aa4c7527a49be4efc4a67e98fba3
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024110457-a724f87
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261024110457-a724f87
Deleted: sha256:e39d5fe36c3240f4beb14cfd6023d1396b38800c24beffb3ecb324c468612ae4
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023180838-c43053f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023180838-c43053f
Deleted: sha256:4c7d9c10507a3341c81163e64a3e13c9ade9cb72fe405e8210707687a372b740
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023175908-c43053f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023175908-c43053f
Deleted: sha256:f7c94378d157fbb4c4efb0fa1c07c99f6f545a8d21fdda19b92e40efaba47d76
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023171818-0859834
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023171818-0859834
Deleted: sha256:0b56e50c361e7ef6c596d56dd24824dcdac62972cc9d8e74f4f6c84b51552150
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023170714-0859834
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261023170714-0859834
Deleted: sha256:c33ba80b5d9416469f860dbce0bc12ee7cd3cf5530816e477494b24d045cd6cd
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022215312-40ac8c3
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022215312-40ac8c3
Deleted: sha256:67e5bc242a48a6a4399bd7f43e4cb5137ec9d7f22f3909e859ce374925c4be5b
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022164729-8b45776
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022164729-8b45776
Deleted: sha256:40cec9af3a1fc9c54b92ae80e8c4285b1d600930f65160d0ea0fe6ff030ad10c
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022153116-5130699
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022153116-5130699
Deleted: sha256:2cd1be0dcf382735378f538ed75cc1206257481a307cb764b8d0a4ad43bcd46c
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022122857-f6d66bb
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022122857-f6d66bb
Deleted: sha256:5157e7bd18d15eac7301c52ec190843605f9ca1b2d5d88c13c28a72cc1f48789
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022104419-ded308f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022104419-ded308f
Deleted: sha256:50c5ea9d4ed716108d69186f2df7cb09cbe8695e120ed75832c75929c314874c
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022093355-b35bf65
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022093355-b35bf65
Deleted: sha256:67113d9f8acf28f912ebcd2f861c4c1ead2fd875e36df998b4fe4a7a9639dbab
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022093121-b35bf65
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261022093121-b35bf65
Deleted: sha256:6e4b632069af8b0e9a57819ae2ff2e8547fda8cf55809c98ffd04316f546f159
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020182303-5240442
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020182303-5240442
Deleted: sha256:dcc2f77b2a60ae488f2ca8430bea8226d8ec1501ad37e328048de969eccbe839
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020143110-5909b1a
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020143110-5909b1a
Deleted: sha256:6051ec9fc382dbe00fd25f798086bd020bb3285b758988479fe7babfd4fe673b
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020040748-f84d5bd
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020040748-f84d5bd
Deleted: sha256:547f14e99901f64c22e5483e46292e2f969cb69467ebe60cb6fe027b64f4a031
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020040407-fadb52e
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020040407-fadb52e
Deleted: sha256:1a5d2bf313a9fbb5ef4e59137d57b289f0bcccee9d0575305f2b38291981d710
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020040351-8123919
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020040351-8123919
Deleted: sha256:2566730bf9df7459870d8c5b8454179ad5125760dcb652ad5ca1d4b8221417b3
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020014610-b0b7cce
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020014610-b0b7cce
Deleted: sha256:eae209c5acd212690c14324712c89d5bf21056ee3b80d3e5404e1c32af66c955
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020020739-b534758
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020020739-b534758
Deleted: sha256:075ba05597aa302ff2a3a984378a8b0b3f05326350c8f8c9efb2717693a5d6ba
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020014423-b0b7cce
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261020014423-b0b7cce
Deleted: sha256:3ae8c5d07f5956ec30053e58e15fd9d77ba912d3c43508329a6fed1c0525e6f2
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019212222-ccba901
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019212222-ccba901
Deleted: sha256:84a417c2e6b5b6e0011f4f9eaf640053b7485943a3c81facd2d440cfde957962
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019212049-ae327e3
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019212049-ae327e3
Deleted: sha256:89fabd7dfeba616104b460d9f11c9d0a6cce5521f9cfa83d10dc7994a83c737f
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019204829-6d22834
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019204829-6d22834
Deleted: sha256:6faccaa4b30a057c7fb4a3f183335db5ebbdf1147716de1c338d7992bc60ac4f
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019204433-6d22834
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019204433-6d22834
Deleted: sha256:54f808667c8dc7139ffc3e5b28957750de12ac5231b780c6882c6adb2372a6f6
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019204350-82022e4
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019204350-82022e4
Deleted: sha256:6866571d009e82618ee2fdb8588f79c0e8c17170d95c50f2d42fec2135998292
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019184238-f0b7857
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019184238-f0b7857
Deleted: sha256:916c54082a082d38ec455e8b14caa1ba5300d5effec86a6085b807efdcf4e152
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019183649-f0b7857
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019183649-f0b7857
Deleted: sha256:59ee7f406d9be96c807e5775635bae1fa8b3a71a2059928185eb18220a4546bf
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019182139-55222ee
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019182139-55222ee
Deleted: sha256:2b86cac74aba98b7edbbd27a0274606e075ef4274417ec880b91f4b803cf94c5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019182538-1c3cb85
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019182538-1c3cb85
Deleted: sha256:ecd8a357571177a3a1672f32c2784fd2d491d84f5287a191637259c714a659ee
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019182206-ca37cdb
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019182206-ca37cdb
Deleted: sha256:7f5036b2548b5df905e93480dcdc258fbabf1c1d22a02caf6c74be79562f9b41
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175714-bb91134
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175714-bb91134
Deleted: sha256:35ffbfcbca97185b784ac5e7a5a0caf1e88a68490ec7f5f5fca2f780df50a75c
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175244-c74064f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175244-c74064f
Deleted: sha256:ae9427994866da9ca125c21d5c15fc1f9bb9e036e5839d4d40b1ebeeac60deb1
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175706-bb91134
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175706-bb91134
Deleted: sha256:e97eea0481fd0f9b3c36d98ab3b4820e268dc0552c3a26749124e98787d2b543
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175046-e0559a2
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019175046-e0559a2
Deleted: sha256:df5abe9f2b9a85a7929b0c5beef46349e0f8d37be6fb4c79dacbb38b5af6b9d6
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019174922-d6fc310
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019174922-d6fc310
Deleted: sha256:ae356031e4fc59869830c9a137555aece7494a726fe86329b3f996295a8f8820
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019162711-1217d53
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019162711-1217d53
Deleted: sha256:ca2fc67b3f8ca2be68fdea7ea59d2709037efade9742691f2bf7bd69e77e3df4
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019164810-cd1ee8d
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019164810-cd1ee8d
Deleted: sha256:56bedd9376e98c9e2a71f1f3719be3c721a9970f063a60cfc721a9057e8c7451
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019173808-01b47ee
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019173808-01b47ee
Deleted: sha256:445aeb46c78242b784f71c73d204303f4fbd181d302317ab297d41d6bbdeffc8
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019173944-706b8d9
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019173944-706b8d9
Deleted: sha256:fadcf6d696cd929d3a0b909d300ec374f40e0a05cefc71a16eb0faa57671fda5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019135835-ad6a5d0
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019135835-ad6a5d0
Deleted: sha256:b43ceef1fa0921c3fba09519751c92e28ca8e68906693552637a89fecf0f4952
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019135546-ad6a5d0
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019135546-ad6a5d0
Deleted: sha256:9d795ad6c89335bf38a9536107efd326c2b97e86388401b912bdf1aabc813df4
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019130453-800ba90
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019130453-800ba90
Deleted: sha256:946dfd5533fae385c73b09f5671f50cb02c2ac3f10fce2b2ecc6e4ba7fe0fd98
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019130008-800ba90
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019130008-800ba90
Deleted: sha256:1faa2b117f14113c404e05399303fbec13b7b24d8a78546393d75c648f0c0d0e
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019125643-4746c01
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019125643-4746c01
Deleted: sha256:8fd2032c68487e5d718c76751fc3ea50b7b20470177251dc849946a9265ff77d
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019123059-6b67265
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019123059-6b67265
Deleted: sha256:99c33a8d056da2312bc8a3c25c47fd3699d41780060423e1df63790e699fa9e7
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019122743-595c9d6
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019122743-595c9d6
Deleted: sha256:7633cdc02be9d11dfcb32e7c0becddcc0e7bd3abbb9b7aa843b191f6b5d9bc64
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019121954-5b37724
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019121954-5b37724
Deleted: sha256:c319305fd296ba8726fce5a7531e59f1d0a762b1f33f355f2321e759804d00e1
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019121834-f21e924
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019121834-f21e924
Deleted: sha256:399b2608692464bdd348632705cb68cbe05d4c6743a6b490f6a56b90d2808dc2
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019094234-1c49004
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019094234-1c49004
Deleted: sha256:5cc6d37850eccd4b226c995b075431b892aaf95112baf086250d036914b74204
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019093829-1c49004
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019093829-1c49004
Deleted: sha256:5131756bbed1a40b4a9a53878721bbbaa1dcbdc464d106e2d967a9ec3079fbe8
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019093744-356a9eb
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261019093744-356a9eb
Deleted: sha256:3a37a549d31ac7ae2c5886c96fc52520bc6aab4ec04357e18d0451b7aa589eb6
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018173648-3ca8810
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018173648-3ca8810
Deleted: sha256:f657225e052cb1925c8740d71d7e14a0b5ce1dba2aa4fa7f83f5e001161fb073
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018173323-bd85779
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018173323-bd85779
Deleted: sha256:9ae292f05a49e19581e081f5adaa738459ee35b1d753a3ef1fc0db0907d5082e
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018172923-6d6db55
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018172923-6d6db55
Deleted: sha256:5db941811952ba0453ad5ef4e80023b25fcc4a806b4a155c043d072c3d13bfd5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018164639-b75bbe3
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018164639-b75bbe3
Deleted: sha256:9fc5e5e525e81a5d6d12cc56bf02bd2abf52110095cd1a3fa6ce772fb1e5b1c9
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018164017-9ab5fc7
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018164017-9ab5fc7
Deleted: sha256:41564d8213e7dfaaca1b2f576852504cc9b737f1285684293963dea10163f54d
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018164401-61a94e5
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018164401-61a94e5
Deleted: sha256:fa8a4ea8a842321a6b9d0b2d1147ed4db173ce35bf185e556622d49d30b1c0b8
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018163358-def3f9b
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018163358-def3f9b
Deleted: sha256:2c1bbfd751bd1011d2dfbf62b83c036aa78822115dae3a1851447e9164fd8dc5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018153605-cfacc01
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018153605-cfacc01
Deleted: sha256:8ff7a4e68f28f257ec8a417c89cf231899f8dcae703ece2c076846fb8eb16850
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018154056-1abecaa
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018154056-1abecaa
Deleted: sha256:7fe9397b9e0ee81b8df3732e0e5dafd1b758141f2a2c677672776387dc8e2fa7
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018153115-f959137
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018153115-f959137
Deleted: sha256:47fe57c3ddeefffe72cc8a9705d4a3efcaeda4a9246456528adeabae14930af5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018151820-1b7bb71
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018151820-1b7bb71
Deleted: sha256:7d8913e1e39644bf174083e8558da9a0cfef97eb109b8ae454fda51daa01571a
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018151617-f0e93d1
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018151617-f0e93d1
Deleted: sha256:6a9b9a32ca8bb609be8e97faa93d00c5b72b1e03c924d9d226dccdc14c9920cc
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018145130-bf6a1b2
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018145130-bf6a1b2
Deleted: sha256:eb9d28bc4d97323a7f458a8fb56d50dd85d611763764f35cdcef57bb1111a6ad
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018144240-eac955c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018144240-eac955c
Deleted: sha256:f8654d80a1091ce12a915276df396fb9b811939565a967f9ff987cefa7374f2b
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018144410-836a633
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018144410-836a633
Deleted: sha256:f0a245c8044856bca3638a83f5aec7f3111133ebc695b29675e2d2067a97910d
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018144202-2e95f22
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018144202-2e95f22
Deleted: sha256:7c019fb958c4350f9c02fa0ab6ee7d6823cec188b4d3c5fb61ae483ac5b22d93
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018132959-77ea49c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018132959-77ea49c
Deleted: sha256:6e7ecc08167051b763dc6df7c4aeb74324f0ef8b2429591c9c921ebcdc19ac7f
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018132336-1505441
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018132336-1505441
Deleted: sha256:a300ab18068d8d0cee3e42cee88b49d451894844c35699c395377feed9f68012
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018132954-77ea49c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018132954-77ea49c
Deleted: sha256:2ffe42d9e68d297430525a90ebfde608a30b7f3f0308643398cc5e990adea7a2
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018131648-22ae3be
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018131648-22ae3be
Deleted: sha256:d73c2c230228f2b4652ba25444d26c9e146f58e326dd2deb53d300c160f3d5c2
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018131420-0234053
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018131420-0234053
Deleted: sha256:cc40986cc14ec47285b9982955129d01a6ed739a0f918a38e6ebb22201f9b339
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018131345-3bd5a20
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018131345-3bd5a20
Deleted: sha256:b278b974123dac1400ce70a2cb0497f76c8c00512960b7e1799a9189d2509cea
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018120421-2020193
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018120421-2020193
Deleted: sha256:6c1651d11be32130d4755876a6ef8556f0b9b6dece6fd9fb4de1e9c9b6310b95
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018115258-4983653
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018115258-4983653
Deleted: sha256:99f2021e1d603f691cffe18e907580ba4c2b1ba785e004313dfc50888b907d0a
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018121411-ccb243c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018121411-ccb243c
Deleted: sha256:f86eab3b4652ae18cb3b4f66d1a8d56fe3d9286d80365f9ce1e6bd1537f6c272
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018115210-67d5d3c
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018115210-67d5d3c
Deleted: sha256:d08d0e8656384fbb45ad882b669cb041879a85258d3277360412589d462292da
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018102050-470573f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018102050-470573f
Deleted: sha256:9275312f1938e8912b6795db657fd628e824684eb77b8843eb35b950426b14c5
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018100128-470573f
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018100128-470573f
Deleted: sha256:75c9510cf5032f13eae4cf35abc5e190670675855e6704776cbcf6774c4eda93
removing ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018090407-33eaedb
Untagged: ghcr.io/merlin-pinpin-org/kingdoms-services:pr-244-20261018090407-33eaedb
Deleted: sha256:e697a3aaf7220447e1a6003bd8269df0d2e66d9e40b5cec44ab1c952dad4edbb

## Disk after
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           763M   30M  734M   4% /run
/dev/sda1        38G   25G   14G  66% /
tmpfs           1.9G     0  1.9G   0% /dev/shm
tmpfs           1.9G   88K  1.9G   1% /tmp
/dev/sda13      989M  151M  772M  17% /boot
/dev/sda15      105M  6.3M   99M   7% /boot/efi
none            1.0M     0  1.0M   0% /run/credentials/serial-getty@ttyS0.service
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-networkd.service
