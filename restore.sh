#!/bin/bash
#set -euo pipefail
BACKUPDIR=/game-backups
RUSTDIR=rust
BACKUPDIRPREFIX=${USER}-backup
DIR=${BACKUPDIRPREFIX}/`date +%F`
FILENAME=${BACKUPDIRPREFIX}/`date +%H%M`
FULLNAME=${BACKUPDIR}/${DIR}/${FILENAME}.tar.gz
TODAY=`date +%F`
#TODAY=$(date +%Y-%b-%d-%H%M)
source ./.config


FILENAME=${USER}-$(date +%Y-%b-%d-%H%M)

if [ -z ${BACKUPDIRPREFIX} ]
then
  #no prefix so omit the var
  FULLNAME=${BACKUPDIR}/${FILENAME}.tar.gz
else
  FULLNAME=${BACKUPDIR}/${BACKUPDIRPREFIX}/${FILENAME}.tar.gz
fi

#
# /game-backups/rust-testing/09/rust-testing-2021-Sep-12-0826.tar.gz
#


# if modded
# home/${USER}/rust/serverfiles/oxide/


# error codes
#
# 1 = syntax error
# 2 = 

if [[ -z $1 ]]
  then
  # no params -- display help
  echo
  echo "Syntax: $0 [backupfile] <date (YYYY-MM-DD); if omitted, today is assumed>"
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
    ls ${BACKUPDIR}/${BACKUPDIRPREFIX}/
    exit
  fi
  ls ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}
  exit
fi



if [[ $PWD == $HOME ]]
  then
  # we're in the homedir, continue.
  # echo 'in homedir'
  # echo 'Deleting test dir...'
  # rm -rv ${HOME}/testdir/
  # mkdir --mode=700 ${HOME}/testdir || exit 1
  
  
  # got a backup file, check if it's another day's
  # TODO: proper regex for format.
  if [[ -z $2 ]]
    then
    # check if server is running.
    if [[ -e ${HOME}/${RUSTDIR}/.rustserver.lock ]]
      then
      echo "Error: Server is running.  Stop it first. (and make a backup!)"
      exit
    fi
    # no date, assuming today
    if [[ -e ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 ]]
      then
      echo
      echo "Extracting from ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/${1}..."
      echo
      echo
      echo "Extract maps?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/proceduralmap*" ; break;;
          No ) break;;
        esac
      done
    echo "Extract configs?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/lgsm/config-lgsm/rustserver/ ; tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/cfg*" ; break;;
          No ) break;;
        esac
      done
    tar -tf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 *home/${USER}/rust/serverfiles/oxide/* > /dev/null 2>&1
    if [[ ! "$?" == 2 ]]
      # oxide found
      then
      echo "Extract Oxide files?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/oxide/" ; break;;
          No ) break;;
        esac
      done
    fi
    echo "Extract blueprints?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/player.blueprints*" ; break;;
          No ) break;;
        esac
      done
    else
      echo "Error: ${BACKUPDIR}/${BACKUPDIRPREFIX}/${USER}-${TODAY}/$1 does not exist.  Did you input the correct date?"
      exit 1
    fi
  echo
  else
    # they put a date and a file, extract from it instead of $today    
    
    # check if server is running.
    if [[ -e ${HOME}/${RUSTDIR}/.rustserver.lock ]]
      then
      echo "WARNING: Server is running.  Stop it first. (and make a backup!)"
      exit
    fi
    
    
    
    if [[ -e ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} ]]
      then
      echo
      echo "Extracting from ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1}..."
      echo
      echo
      echo "Extract maps?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/proceduralmap*" ; break;;
          No ) break;;
        esac
      done
      echo "Extract configs?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} --strip-components=2 home/${USER}/rust/lgsm/config-lgsm/rustserver/ ; tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/cfg*" ; break;;
          No ) break;;
        esac
      done
    tar -tf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} *home/${USER}/rust/serverfiles/oxide/* > /dev/null 2>&1
    if [[ ! "$?" == 2 ]]
      # oxide found
      then
      echo "Extract Oxide files?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/oxide/" ; break;;
          No ) break;;
        esac
      done
    fi
      echo "Extract blueprints?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) echo "tar zxvf ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/player.blueprints*" ; break;;
          No ) break;;
        esac
      done
    echo
    
      else
      # file doesn't exist.
      echo "Error: ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1} does not exist.  Did you input the correct date?"
      exit 1
    fi
    # echo "Extracting from ${BACKUPDIR}/${BACKUPDIRPREFIX}/${2}/${1}..."
    echo
    exit
    fi # end date / file check loop
else
  echo "You need to run this file from ${HOME}; you're in ${PWD} currently."
  exit 1
  echo
fi
