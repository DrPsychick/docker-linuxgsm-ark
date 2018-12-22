FROM gameservermanagers/linuxgsm-docker

USER root
RUN apt-get update && apt-get install -y jq # should be in base image?!?

# TODO: cleanup

USER lgsm
RUN ./linuxgsm.sh arkserver \
    && mkdir ./serverfiles ./serverfiles_saved ./serverfiles_config ./serverfiles_mods ./serverfiles_clusters \
    && ./arkserver \
    && mv ./lgsm/config-lgsm/arkserver/arkserver.cfg ./serverfiles_config/arkserver.cfg \
    && ln -s ../../../serverfiles_config/arkserver.cfg ./lgsm/config-lgsm/arkserver/arkserver.cfg

ADD updateMods.sh extractMod.sh start.sh /home/lgsm/

VOLUME /home/lgsm/serverfiles /home/lgsm/serverfiles_saved /home/lgsm/serverfiles_config /home/lgsm/serverfiles_mods /home/lgsm/serverfiles_clusters
