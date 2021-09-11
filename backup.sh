#!/bin/bash
#set -euo pipefail

source ./.config

FILENAME=${USER}-$(date +%Y-%b-%d-%H%M)
FULLNAME=${BACKUPDIR}/${BACKUPDIRPREFIX}/${FILENAME}.tar.gz
MKNICE='ionice -c 3'


echo "File: $FILENAME.tar.gz"
echo "Path: $FULLNAME"



#
#   ${HOME}/${RUSTDIR}/serverfiles/oxide


#
# array of directories to backup
#
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

echo "${MKNICE} tar zcvf $FULLNAME "${backuplist[@]}""




# code follows

#if [ $(/usr/bin/mount | grep -c ${BASEDIR}) !== 1 ]
#  then
#  # Directory not mounted... try and mount.
#  ${MKNICE} /usr/bin/mount /game-backups/ || exit 1
#fi

if [[ -d ${BACKUPDIR}/${BACKUPDIRPREFIX}/ ]]
  then
  echo "Directory ${BACKUPDIR}/${BACKUPDIRPREFIX}/ exists."
else
  echo "Directory ${BACKUPDIR}/${BACKUPDIRPREFIX}/ does not exist... making it."
  echo "${MKNICE} mkdir -p --mode=700 ${BACKUPDIR}/${BACKUPDIRPREFIX}/"
fi
# Directory made... proceed.

exit 1

# check if the server is running; if so, save.
if pgrep RustDedicated > /dev/null
# server is running
then
  timeout 5 /usr/bin/webrcon-cli ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "server.save"
fi

sleep 2
echo "Making ${FULLNAME}"
${MKNICE} tar zcvf $FULLNAME "${backuplist[@]}"
