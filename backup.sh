#!/bin/bash
#set -euo pipefail

if [ ! -e ./.config ]
then
  echo ".config file does not exist.  Please copy .config.example to .config and configure the settings as needed."
  #exit 1
fi

source ./.config

fullBackup=0

if [[ "$#" -eq 1 ]] || [[ "$#" -eq 0 ]]
then
  # zero or one option entered -- lets see if it's help.
  if [[ ${1} == '--help' ]] || [[ ${1} == '-h' ]]
  then
    echo "One input: help goes here."
    exit 3
  else
    if [[ -z ${1} ]]
    then
      echo "Zero input given: help goes here."
      exit 3
    fi
  fi
fi


while [ "$#" -gt 0 ]
do
  case ${1} in
    --all-instances|--full)
      # do a global backup so exit the loop
      fullBackup=1
      break
      ;;
    *)
      # unknown input, we need to check if it's asking for help or an instance name
      if [[ ${1} == "--help" ]] || [[ ${1} == '-h' ]]
      then
        # display help.
        echo "Help goes here."
        exit 3
      else
        # it's not help or --all, so it's an instance name.  let's check if it's valid.
        if [ ! -e ${installDir}/${1} ]
        then
          echo "Error: ${installDir}/${1} does not exist."
        else
          lgsmConfig=${installDir}/lgsm/config-lgsm/rustserver/${1}.cfg

          # let's snag the rcon stuff.

          rconIp=$(awk -F'=' '/[Ii][Pp]="?([0-9]{1,3}[\.]){3}[0-9]{1,3}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
          rconPort=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Oo][Rr][Tt]="?\d{0,5}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
          rconPassword=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Aa][Ss]{2}[Ww][Oo][Rr][Dd]="?[[:alnum:]]{0,63}"?/ {print $2}' ${lgsmConfig} | tr -d '"')

          instanceBackupList=(
            lgsm/config-lgsm/rustserver/${1}.cfg
            lgsm/config-lgsm/rustserver/secrets-${1}.cfg
            lgsm/config-lgsm/rustserver/common.cfg
            serverfiles/server/${1}
          )

          fileName=${user}_${1}_${backupDate}

          if [[ -z ${backupDirSuffix} ]]
          then
            # no prefix so omit the var
            fullName=${backupDir}/${fileName}.tar.gz
            trueBackupDir=${backupDir}
          else
            fullName=${backupDir}/${backupDirSuffix}/${fileName}.tar.gz
            trueBackupDir=${backupDir}/${backupDirSuffix}
          fi

          if [[ -d ${trueBackupDir}/ ]]
            then
            echo "Directory ${trueBackupDir}/ exists."
          else
            echo "Directory ${trueBackupDir}/ does not exist... making it."
            ${mkNice} mkdir -p --mode=700 ${trueBackupDir}/
          fi

          # do we need to save the server?
          if [[ -e ${installDir}/lgsm/lock/${1}.lock ]]
          then
            timeout 5 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "server.save"
          fi
          echo tar zcvf $fullName -C ${installDir} "${instanceBackupList[@]}"
          # let's sleep for a bit to avoid save churning.
          sleep 1
        fi
      fi
      ;;
  esac
  shift
done

