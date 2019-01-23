[Docker image: drpsychick/linuxgsm-ark](https://hub.docker.com/r/drpsychick/linuxgsm-ark/)
=======================
[![DockerHub build status](https://img.shields.io/docker/build/drpsychick/linuxgsm-ark.svg)](https://hub.docker.com/r/drpsychick/linuxgsm-ark/builds/)
[![DockerHub build](https://img.shields.io/docker/automated/drpsychick/linuxgsm-ark.svg)](https://hub.docker.com/r/drpsychick/linuxgsm-ark/builds/)

* Source: https://github.com/DrPsychick/docker-linuxgsm-ark
* Image: https://hub.docker.com/r/drpsychick/linuxgsm-ark
* Based on: https://github.com/GameServerManagers/LinuxGSM-Docker

Known & Solved issues:
----------------------
* All ARK servers in a cluster MUST run with the same user as they share files on the host system
  * Ideally setup docker with user namespace mapping (--userns-remap), to keep the container user generic (UID=1000) and map it to what you need on the host
* Each ARK server REQUIRES dedicated ports, because the ports are communicated to the client (docker port mapping will not work!)
  * you can configure only three ports for ARK. It will automatically use game client port +1 as the fourth port.
  * see https://ark.gamepedia.com/Dedicated_Server_Setup#Network


Usage:
======
* create a docker container (with appropriate mounts, ports and ENV - see below)
* start/stop the container as you wish
* BACKUP the `_config`, `_saved` and `shared_clusters` directories when the servers are offline.

Directories:
* `serverfiles` contains the dedicated ARK server files (downloaded from steam) and links to the directories below
* `serverfiles_mods` contains - what a surprise - steam workshop mods (downloaded from steam)
* `<yourserver>_config` contains the config for your individual ARK server instance : BACKUP!
* `<yourserver>_saved` contains the save game for your individual ARK server instance : BACKUP!
* `shared_clusters` shared directory of clusters where ARK stores survivors to download to a world : BACKUP!

Clusters:
---------
To run a cluster with multiple worlds you need:
* RAM, a lot of it. Expect to provide at least 5G per server.
* mount the same `shared_clusters` directory in each docker container
* mount individual `_saved` and `_config` directories in each docker container
* use the `-clusterid=<clustername>` and `-NoTransferFromFiltering` parameters for ShooterGame in each docker container
* run two servers, go to a drop/obelisk/Tek+ Transmitter and travel to the other server
* enjoy!

Helpful commands:
-----------------
* look inside: `docker run --rm -it --name lgsm-ark --entrypoint /bin/bash drpsychick/linuxgsm-ark`
  * from within the container, take `lgsm/config-lgsm/arkserver/_default.cfg` as a starting point for your `arkserver.cfg` which you need to put into the `_saved` directory
  * start the server once with mounted directories and stop it when it is fully available - this will create all config files needed.
  * modify the `.ini` files (created by ARK during first start) in your `_config` directory to suit your needs
* run server with directories mounted, environment variables, ports, ...:
  * `--tty` is required, see entrypoint.sh of base image
  * `RCON_*` variables are required for healthcheck to work
  * you need to publish all ports, each server needs his own ports (if you run them on the same IP)
```
docker run --rm -it --name lgsm-ark --memory=5G --tty \
  --env ARK_MODS="731604991,889745138" \
  --env RCON_PORT=27020 --env RCON_PASS=mypass \
  --publish 7777:7777/udp --publish 7778:7778/udp --publish 27015:27015/udp --publish 27020:27020/tcp \
  --mount type=bind,source=$PWD/serverfiles,target=/home/lgsm/serverfiles \
  --mount type=bind,source=$PWD/serverfiles_mods,target=/home/lgsm/serverfiles_mods \
  --mount type=bind,source=$PWD/testark_saved,target=/home/lgsm/serverfiles_saved \
  --mount type=bind,source=$PWD/testark_config,target=/home/lgsm/serverfiles_config \
  --mount type=bind,source=$PWD/shared_clusters,target=/home/lgsm/serverfiles_clusters \
  drpsychick/linuxgsm-ark ./arkserver details
```

Docker user namespace remap
===========================
Settings for the docker HOST

* first line: map UID/GID 0 within the container to UID/GID 1000 on the host
* second line: map any UID/GID > 0 within the container to 10000+ on the host
* both lines: everything within the container runs as user: "hostuser" and group: "hostgroup" on the host
* Be careful! Before switching an existing docker environment to use `--userns-remap`, make sure to exclude containers that need `--priviledged` AND take care of permissions (volumes) of existing containers. Search for more information on the web or on the links below.

`/etc/subuid`
```hostuser:1000:1
hostuser:10000:65536
```

`/etc/subgid`
```hostgroup:1000:1
hostgroup:10000:65536
```

Further reading:
* https://docs.docker.com/engine/security/userns-remap/
* https://www.jujens.eu/posts/en/2017/Jul/02/docker-userns-remap/
