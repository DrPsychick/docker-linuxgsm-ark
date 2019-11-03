FROM drpsychick/linuxgsm-ubuntu:latest
LABEL description="linuxgsm-docker tuned for a cluster of ARK: Survival Evolved" \
      maintainer="github@drsick.net"

USER root
# install mcrcon python module (as root)
RUN apt-get update \
    && apt-get install -y git python-setuptools \
    && git clone https://github.com/barneygale/MCRcon \
    && (cd MCRcon; python setup.py install_lib) \
    && rm -rf MCRcon \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# switch to UID 1100 (temporary fix until I find time to setup userns-remap)
#RUN usermod -u 1100 lgsm

# UID 1000
# shared files must be owned by the same UID (ARK creates "clusters" files with its user and no group permissions)
# OR: enable --userns-remap for dockerd (RTFM!)
USER lgsm
# prepare for ark, run "arkserver" once to download linuxgsm functions etc. and link the "arkserver.cfg"
# WORKAROUND: download ARK dedicated server from steam and delete it (make sure its working and install steamcmd)
RUN ./linuxgsm.sh arkserver \
    && mkdir -p ./serverfiles ./serverfiles_saved ./serverfiles_config ./serverfiles_mods ./serverfiles_clusters \
    && ./arkserver && ./arkserver validate && rm -rf ./arkserver ./serverfiles/* \
    && mv ./lgsm/config-lgsm/arkserver/arkserver.cfg ./serverfiles_config/arkserver.cfg \
    && ln -s ../../../serverfiles_config/arkserver.cfg ./lgsm/config-lgsm/arkserver/arkserver.cfg

ADD update_mods.sh \
    extract_mod.sh \
    container_init.sh \
    container_warmup.sh \
    rcon.py /home/lgsm/

# you need to bind-mount these to persist server files to your drive
# serverfiles and serverfiles_mods : are shared between all servers
# serverfiles_saved and serverfiles_config : are "per server"
# serverfiles_clusters : is shared among all servers in a cluster
VOLUME /home/lgsm/serverfiles /home/lgsm/serverfiles_saved /home/lgsm/serverfiles_config /home/lgsm/serverfiles_mods /home/lgsm/serverfiles_clusters

# do NOT expose ports as each server must have dedicated ports (through configuration), because they are communicated to the client
# example: running 2 servers on port 7777 which is mapped by docker to different host ports -> the client will "see" only one ARK server that is running on 7777
#EXPOSE 7777/udp 7778/udp 27015/udp 27020/tcp

# UPDATE: RCON_HOST=localhost WILL work, if you do NOT use the "?Multihome=<eth0 IP>" command line parameter of ShooterGame
# localhost will NOT work when ARK server listens on eth0 IP only
# you need to set RCON_PORT and RCON_PASS when starting your container for healthcheck to work
ENV RCON_HOST=localhost RCON_PORT=27020 RCON_PASS=password
HEALTHCHECK --interval=10s --timeout=1s --retries=3 CMD python /home/lgsm/rcon.py listplayers

ENV SERVERNAME="arkserver"
ENV UPDATE_LGSM="" UPDATE_SERVER="" FORCE_VALIDATE="" UPDATE_MODS=""
ENV CONTAINER_INIT="yes" CONTAINER_WARMUP="yes"
CMD ["start"]
