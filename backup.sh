#!/bin/bash

# Testing

#set -euo pipefail

BASEDIR=/rust-backups
RUSTDIR=rust
PREFIX=$USER'-backup'
DIR=$PREFIX-`date +%F`
FILENAME=$PREFIX'-'`date +%H%M`
FULLNAME=${BASEDIR}/${DIR}/${FILENAME}.tar.gz

echo $DIR
echo
echo $FILENAME
echo
#echo
echo $FULLNAME

if [ $(/usr/bin/mount | grep -c ${BASEDIR}) != 1 ]
then
  # Directory not mounted... try and mount.
  /usr/bin/mount /rust-backups/ || exit 1
fi



if [[ -d ${BASEDIR}/${DIR} ]]
then
  echo "Directory ${BASEDIR}/${DIR} exists."
else
  echo "Directory ${BASEDIR}${DIR} does not exist... making it."
  mkdir --mode=700 ${BASEDIR}/${DIR} || exit 1
fi

# Directory made... proceed.


echo "Making ${FULLNAME}"
#echo 'Making '$BASEDIR'test.tar.gz'
echo 
tar zcvf $FULLNAME "${HOME}/${RUSTDIR}/lgsm/config-lgsm/rustserver" "${HOME}/${RUSTDIR}/serverfiles/server/rustserver"
