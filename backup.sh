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

if [ ! -e ${INSTALLDIR}/${instanceName} ]
then
  echo "Error: ${INSTALLDIR}/${instanceName} does not exist."
  exit 1
else
  LGSMCONFIG=${INSTALLDIR}/lgsm/config-lgsm/${instanceName}/${instanceName}.cfg
fi


if [ ${SAVEONBACKUP} -eq 1 ]
then
  # check if webrcon is valid.
  if [ ! -e ${WEBRCONCMD} ]
  then
    echo "Warning: SAVEONBACKUP is true, but WEBRCONCMD isn't a valid path.  Disabling SAVEONBACKUP for this run."
    SAVEONBACKUP=0
  fi
  # check if LGSMCONFIG is filled out.
  if [ ! -e ${LGSMCONFIG} ]
  then
    echo "Warning: SAVEONBACKUP is true, but LGSMCONFIG isn't a valid path.  Disabling SAVEONBACKUP for this run."
    SAVEONBACKUP=0
  fi
  # end sanity checks.
fi

FILENAME=${USER}-${BACKUPDATE}

if [ -z ${BACKUPDIRSUFFIX} ]
then
  #no prefix so omit the var
  FULLNAME=${BACKUPDIR}/${FILENAME}.tar.gz
else
  FULLNAME=${BACKUPDIR}/${BACKUPDIRSUFFIX}/${FILENAME}.tar.gz
fi

MKNICE='ionice -c 3'

# code follows

if [[ -d ${BACKUPDIR}/${BACKUPDIRSUFFIX}/ ]]
  then
  echo "Directory ${BACKUPDIR}/${BACKUPDIRSUFFIX}/ exists."
else
  echo "Directory ${BACKUPDIR}/${BACKUPDIRSUFFIX}/ does not exist... making it."
  ${MKNICE} mkdir -p --mode=700 ${BACKUPDIR}/${BACKUPDIRSUFFIX}/
fi
# Directory made... proceed.
if [ ${SAVEONBACKUP} -eq 1 ]
then
  # do a server.save first
  # check if the server is running.
  if pgrep -u $(whoami) RustDedicated > /dev/null
  then
    echo "Server is running; sending 'server.save' via rcon."
    RCONIP=$(awk -F'=' '/[Ii][Pp]="?([0-9]{1,3}[\.]){3}[0-9]{1,3}"?/ {print $2}' ${LGSMCONFIG} | tr -d '"')
    RCONPORT=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Oo][Rr][Tt]="?\d{0,5}"?/ {print $2}' ${LGSMCONFIG} | tr -d '"')
    RCONPASSWORD=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Aa][Ss]{2}[Ww][Oo][Rr][Dd]="?[[:alnum:]]{0,63}"?/ {print $2}' ${LGSMCONFIG} | tr -d '"')
    timeout 5 ${WEBRCONCMD} ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "server.save"
    #end server run check
  fi
  # end save check
fi

echo "Making ${FULLNAME}"
${MKNICE} tar zcvf $FULLNAME "${BACKUPLIST[@]}"
echo "Done!"
