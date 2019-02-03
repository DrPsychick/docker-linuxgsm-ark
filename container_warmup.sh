#!/bin/bash

# trigger update_mods.sh if a mod is missing
(IFS=","; for m in $ARK_MODS; do
  if [ ! -r "./serverfiles_mods/$m" ]; then
    update_mods.sh
    break
  fi
done)

# ENV -> config
echo "Configuring mods in GameUserSettings: $ARK_MODS"
sed -i -e "s/ActiveMods=.*/ActiveMods=$ARK_MODS/" ./serverfiles_config/LinuxServer/GameUserSettings.ini
