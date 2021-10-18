#!/bin/bash
#set -euo pipefail

if [ ! -e ./.config ]
then
  echo ".config file does not exist.  Please copy .config.example to .config and configure the settings as needed."
  exit 1
fi

source ./.config

if [ -z ${1} ]
then
  # $1 is empty, assuming the default name
  instanceName=rustserver
else
  instanceName=${1}
fi

if [ ! -e ${installDir}/${instanceName} ]
then
  echo "Error: ${installDir}/${instanceName} does not exist."
  exit 1
else
  lgsmConfig=${installDir}/lgsm/config-lgsm/${instanceName}/${instanceName}.cfg
fi


if [ ${saveOnBackup} -eq 1 ]
then
  # check if webrcon is valid.
  if [ ! -e ${webRconCmd} ]
  then
    echo "Warning: saveOnBackup is true, but webRconCmd isn't a valid path.  Disabling saveOnBackup for this run."
    saveOnBackup=0
  fi
  # check if lgsmConfig is filled out.
  if [ ! -e ${lgsmConfig} ]
  then
    echo "Warning: saveOnBackup is true, but lgsmConfig isn't a valid path.  Disabling saveOnBackup for this run."
    saveOnBackup=0
  fi
  # end sanity checks.
fi

fileName=${user}_${instanceName}_${backupDate}

if [ -z ${backupDirSuffix} ]
then
  #no prefix so omit the var
  fullName=${backupDir}/${fileName}.tar.gz
else
  fullName=${backupDir}/${backupDirSuffix}/${fileName}.tar.gz
fi

mkNice='ionice -c 3'

# code follows

if [[ -d ${backupDir}/${backupDirSuffix}/ ]]
  then
  echo "Directory ${backupDir}/${backupDirSuffix}/ exists."
else
  echo "Directory ${backupDir}/${backupDirSuffix}/ does not exist... making it."
  ${mkNice} mkdir -p --mode=700 ${backupDir}/${backupDirSuffix}/
fi
# Directory made... proceed.
if [ ${saveOnBackup} -eq 1 ]
then
  # do a server.save first
  # check if the server is running.
  if pgrep -u $(whoami) RustDedicated > /dev/null
  then
    echo "Server is running; sending 'server.save' via rcon."
    rconIp=$(awk -F'=' '/[Ii][Pp]="?([0-9]{1,3}[\.]){3}[0-9]{1,3}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
    rconPort=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Oo][Rr][Tt]="?\d{0,5}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
    rconPassword=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Aa][Ss]{2}[Ww][Oo][Rr][Dd]="?[[:alnum:]]{0,63}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
    timeout 5 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "server.save"
    #end server run check
  fi
  # end save check
fi

echo "Making ${fullName}"
${mkNice} tar zcvf $fullName -C ${installDir} "${backupList[@]}"
echo "Done!"
