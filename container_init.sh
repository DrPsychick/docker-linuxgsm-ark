#!/bin/bash

# AFTER first install, BEFORE first run
if [ ! -r ./serverfiles/ShooterGame/Saved ]; then
  mkdir -p ./serverfiles/ShooterGame/Saved \
    && ln -s ../../../serverfiles_saved ./serverfiles/ShooterGame/Saved/SavedArks \
    && ln -s ../../../serverfiles_config ./serverfiles/ShooterGame/Saved/Config \
    && ln -s ../../../serverfiles_clusters ./serverfiles/ShooterGame/Saved/clusters
fi
