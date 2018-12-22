#!/bin/bash

# download mods (sequencial)
# for each $ARK_MODIDS
#   download
for mod in $ARK_MODS; do
  echo "---> Installing MOD $mod..."
  #mod=731604991
  ./steamcmd/steamcmd.sh +login anonymous +workshop_download_item 346110 $mod validate +quit
  # remove old mod files
  rm -rf serverfiles/ShooterGame/Content/Mods/$mod*
  #   extract (in background)
  ./extractMod.sh $mod > /dev/null &
done

# TODO: wait for children to finish
sleep 2;

# link mods
(find $HOME/serverfiles/ShooterGame/Content/Mods -type l -exec rm {} ';')
(cd $HOME/serverfiles_mods; 
for f in $(ls -1 .); do 
  ln -s ../../../../serverfiles_mods/$f ../serverfiles/ShooterGame/Content/Mods/$f
done)

