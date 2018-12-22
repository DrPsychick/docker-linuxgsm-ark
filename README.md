docker-linuxgsm-ark
===================

Usage:
* 

Helpful commands:

* look inside: docker run --rm -it --name lgsm-ark docker-linuxgsm-ark /bin/bash
* including mounts: 
```
docker run --rm -it --name lgsm-ark \
  --mount type=bind,source=$PWD/serverfiles,target=/home/lgsm/serverfiles \
  --mount type=bind,source=$PWD/serverfiles_mods,target=/home/lgsm/serverfiles_mods \
  --mount type=bind,source=$PWD/testark_saved,target=/home/lgsm/serverfiles_saved \
  --mount type=bind,source=$PWD/testark_config,target=/home/lgsm/serverfiles_config \
  --mount type=bind,source=$PWD/testark_clusters,target=/home/lgsm/serverfiles_clusters \
  docker-linuxgsm-ark /bin/bash
```
