#!/bin/bash
#set -euo pipefail
BASEDIR=/rust-backups
RUSTDIR=rust
PREFIX=$USER'-backup'
DIR=$PREFIX-`date +%F`
FILENAME=$PREFIX'-'`date +%H%M`
FULLNAME=${BASEDIR}/${DIR}/${FILENAME}.tar.gz
MKNICE='ionice -c 3'

#
#   ${HOME}/${RUSTDIR}/serverfiles/oxide


#
# array of directories to backup
#
backuplist=(
  ${HOME}/${RUSTDIR}/lgsm/config-lgsm/rustserver
  ${HOME}/${RUSTDIR}/serverfiles/server/rustserver
  ${HOME}/${RUSTDIR}/log
)

if [[ -d ${HOME}/${RUSTDIR}/serverfiles/oxide ]]
  then
  backuplist+=(
    ${HOME}/${RUSTDIR}/serverfiles/oxide
  )
fi


# echo $DIR
echo
# echo $FILENAME
# echo
# echo
# echo $FULLNAME
if [ $(/usr/bin/mount | grep -c ${BASEDIR}) != 1 ]
  then
  # Directory not mounted... try and mount.
  ${MKNICE} /usr/bin/mount /rust-backups/ || exit 1
fi
if [[ -d ${BASEDIR}/${DIR} ]]
  then
  echo "Directory ${BASEDIR}/${DIR} exists."
else
  echo "Directory ${BASEDIR}/${DIR} does not exist... making it."
  ${MKNICE} mkdir --mode=700 ${BASEDIR}/${DIR} || exit 1
fi
# Directory made... proceed.
echo "Making ${FULLNAME}"


# ${MKNICE} tar zcvf $FULLNAME "${HOME}/${RUSTDIR}/lgsm/config-lgsm/rustserver" "${HOME}/${RUSTDIR}/serverfiles/server/rustserver" "${HOME}/${RUSTDIR}/log" "${HOME}/${RUSTDIR}/serverfiles/oxide"
${MKNICE} tar zcvf $FULLNAME "${backuplist[@]}"

