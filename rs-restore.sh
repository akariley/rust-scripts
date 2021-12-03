#!/bin/bash
rs_selfName=$(basename "$(readlink -f ${BASH_SOURCE[0]})")
rs_rootDir=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
if [[ ! -e ${rs_rootDir}/.rs.config ]]
then
  echo "Config file does not exist.  Please copy ${rs_rootDir}/.rs.config.example to ${rs_rootDir}/.rs.config and configure the settings as needed."
  exit 1
else
  source ${rs_rootDir}/.rs.config
fi

fullRestore=0

function show_Help {
  echo
  echo "Syntax: ${rs_selfName} [--full] backupFile [<date>]"
  echo "or"
  echo "Syntax: ${rs_selfName} list [<date>]"
  echo "Note: <date> is defined by backupDirSuffix in the .config file.  Currently it is ${backupDirSuffix}"
  echo 
}


# return codes
#
# 1 = syntax error
# 2 = server running

if [[ -z $1 ]] || [[ ${1} == '--help' ]] || [[ ${1} == '-h' ]]
then
  # no params -- display help
  show_Help
  exit
fi



if [[ $1 == "list" ]]
then
  # echo 'in list loop'
  if [[ -z $2 ]]
  then
    ls -1 ${backupDir}/${backupDirSuffix}/
  else
    ls -1 ${backupDir}/${2}
  fi
  exit
fi

if [[ ${1} == '--full' ]]
then
  fullRestore=1
  shift
fi


# got a backup file, check if it's another day's
if [[ -z $2 ]]
then
  # no date, assuming today
  if [[ -e ${backupDir}/${backupDirSuffix}/$1 ]]
  then
    # snag the instance name
    instanceName=$(tar --wildcards --list -f ${backupDir}/${backupDirSuffix}/$1 *serverfiles/server/* | head -n 1 | awk -F/ '{print $3}')
    instanceBackupList=(
      lgsm/config-lgsm/rustserver/${instanceName}.cfg
      lgsm/config-lgsm/rustserver/secrets-${instanceName}.cfg
      lgsm/config-lgsm/rustserver/common.cfg
      serverfiles/server/${instanceName}
    )

    echo "Extracting from ${backupDir}/${backupDirSuffix}/$1..."
    if [[ fullRestore -eq 1 ]]
    then
      for backupPath in "${backupList[@]}"
      do
        echo "Extract $backupPath?"
        select yn in "Yes" "No"
        do
          case $yn in
            Yes ) tar zxvf ${backupDir}/${backupDirSuffix}/${1} -C ${installDir} $backupPath ; break;;
            No ) break;;
          esac
        done
      done
      echo
    else
      for backupPath in "${instanceBackupList[@]}"
      do
        echo "Extract $backupPath?"
        select yn in "Yes" "No"
        do
          case $yn in
            Yes ) tar zxvf ${backupDir}/${backupDirSuffix}/${1} -C ${installDir} $backupPath ; break;;
            No ) break;;
          esac
        done
      done
      echo
    fi
  else
    echo "Error: ${backupDir}/${backupDirSuffix}/$1 does not exist.  Did you input the correct date?"
    exit 1
  fi
  echo
else
  # they put a file and a date, extract from it instead of $today    
  if [[ -e ${backupDir}/${2}/${1} ]]
  then
    # snag the instance name
    instanceName=$(tar --wildcards --list -f ${backupDir}/${backupDirSuffix}/$1 *serverfiles/server/* | head -n 1 | awk -F/ '{print $3}')
    instanceBackupList=(
      lgsm/config-lgsm/rustserver/${instanceName}.cfg
      lgsm/config-lgsm/rustserver/secrets-${instanceName}.cfg
      lgsm/config-lgsm/rustserver/common.cfg
      serverfiles/server/${instanceName}
    )

    echo "Extracting from ${backupDir}/${backupDirSuffix}/$1..."
    if [[ fullRestore -eq 1 ]]
    then
      for backupPath in "${backupList[@]}"
      do
        echo "Extract $backupPath?"
        select yn in "Yes" "No"
        do
          case $yn in
            Yes ) tar zxvf ${backupDir}/${backupDirSuffix}/${1} -C ${installDir} $backupPath ; break;;
            No ) break;;
          esac
        done
      done
      echo
    else
      for backupPath in "${instanceBackupList[@]}"
      do
        echo "Extract $backupPath?"
        select yn in "Yes" "No"
        do
          case $yn in
            Yes ) tar zxvf ${backupDir}/${backupDirSuffix}/${1} -C ${installDir} $backupPath ; break;;
            No ) break;;
          esac
        done
      done
      echo
    fi
  else
    echo "Error: ${backupDir}/${2}/${1} does not exist.  Did you input the correct date?"
    exit 1
  fi
  echo
  exit
fi  # end date / file check loop

