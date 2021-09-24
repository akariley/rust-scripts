#!/bin/bash
#set -euo pipefail

if [ ! -e ./.config ]
then
  echo ".config file does not exist.  Please copy .config.example to .config and configure the settings as needed."
  exit 1
fi

source ./.config

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
  if pgrep RustDedicated > /dev/null
  then
    echo "Server is running; sending 'server.save' via rcon."
    RCONIP=$(grep ^ip ${LGSMCONFIG} | awk -F'=' '{print $2}' | tr -d '"')
    RCONPORT=$(grep ^rconport ${LGSMCONFIG} | awk -F'=' '{print $2}' | tr -d '"')
    RCONPASSWORD=$(grep ^rconpassword ${LGSMCONFIG} | awk -F'=' '{print $2}' | tr -d '"')
    timeout 5 ${WEBRCONCMD} ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "server.save"
    #end server run check
  fi
  # end save check
fi

echo "Making ${FULLNAME}"
${MKNICE} tar zcvf $FULLNAME "${BACKUPLIST[@]}"
echo "Done!"
