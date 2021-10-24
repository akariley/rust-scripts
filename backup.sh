#!/bin/bash
rs_selfName=$(basename "$(readlink -f ${BASH_SOURCE[0]})")
rs_rootDir=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
if [[ ! -e ${rs_rootDir}/.config ]]
then
  echo ".config file does not exist.  Please copy ${rs_rootDir}/.config.example to ${rs_rootDir}/.config and configure the settings as needed."
  exit 1
else
  source ${rs_rootDir}/.config
fi

temp_Files

function script_exit {
    rm -v $tmpFile
}

trap script_exit exit

fullBackup=0
mkNice='ionice -c 3'

while [ "$#" -gt 0 ]
do
  case ${1} in
    --full)
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
        if [[ ! -e ${installDir}/${1} ]]
        then
          echo "Error: ${installDir}/${1} does not exist."
        else
          lgsmConfig=${installDir}/lgsm/config-lgsm/rustserver/${1}.cfg
          echo ${1} >> $tmpFile
        fi # end instance validation
      fi # end input checking
      ;;
  esac
  shift
done

if [[ ${fullBackup} -eq 1 ]]
then
  fileName=${user}-${backupDate}
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
  echo "Making ${fullName}"
  ${mkNice} tar zcf $fullName -C ${installDir} "${backupList[@]}" 
  exit
else
  while read instanceName
  do
    # let's snag the rcon stuff.
    lgsmConfig=${installDir}/lgsm/config-lgsm/rustserver/${instanceName}.cfg

    rconIp=$(awk -F'=' '/[Ii][Pp]="?([0-9]{1,3}[\.]){3}[0-9]{1,3}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
    rconPort=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Oo][Rr][Tt]="?\d{0,5}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
    rconPassword=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Aa][Ss]{2}[Ww][Oo][Rr][Dd]="?[[:alnum:]]{0,63}"?/ {print $2}' ${lgsmConfig} | tr -d '"')

    instanceBackupList=(
      lgsm/config-lgsm/rustserver/${instanceName}.cfg
      lgsm/config-lgsm/rustserver/secrets-${instanceName}.cfg
      lgsm/config-lgsm/rustserver/common.cfg
      serverfiles/server/${instanceName}
    )

    fileName=${user}_${instanceName}_${backupDate}

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
    if [[ -e ${installDir}/lgsm/lock/${instanceName}.lock ]]
    then
      timeout 5 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "server.save"
    fi
    tar zcf $fullName -C ${installDir} "${instanceBackupList[@]}"
    # let's sleep for a bit to avoid save churning.
    sleep 1
  done < $tmpFile

fi
