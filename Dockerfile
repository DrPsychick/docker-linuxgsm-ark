ARG UBUNTU_VERSION=latest
FROM drpsychick/linuxgsm-ubuntu:$UBUNTU_VERSION
LABEL description="linuxgsm-docker tuned for a cluster of ARK: Survival Evolved" \
      maintainer="github@drsick.net"

USER root
COPY update_mods.sh \
    extract_mod.sh \
    container_init.sh \
    container_stop.sh \
    container_warmup.sh \
    rcon-ark.py \
    /home/lgsm/
RUN chown lgsm:lgsm /home/lgsm/*

# UID 750
# shared files must be owned by the same UID (ARK creates "clusters" files with its user and no group permissions)
# OR: enable --userns-remap for dockerd (RTFM!)
USER lgsm

# prepare for ark, run "arkserver" once to download linuxgsm functions etc. and link the "arkserver.cfg"
# WORKAROUND: download ARK dedicated server from steam and delete it (make sure its working and install steamcmd)
RUN ./linuxgsm.sh arkserver \
    && mkdir -p ./serverfiles ./serverfiles_saved/Config ./serverfiles_mods ./serverfiles_clusters \
    && sed -i -e 's/+quit | tee -a/+quit | uniq | tee -a/' lgsm/functions/core_dl.sh \
    && ./arkserver && ./arkserver validate; ARK_MODS=731604991 ./update_mods.sh; \
    rm -rf ./arkserver ./serverfiles/* ./serverfiles_mods/* ./.steam/steamapps/workshop ./.steam/depotcache/* ./.steam/appcache/* \
    && mv ./lgsm/config-lgsm/arkserver/arkserver.cfg ./serverfiles_saved/Config/arkserver.cfg \
    && ln -s ../../../serverfiles_saved/Config/arkserver.cfg ./lgsm/config-lgsm/arkserver/arkserver.cfg

# you need to bind-mount these to persist server files to your drive
# serverfiles and serverfiles_mods : are shared between all servers
# serverfiles_saved : is "per server"
# serverfiles_clusters : is shared among all servers in a cluster
VOLUME /home/lgsm/serverfiles /home/lgsm/serverfiles_saved /home/lgsm/serverfiles_mods /home/lgsm/serverfiles_clusters

# do NOT expose ports as each server must have dedicated ports (through configuration), because they are communicated to the client
# example: running 2 servers on port 7777 which is mapped by docker to different host ports -> the client will "see" only one ARK server that is running on 7777
#EXPOSE 7777/udp 7778/udp 27015/udp 27020/tcp

# UPDATE: RCON_HOST=localhost WILL work, if you do NOT use the "?Multihome=<eth0 IP>" command line parameter of ShooterGame
# localhost will NOT work when ARK server listens on eth0 IP only
# you need to set RCON_PORT and RCON_PASS when starting your container for healthcheck to work
ENV RCON_HOST=localhost \
    RCON_PORT=27020 \
    RCON_PASS=password
HEALTHCHECK --interval=10s --timeout=1s --retries=3 CMD python3 /home/lgsm/rcon-ark.py listplayers

ENV SERVERNAME="arkserver" \
    UPDATE_LGSM="" \
    UPDATE_SERVER="" \
    FORCE_VALIDATE="" \
    UPDATE_MODS="" \
    CONTAINER_INIT="yes" \
    CONTAINER_WARMUP="yes"
CMD ["start"]
