FROM gameservermanagers/linuxgsm-docker

USER root
RUN apt-get update \
    && apt-get install -y jq # should be in base image?!?

# cleanup
RUN apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# switch to UID 1100 (temporary fix until I find time to setup userns-remap)
RUN usermod -u 1100 lgsm

# UID 1000
# shared files must be owned by the same UID (ARK creates "clusters" files with its user and no group permissions)
# OR: enable --userns-remap for dockerd (RTFM!)
USER lgsm
RUN ./linuxgsm.sh arkserver \
    && mkdir ./serverfiles ./serverfiles_saved ./serverfiles_config ./serverfiles_mods ./serverfiles_clusters \
    && ./arkserver \
    && mv ./lgsm/config-lgsm/arkserver/arkserver.cfg ./serverfiles_config/arkserver.cfg \
    && ln -s ../../../serverfiles_config/arkserver.cfg ./lgsm/config-lgsm/arkserver/arkserver.cfg

ADD updateMods.sh extractMod.sh start.sh /home/lgsm/

VOLUME /home/lgsm/serverfiles /home/lgsm/serverfiles_saved /home/lgsm/serverfiles_config /home/lgsm/serverfiles_mods /home/lgsm/serverfiles_clusters

# download + delete ARK dedicated server from steam (make sure its working and install steamcmd)
RUN ./arkserver validate 
  #&& rm -rf ./serverfiles/*

# do NOT expose ports as each server must have dedicated ports (through configuration), because they are communicated to the client
# example: running 2 servers on port 7777 which is mapped by docker to different host ports -> the client will "see" only one ARK server that is running on 7777
#EXPOSE 7777/udp 7778/udp 27015/udp 27020/tcp
