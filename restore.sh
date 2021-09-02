#!/bin/bash
#set -euo pipefail
BASEDIR=/game-backups
RUSTDIR=rust
PREFIX=${USER}-backup
DIR=${PREFIX}-`date +%F`
FILENAME=${PREFIX}-`date +%H%M`
FULLNAME=${BASEDIR}/${DIR}/${FILENAME}.tar.gz
TODAY=`date +%F`

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
  echo "Syntax: $0 [list] <date (YYYY-MM-DD)>"
  echo 
  exit
fi

echo "$@"

if [[ $1 == "list" ]]
  then
  # echo 'in list loop'
  if [[ -z $2 ]]
    then
    ls ${BASEDIR}/${PREFIX}-${TODAY}
    exit
  fi
  ls ${BASEDIR}/${PREFIX}-${2}
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
      echo "WARNING: Server is running.  Stop it first. (and make a backup!)"
      exit
    fi
    # no date, assuming today
    if [[ -e ${BASEDIR}/${PREFIX}-${TODAY}/$1 ]]
      then
      echo
      echo "Extracting from ${BASEDIR}/${PREFIX}-${TODAY}/${1}..."
      echo
      echo
      echo "Extract maps?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/proceduralmap* ; break;;
          No ) break;;
        esac
      done
    echo "Extract configs?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/lgsm/config-lgsm/rustserver/ ; tar zxvf ${BASEDIR}/${PREFIX}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/cfg* ; break;;
          No ) break;;
        esac
      done
    tar -tf ${BASEDIR}/${PREFIX}-${TODAY}/$1 *home/${USER}/rust/serverfiles/oxide/* > /dev/null 2>&1
    if [[ ! "$?" == 2 ]]
      # oxide found
      then
      echo "Extract Oxide files?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/oxide/ ; break;;
          No ) break;;
        esac
      done
    fi
    echo "Extract blueprints?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${TODAY}/$1 --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/player.blueprints* ; break;;
          No ) break;;
        esac
      done
    else
      echo "Error: ${BASEDIR}/${PREFIX}-${TODAY}/$1 does not exist.  Did you input the correct date?"
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
    
    
    
    if [[ -e ${BASEDIR}/${PREFIX}-${2}/${1} ]]
      then
      echo
      echo "Extracting from ${BASEDIR}/${PREFIX}-${2}/${1}..."
      echo
      echo
      echo "Extract maps?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/proceduralmap* ; break;;
          No ) break;;
        esac
      done
      echo "Extract configs?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${2}/${1} --strip-components=2 home/${USER}/rust/lgsm/config-lgsm/rustserver/ ; tar zxvf ${BASEDIR}/${PREFIX}-${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/cfg* ; break;;
          No ) break;;
        esac
      done
    tar -tf ${BASEDIR}/${PREFIX}-${2}/${1} *home/${USER}/rust/serverfiles/oxide/* > /dev/null 2>&1
    if [[ ! "$?" == 2 ]]
      # oxide found
      then
      echo "Extract Oxide files?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/oxide/ ; break;;
          No ) break;;
        esac
      done
    fi
      echo "Extract blueprints?"
      select yn in "Yes" "No"; do
        case $yn in
          Yes ) tar zxvf ${BASEDIR}/${PREFIX}-${2}/${1} --strip-components=2 home/${USER}/rust/serverfiles/server/rustserver/player.blueprints* ; break;;
          No ) break;;
        esac
      done
    echo
    
      else
      # file doesn't exist.
      echo "Error: ${BASEDIR}/${PREFIX}-${2}/${1} does not exist.  Did you input the correct date?"
      exit 1
    fi
    # echo "Extracting from ${BASEDIR}/${PREFIX}-${2}/${1}..."
    echo
    exit
    fi # end date / file check loop
else
  echo "You need to run this file from ${HOME}; you're in ${PWD} currently."
  exit 1
  echo
fi
