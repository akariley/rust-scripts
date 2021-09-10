#!/bin/bash

USER=rust-pve-2
MONTH=$(date +"%-m")
LOGDATE=$(date +"%m-%d-%Y-%s")
LOGFILE=weekly-tasks_${LOGDATE}.log
FULLLOG=/home/${USER}/rust/log/${LOGFILE}

# read in lgsm vars we need
# TODO: validate these: https://askubuntu.com/questions/367136/how-do-i-read-a-variable-from-a-file

source ./.config

RCONIP=$(grep ^ip ${LGSMCONFIG})
RCONPORT=$(grep ^rconport ${LGSMCONFIG})
RCONPASSWORD=$(grep ^rconpassword ${LGSMCONFIG})

exit 255
exec  >> ${FULLLOG} 2>&1

echo "Restart cycle start: $(date +"%c")"
touch /home/${USER}/rust/.disable_monitor
echo "Sending restart command to server via rcon..."
timeout 2 /usr/bin/webrcon-cli ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "restart 3600 'weekly restart'"
while pgrep RustDedicated > /dev/null
do
  sleep 60
done
# remove lock files
echo "Shutdown complete, proceeding." 
find /home/${USER}/rust/lgsm/lock/ -type f -delete
#/home/${USER}/rust/backup.sh
#/home/${USER}/rust/rustserver update-lgsm
#/home/${USER}/rust/rustserver update > /dev/null
#/home/${USER}/rust/rustserver mods-update > /dev/null
# we need to see if this is the first Thursday of the month.
# TODO: https://stackoverflow.com/questions/24777597/value-too-great-for-base-error-token-is-08
# HACK
#
#
if [ $(date +\%d) -le 07 ] && [ 1 -eq 2 ]
then
  # we're doing the wipe today.
  # let's get a new map seed.
  newseed=$(shuf -i 1-2147483647 -n1)
  echo "New seed is ${newseed}."
  sed -i "s/seed=".*"/seed="${newseed}"/g" /home/${USER}/rust/lgsm/config-lgsm/rustserver/rustserver.cfg
  # are we doing a blueprint wipe?
  if [[ $MONTH%2 -eq 1 ]];
  then
    # odd month so we're doing a BP wipe
    echo 'Starting full wipe...'
    /home/${USER}/rust/rustserver full-wipe
    find /home/${USER}/rust/serverfiles/oxide/data/Backpacks -type f -delete
  else
    echo 'Starting normal wipe...'
    /home/${USER}/rust/rustserver wipe
    find /home/${USER}/rust/serverfiles/oxide/data/Backpacks -type f -delete
  fi
fi
#rm -vr /home/${USER}/rust/.disable_monitor
echo "Starting server."
#/home/${USER}/rust/rustserver start
sleep 10
echo "Setting affinity..."
#taskset -cp 1 $(pgrep RustDedicated)

echo "Done!"
echo "Restart cycle ended: $(date +"%c")"
sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ${FULLLOG}
