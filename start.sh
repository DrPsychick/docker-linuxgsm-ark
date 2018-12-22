#!/bin/bash

# upon every start 
if [ -n "$UPDATE_LGSM" -o ! -d "./lgsm/lgsm-functions" ]; then
  ./arkserver update-lgsm 
fi
if [ -n "$FORCE_UPDATE" -o ! -d "./serverfiles/ShooterGame/Content/Maps" ]; then
  ./arkserver auto-install
fi

# AFTER first install, BEFORE first run
if [ ! -r ./serverfiles/ShooterGame/Saved ]; then
  mkdir -p ./serverfiles/ShooterGame/Saved \
    && ln -s ../../../serverfiles_saved ./serverfiles/ShooterGame/Saved/SavedArks \
    && ln -s ../../../serverfiles_config ./serverfiles/ShooterGame/Saved/Config \
    && ln -s ../../../serverfiles_clusters ./serverfiles/ShooterGame/Saved/clusters
fi

# lgsm config
# lgsm/config-lgsm/arkserver/arkserver.cfg

# upon every start
./updateMods.sh

# now fallback to parent entrypoint
bash /entrypoint.sh

