#!/bin/bash

# AFTER first install, BEFORE first run
if [ ! -r ./serverfiles/ShooterGame/Saved ]; then
  mkdir -p ./serverfiles/ShooterGame/Saved \
    && ln -s ../../../serverfiles_saved/SavedArks ./serverfiles/ShooterGame/Saved/SavedArks \
    && ln -s ../../../serverfiles_saved/Config ./serverfiles/ShooterGame/Saved/Config \
    && ln -s ../../../serverfiles_saved/Logs ./serverfiles/ShooterGame/Saved/Logs \
    && ln -s ../../../serverfiles_saved/SaveGames ./serverfiles/ShooterGame/Saved/SaveGames \
    && ln -s ../../../serverfiles_clusters ./serverfiles/ShooterGame/Saved/clusters
fi
