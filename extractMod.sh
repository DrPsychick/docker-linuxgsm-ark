#!/bin/bash

##
## credits go to https://github.com/FezVrasta/ark-server-tools/blob/master/tools/arkmanager
##
if [ -z "${1}" ]; then
  echo "Usage: $0 <steam_workshop_id>"
  exit 1
fi

modid=$1
mod_appid=346110
arkserverroot=/home/lgsm
arkserverdir=serverfiles_mods
steamcmdroot=/home/lgsm/steamcmd
# using Linux crashes the server:
mod_branch="Windows"

# defaults
steamworkshopdir=/home/lgsm/Steam/steamapps/workshop

#
# Extracts a mod into the ARK Mods directory
#
doExtractMod(){
  local modid=$1
  local steamdataroot="${steamdataroot:-${steamcmdroot}}"
  local steamworkshopdir="${steamworkshopdir:-${steamdataroot}/steamapps/workshop}"
  local modsrcdir="${steamworkshopdir}/content/$mod_appid/$modid"
  local moddestdir="$arkserverroot/${arkserverdir}/$modid"
  local modextractdir="$moddestdir"
  local modbranch="${mod_branch:-Windows}"
  if [[ -n "$arkStagingDir" && -d "$arkStagingDir" ]]; then
    modextractdir="$arkStagingDir/Mods/$modid"
  fi
  # Bypass the 111111111 modid used by Primitive+
  if [ "$modid" = "111111111" ]; then
    return 0
  fi
  if [ -n "${modsrcdirs[$modid]}" ]; then
    modsrcdir="${modsrcdirs[$modid]}"
  fi
  for varname in "${!mod_branch_@}"; do
    if [ "mod_branch_$modid" == "$varname" ]; then
      modbranch="${!varname}"
    fi
  done
  if [ -f "$modextractdir/.modbranch" ]; then
    mv "$modextractdir/.modbranch" "$modextractdir/__arkmanager_modbranch__.info"
  fi
  if [ \( ! -f "$modextractdir/__arkmanager_modbranch__.info" \) ] || [ "$(<"$modextractdir/__arkmanager_modbranch__.info")" != "$modbranch" ]; then
    rm -rf "$modextractdir"
  fi
  ls -l "$modsrcdir/mod.info"
  if [ -f "$modsrcdir/mod.info" ]; then
    echo "Copying files to $modextractdir"
    if [ -f "$modsrcdir/${modbranch}NoEditor/mod.info" ]; then
      modsrcdir="$modsrcdir/${modbranch}NoEditor"
    fi
    find "$modsrcdir" -type d -printf "$modextractdir/%P\0" | xargs -0 -r mkdir -p
    find "$modextractdir" -type f ! -name '.*' -printf "%P\n" | while read f; do
      if [ \( ! -f "$modsrcdir/$f" \) -a \( ! -f "$modsrcdir/${f}.z" \) ]; then
        rm "$modextractdir/$f"
      fi
    done
    find "$modextractdir" -depth -type d -printf "%P\n" | while read d; do
      if [ ! -d "$modsrcdir/$d" ]; then
        rmdir "$modextractdir/$d"
      fi
    done
    find "$modsrcdir" -type f ! \( -name '*.z' -or -name '*.z.uncompressed_size' \) -printf "%P\n" | while read f; do
      if [ \( ! -f "$modextractdir/$f" \) -o "$modsrcdir/$f" -nt "$modextractdir/$f" ]; then
        printf "%10d  %s  " "`stat -c '%s' "$modsrcdir/$f"`" "$f"
        if [[ -n "$useRefLinks" && "$(stat -c "%d" "$modsrcdir")" == "$(stat -c "%d" "$modextractdir")" ]]; then
          cp --reflink=auto "$modsrcdir/$f" "$modextractdir/$f"
        else
          cp "$modsrcdir/$f" "$modextractdir/$f"
        fi
        echo -ne "\r\\033[K"
      fi
    done
    find "$modsrcdir" -type f -name '*.z' -printf "%P\n" | while read f; do
      if [ \( ! -f "$modextractdir/${f%.z}" \) -o "$modsrcdir/$f" -nt "$modextractdir/${f%.z}" ]; then
        printf "%10d  %s  " "`stat -c '%s' "$modsrcdir/$f"`" "${f%.z}"
        perl -M'Compress::Raw::Zlib' -e '
          my $sig;
          read(STDIN, $sig, 8) or die "Unable to read compressed file: $!";
          if ($sig != "\xC1\x83\x2A\x9E\x00\x00\x00\x00"){
            die "Bad file magic";
          }
          my $data;
          read(STDIN, $data, 24) or die "Unable to read compressed file: $!";
          my ($chunksizelo, $chunksizehi,
              $comprtotlo,  $comprtothi,
              $uncomtotlo,  $uncomtothi)  = unpack("(LLLLLL)<", $data);
          my @chunks = ();
          my $comprused = 0;
          while ($comprused < $comprtotlo) {
            read(STDIN, $data, 16) or die "Unable to read compressed file: $!";
            my ($comprsizelo, $comprsizehi,
                $uncomsizelo, $uncomsizehi) = unpack("(LLLL)<", $data);
            push @chunks, $comprsizelo;
            $comprused += $comprsizelo;
          }
          foreach my $comprsize (@chunks) {
            read(STDIN, $data, $comprsize) or die "File read failed: $!";
            my ($inflate, $status) = new Compress::Raw::Zlib::Inflate();
            my $output;
            $status = $inflate->inflate($data, $output, 1);
            if ($status != Z_STREAM_END) {
              die "Bad compressed stream; status: " . ($status);
            }
            if (length($data) != 0) {
              die "Unconsumed data in input"
            }
            print $output;
          }
        ' <"$modsrcdir/$f" >"$modextractdir/${f%.z}"
        touch -c -r "$modsrcdir/$f" "$modextractdir/${f%.z}"
        echo -ne "\r\\033[K"
      fi
    done
    modname="$(curl -s "http://steamcommunity.com/sharedfiles/filedetails/?id=${modid}" | sed -n 's|^.*<div class="workshopItemTitle">\([^<]*\)</div>.*|\1|p')"
    if [ -f "${modextractdir}/.mod" ]; then
      rm "${modextractdir}/.mod"
    fi
    perl -e '
      my $data;
      { local $/; $data = <STDIN>; }
      my $mapnamelen = unpack("@0 L<", $data);
      my $mapname = substr($data, 4, $mapnamelen - 1);
      my $nummaps = unpack("@" . ($mapnamelen + 4) . " L<", $data);
      my $pos = $mapnamelen + 8;
      my $modname = ($ARGV[2] || $mapname) . "\x00";
      my $modnamelen = length($modname);
      my $modpath = "../../../" . $ARGV[0] . "/" . $ARGV[1] . "\x00";
      my $modpathlen = length($modpath);
      print pack("L< L< L< Z$modnamelen L< Z$modpathlen L<",
        $ARGV[1], 0, $modnamelen, $modname, $modpathlen, $modpath,
        $nummaps);
      for (my $mapnum = 0; $mapnum < $nummaps; $mapnum++){
        my $mapfilelen = unpack("@" . ($pos) . " L<", $data);
        my $mapfile = substr($data, $mapnamelen + 12, $mapfilelen);
        print pack("L< Z$mapfilelen", $mapfilelen, $mapfile);
        $pos = $pos + 4 + $mapfilelen;
      }
      print "\x33\xFF\x22\xFF\x02\x00\x00\x00\x01";
    ' "$arkserverdir" "$modid" "$modname" <"$modextractdir/mod.info" >"${modextractdir}.mod"
    if [ -f "$modextractdir/modmeta.info" ]; then
      cat "$modextractdir/modmeta.info" >>"${modextractdir}.mod"
    else
      echo -ne '\x01\x00\x00\x00\x08\x00\x00\x00ModType\x00\x02\x00\x00\x001\x00' >>"${modextractdir}.mod"
    fi
    echo "$modbranch" >"$modextractdir/__arkmanager_modbranch__.info"
    if [[ "$modextractdir" != "$moddestdir" ]]; then
      if [ ! -d "${moddestdir}" ]; then
        mkdir -p "${moddestdir}"
      fi
      if [ "$(stat -c "%d" "$modextractdir")" == "$(stat -c "%d" "$moddestdir")" ]; then
        if [ -n "$useRefLinks" ]; then
          cp -au --reflink=always --remove-destination "${modextractdir}/." "${moddestdir}"
        else
          cp -alu --remove-destination "${modextractdir}/." "${moddestdir}"
        fi
      else
        cp -au --remove-destination "${modextractdir}/." "${moddestdir}"
      fi
      find "${moddestdir}" -type f ! -name '.*' -printf "%P\n" | while read f; do
        if [ ! -f "${modextractdir}/${f}" ]; then
          rm "${moddestdir}/${f}"
        fi
      done
      find "$modextractdir" -depth -type d -printf "%P\n" | while read d; do
        if [ ! -d "$modsrcdir/$d" ]; then
          rmdir "$modextractdir/$d"
        fi
      done
      if [[ -n "$useRefLinks" && "$(stat -c "%d" "$modextractdir")" == "$(stat -c "%d" "$moddestdir")" ]]; then
        cp -u --reflink=always "${modextractdir}.mod" "${moddestdir}.mod"
      else
        cp -u "${modextractdir}.mod" "${moddestdir}.mod"
      fi
    fi
  fi
}

doExtractMod $modid
