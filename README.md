docker-linuxgsm-ark
===================

Known & Solved issues:
----------------------
* Each ARK server MUST run with the same user as they share files on the host system
** Ideally setup docker with user namespace mapping (--userns-remap), to keep the container user generic (UID=1000) and map it to what you need on the host
* Each ARK server REQUIRES dedicated ports, because the ports are communicated to the client (docker port mapping will not work!)


Usage:
* create a docker container (with appropriate mounts, ports and ENV)
* start/stop the container as you wish

Helpful commands:

* look inside: docker run --rm -it --name lgsm-ark docker-linuxgsm-ark /bin/bash
* including mounts: 
```
docker run --rm -it --name lgsm-ark \
  --env ARK_MODS="731604991,889745138" \
  --publish 7777/udp --publish 7778/udp --publish 27015/udp --publish 27020/tcp \
  --mount type=bind,source=$PWD/serverfiles,target=/home/lgsm/serverfiles \
  --mount type=bind,source=$PWD/serverfiles_mods,target=/home/lgsm/serverfiles_mods \
  --mount type=bind,source=$PWD/testark_saved,target=/home/lgsm/serverfiles_saved \
  --mount type=bind,source=$PWD/testark_config,target=/home/lgsm/serverfiles_config \
  --mount type=bind,source=$PWD/testark_clusters,target=/home/lgsm/serverfiles_clusters \
  drpsychick/linuxgsm-ark ./start.sh ./arkserver details
```
