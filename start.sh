#!/bin/bash

# upon every start 
if [ -n "$UPDATE_LGSM" -o ! -d "./lgsm/lgsm-functions" ]; then
  ./arkserver update-lgsm 
fi
if [ -n "$FORCE_UPDATE" -o ! -d "./serverfiles/ShooterGame/Content/Maps" ]; then
  ./arkserver auto-install
fi
if [ -n "$FORCE_VALIDATE" -o ! -d "./steamcmd" ]; then
  ./arkserver validate
fi

# AFTER first install, BEFORE first run
if [ ! -r ./serverfiles/ShooterGame/Saved ]; then
  mkdir -p ./serverfiles/ShooterGame/Saved \
    && ln -s ../../../serverfiles_saved ./serverfiles/ShooterGame/Saved/SavedArks \
    && ln -s ../../../serverfiles_config ./serverfiles/ShooterGame/Saved/Config \
    && ln -s ../../../serverfiles_clusters ./serverfiles/ShooterGame/Saved/clusters
fi

# when mods are missing
(export FORCE_UPDATE_MODS
IFS=","; for m in $ARK_MODS; do
  if [ ! -r "./serverfiles_mods/$m" ]; then
    FORCE_UPDATE_MODS="yes"
  fi
done
if [ -n "$FORCE_UPDATE_MODS" ]; then
  ./updateMods.sh
fi)

echo "Configuring mods in GameUserSettings: $ARK_MODS"
sed -i -e "s/ActiveMods=.*/ActiveMods=$ARK_MODS/" ./serverfiles_config/LinuxServer/GameUserSettings.ini

# now fallback to parent entrypoint
bash /entrypoint.sh $@

