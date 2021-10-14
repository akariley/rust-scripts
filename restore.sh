#!/bin/bash
#set -euo pipefail
#backupDir=/game-backups
#rustDir=rust
#backupDirSuffix=${user}-backup
#DIR=${backupDirSuffix}/`date +%F`
#fileName=${backupDirSuffix}/`date +%H%M`
#fullName=${backupDir}/${DIR}/${fileName}.tar.gz
#TODAY=`date +%F`
#TODAY=$(date +%Y-%b-%d-%H%M)

if [ ! -e ./.config ]
then
  echo ".config file does not exist.  Please copy .config.example to .config and configure the settings as needed."
  exit 1
fi

source ./.config

fileName=${user}-${backupDate}

if [ -z ${backupDirSuffix} ]
then
  #no prefix so omit the var
  fullName=${backupDir}/${fileName}.tar.gz
else
  fullName=${backupDir}/${backupDirSuffix}/${fileName}.tar.gz
fi

#
# /game-backups/rust-testing/09/rust-testing-2021-Sep-12-0826.tar.gz
#


# if modded
# home/${user}/rust/serverfiles/oxide/


# return codes
#
# 1 = syntax error
# 2 = server running

if [[ -z $1 ]]
then
  # no params -- display help
  echo
  echo "Syntax: $0 [backupfile] <date (XX); pad single digits with a prededing 0 (ie, March is '03')>"
  echo "or"
  echo "Syntax: $0 [list] <date (XX); pad single digits with a prededing 0 (ie, March is '03')>"
  echo 
  exit
fi

echo "$@"

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

# got a backup file, check if it's another day's
# TODO: proper regex for format.
if [[ -z $2 ]]
then
# check for lock files.
  if [[ -e ${installDir}/lgsm/lock/rustserver.lock ]]
  then
    echo "Error: Server is running.  Stop it first. (and make a backup!)"
    exit 2
  fi
  # no date, assuming today
  if [[ -e ${backupDir}/${backupDirSuffix}/$1 ]]
  then
    echo "Extracting from ${backupDir}/${backupDirSuffix}/$1..."
    for backupPath in "${backupList[@]}"
    do
      backupPath=$(echo "${backupPath}" | cut -d/ -f2-)
      echo "Extract $backupPath?"
      select yn in "Yes" "No"
      do
        case $yn in
          Yes ) tar zxvf ${backupDir}/${backupDirSuffix}/${1} -C ${installDir} --strip-components=3 $backupPath ; break;;
          No ) break;;
        esac
      done
    done
    echo
  else
    echo "Error: ${backupDir}/${backupDirSuffix}/$1 does not exist.  Did you input the correct date?"
    exit 1
  fi
  echo
else
  # they put a file and a date, extract from it instead of $today    
  # check for lock files.
  if [[ -e ${installDir}/lgsm/lock/rustserver.lock ]]
  then
    echo "Error: Server is running.  Stop it first. (and make a backup!)"
    exit 2
  fi
  if [[ -e ${backupDir}/${2}/${1} ]]
  then
    echo
    echo "Extracting from ${backupDir}/${2}/${1}..."
    echo
    for backupPath in "${backupList[@]}"
    do
      backupPath=$(echo ${backupPath} | cut -d/ -f2-)
      echo "Extract $backupPath?"
      select yn in "Yes" "No"
      do
        case $yn in
          Yes ) tar zxvf ${backupDir}/${2}/${1} C ${installDir} --strip-components=3 $backupPath ; break;;
          No ) break;;
        esac
      done
    done
    echo
  else
    echo "Error: ${backupDir}/${2}/${1} does not exist.  Did you input the correct date?"
    exit 1
  fi
  echo
  exit
fi  # end date / file check loop

