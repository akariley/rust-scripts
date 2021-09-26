#!/bin/bash

if [ ! -e ./.config ]
then
  echo ".config file does not exist.  Please copy .config.example to .config and configure the settings as needed."
  exit 1
fi

source ./.config

# read in lgsm vars we need
# TODO: validate these: https://askubuntu.com/questions/367136/how-do-i-read-a-variable-from-a-file

if [ ! -e ${LGSMCONFIG} ] || [ -z ${LGSMCONFIG} ]
then
  echo "LGSMCONFIG is not set in ./.config or file does not exist.  Aborting."
  exit 1
fi 

if [ ! -e ${WEBRCONCMD} ]
then
  echo "Error: WEBRCONCMD is not set and we need it.  Aborting."
  exit 1

fi

RCONIP=$(awk -F'=' '/[Ii][Pp]="?([0-9]{1,3}[\.]){3}[0-9]{1,3}"?/ {print $2}' ${LGSMCONFIG} | tr -d '"')
RCONPORT=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Oo][Rr][Tt]="?\d{0,5}"?/ {print $2}' ${LGSMCONFIG} | tr -d '"')
RCONPASSWORD=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Aa][Ss]{2}[Ww][Oo][Rr][Dd]="?[[:alnum:]]{0,63}"?/ {print $2}' ${LGSMCONFIG} | tr -d '"')


if [ ${EXECLOGGING} -eq 1 ]
then
  exec  >> ${FULLLOG} 2>&1
fi


echo "Restart cycle start: $(date +"%c")"
touch ${INSTALLDIR}/.disable_monitor
echo "Sending restart command to server via rcon..."
timeout 2 ${WEBRCONCMD} ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "restart ${RESTARTSECONDS} 'weekly restart'"
while pgrep -u $(whoami) RustDedicated > /dev/null
do
  sleep 60
done
# remove lock files
echo "Shutdown complete, proceeding." 
find ${INSTALLDIR}/lgsm/lock/ -type f -delete
${SCRIPTDIR}/backup.sh
${INSTALLDIR}/rustserver update-lgsm
echo "Checking for Rust update..."
${INSTALLDIR}/rustserver check-update | grep -q 'Update available'
statuscode=$?
echo "Status code for Rust update check was: $statuscode"
if [[ $statuscode -eq 0 ]];
then
  # there's a rust update
  echo "Rust update found, updating..."
  ${INSTALLDIR}/rustserver update > /dev/null
fi # end rust update check
echo "No Rust update found, proceeding..."

${INSTALLDIR}/rustserver mods-update > /dev/null
# we need to see if this is the first Thursday of the month.
# TODO: https://stackoverflow.com/questions/24777597/value-too-great-for-base-error-token-is-08
#
if [ $(date +\%d) -le 07 ]
then
  # check for backpacks.
  if [ ! -e ${INSTALLDIR}/serverfiles/oxide/plugins/Backpacks.cs ]
  then
    # no backpack plugin loaded.
    WIPECLEARBACKPACKS=0
  fi
  # we're doing the wipe today.
  # let's get a new map seed.
  newseed=$(shuf -i 1-2147483647 -n1)
  echo "New seed is ${newseed}."
  sed -i "s/seed=".*"/seed="${newseed}"/g" ${LGSMCONFIG}
  # are we doing a blueprint wipe?
  if [[ $MONTH%2 -eq 1 ]];
  then
    # odd month so we're doing a BP wipe
    echo 'Starting full wipe...'
    ${INSTALLDIR}/rustserver full-wipe
    if [ ${WIPECLEARBACKPACKS} -eq 1 ]
    then
      find ${INSTALLDIR}/serverfiles/oxide/data/Backpacks -type f -delete
    fi
  else
    echo 'Starting normal wipe...'
    ${INSTALLDIR}/rustserver wipe
    if [ ${WIPECLEARBACKPACKS} -eq 1 ]
    then
      find ${INSTALLDIR}/serverfiles/oxide/data/Backpacks -type f -delete
    fi
  fi # end month check
fi # end main wipe check

# start the server again
rm -vr ${INSTALLDIR}/.disable_monitor
echo "Starting server."
${INSTALLDIR}/rustserver start
sleep 10
echo "Setting affinity..."
taskset -cp 1 $(pgrep -u $(whoami) RustDedicated)

echo "Done!"
echo "Restart cycle ended: $(date +"%c")"

if [ ${EXECLOGGING} -eq 1 ]
then
  sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ${FULLLOG}
fi
