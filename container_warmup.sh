#!/bin/bash

# trigger migration of directories
if [ -r ./serverfiles_config/arkserver.cfg -a -n "$(ls ./serverfiles_saved/*.ark 2>/dev/null)" ]; then
  echo "--> Starting migration to new 'serverfiles_saved' structure"
  # migrate to new `saved` directory structure
  # move saved
  mkdir ./serverfiles_saved/SavedArks
  mv ./serverfiles_saved/* ./serverfiles_saved/SavedArks/
  rm ./serverfiles/ShooterGame/Saved/SavedArks
  ln -s ../../../serverfiles_saved/SavedArks ./serverfiles/ShooterGame/Saved/SavedArks
  # move Logs
  mkdir ./serverfiles_saved/Logs
  if [ ! -h ./serverfiles/ShooterGame/Saved/Logs ]; then
    mv ./serverfiles/ShooterGame/Saved/Logs/* ./serverfiles_saved/Logs/
    rmdir ./serverfiles/ShooterGame/Saved/Logs
    ln -s ../../../serverfiles_saved/Logs ./serverfiles/ShooterGame/Saved/Logs
  fi
  # move SaveGames
  mkdir ./serverfiles_saved/SaveGames
  if [ ! -h ./serverfiles/ShooterGame/Saved/SaveGames ]; then
    mv ./serverfiles/ShooterGame/Saved/SaveGames/* ./serverfiles_saved/SaveGames/
    rmdir ./serverfiles/ShooterGame/Saved/SaveGames
    ln -s ../../../serverfiles_saved/SaveGames ./serverfiles/ShooterGame/Saved/SaveGames
  fi
  # move config
  mkdir ./serverfiles_saved/Config
  mv ./serverfiles_config/* ./serverfiles_saved/Config/
  if [ ! -h ./serverfiles/ShooterGame/Saved/Config ]; then
    rm ./serverfiles/ShooterGame/Saved/Config
    ln -s ../../../serverfiles_saved/Config ./serverfiles/ShooterGame/Saved/Config
  fi

  echo "--> Migration complete: you no longer need to mount 'serverfiles_config'"
fi

# trigger update_mods.sh if a mod is missing
(IFS=","; for m in $ARK_MODS; do
  if [ ! -r "./serverfiles_mods/$m" ]; then
    update_mods.sh
    break
  fi
done)

# ENV -> config
echo "Configuring mods in GameUserSettings: $ARK_MODS"
sed -i -e "s/ActiveMods=.*/ActiveMods=$ARK_MODS/" ./serverfiles_saved/Config/LinuxServer/GameUserSettings.ini
