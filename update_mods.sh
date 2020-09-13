#!/bin/bash

export steamroot="/home/lgsm/.steam"
export steamcmdroot="$steamroot/steamcmd"
export steamappsroot="$steamroot/steam/steamapps"

mkdir -p serverfiles/ShooterGame/Content/Mods

# download mods (sequencial)
# for each $ARK_MODIDS
#   download
(IFS=","; for mod in $ARK_MODS; do
  echo "---> Installing MOD $mod..."
  #mod=731604991
  $steamcmdroot/steamcmd.sh +login anonymous +workshop_download_item 346110 $mod validate +quit
  # remove old mod files
  rm -rf serverfiles/ShooterGame/Content/Mods/$mod*
  #   extract (in background)
  ./extract_mod.sh $mod > /dev/null &
  echo -e "\n---> MOD $mod installed"
done)

# wait for children to finish
echo "---> waiting for background jobs to finish: "
while [ -n "$(jobs)" ] ; do
  sleep 0.5;
  echo -n "."
done

# link mods
(find $HOME/serverfiles/ShooterGame/Content/Mods -type l -exec rm {} ';')
(cd $HOME/serverfiles_mods; 
for f in $(ls -1 .); do 
  ln -s ../../../../serverfiles_mods/$f ../serverfiles/ShooterGame/Content/Mods/$f
done)

