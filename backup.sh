#!/bin/bash
#set -euo pipefail
BASEDIR=/game-backups
RUSTDIR=rust
DIR=${USER}/$(date +%m)
FILENAME=${USER}-$(date +%Y-%b-%d-%H%M)
FULLNAME=${BASEDIR}/${DIR}/${FILENAME}.tar.gz
MKNICE='ionice -c 3'

source ./.config

echo $FILENAME.tar.gz
echo $FULLNAME



#
#   ${HOME}/${RUSTDIR}/serverfiles/oxide


#
# array of directories to backup
#
backuplist=(
  ${HOME}/${RUSTDIR}/lgsm/config-lgsm/rustserver
  ${HOME}/${RUSTDIR}/serverfiles/server/rustserver
  ${HOME}/${RUSTDIR}/log/console
)


excludelist=(
)


if [[ -d ${HOME}/${RUSTDIR}/serverfiles/oxide ]]
  then
  backuplist+=(
    ${HOME}/${RUSTDIR}/serverfiles/oxide
  )
fi

echo "${MKNICE} tar zcvf $FULLNAME "${backuplist[@]}""

exit 1


# code follows

if [ $(/usr/bin/mount | grep -c ${BASEDIR}) !== 1 ]
  then
  # Directory not mounted... try and mount.
  ${MKNICE} /usr/bin/mount /game-backups/ || exit 1
fi

if [[ -d ${BASEDIR}/${DIR} ]]
  then
  echo "Directory ${BASEDIR}/${DIR} exists."
else
  echo "Directory ${BASEDIR}/${DIR} does not exist... making it."
  ${MKNICE} mkdir -p --mode=700 ${BASEDIR}/${DIR} || exit 1
fi
# Directory made... proceed.

# check if the server is running; if so, save.
if pgrep RustDedicated > /dev/null
# server is running
then
  timeout 5 /usr/bin/webrcon-cli ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "server.save"
fi

sleep 2
echo "Making ${FULLNAME}"
${MKNICE} tar zcvf $FULLNAME "${backuplist[@]}"
