#!/bin/bash
#set -euo pipefail

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

FILENAME=${USER}-$(date +%Y-%b-%d-%H%M)
FULLNAME=${BACKUPDIR}/${BACKUPDIRPREFIX}/${FILENAME}.tar.gz
MKNICE='ionice -c 3'


echo "File: $FILENAME.tar.gz"
echo "Path: $FULLNAME"

backuplist=(
  ${INSTALLDIR}/lgsm/config-lgsm/rustserver
  ${INSTALLDIR}/serverfiles/server/rustserver
  ${INSTALLDIR}/log/console
)

excludelist=(
)


if [[ -d ${INSTALLDIR}/serverfiles/oxide ]]
  then
  backuplist+=(
    ${INSTALLDIR}/serverfiles/oxide
  )
fi

# code follows

if [[ -d ${BACKUPDIR}/${BACKUPDIRPREFIX}/ ]]
  then
  echo "Directory ${BACKUPDIR}/${BACKUPDIRPREFIX}/ exists."
else
  echo "Directory ${BACKUPDIR}/${BACKUPDIRPREFIX}/ does not exist... making it."
  echo "${MKNICE} mkdir -p --mode=700 ${BACKUPDIR}/${BACKUPDIRPREFIX}/"
fi
# Directory made... proceed.
if [ ${SAVEONBACKUP} -eq 1 ]
then
  # do a server.save first
  if pgrep RustDedicated > /dev/null
  then
    RCONIP=$(grep ^ip ${LGSMCONFIG} | awk -F'=' '{print $2}' | tr -d '"')
    RCONPORT=$(grep ^rconport ${LGSMCONFIG} | awk -F'=' '{print $2}' | tr -d '"')
    RCONPASSWORD=$(grep ^rconpassword ${LGSMCONFIG} | awk -F'=' '{print $2}' | tr -d '"')
    echo "timeout 5 ${WEBRCONCMD} ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "server.save""
    #end server run check
  fi
  # end save check
fi

echo "Making ${FULLNAME}"
echo "${MKNICE} tar zcvf $FULLNAME "${backuplist[@]}""

