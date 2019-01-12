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

EXPOSE 7777/udp 7778/udp 27015/udp 27020/tcp
