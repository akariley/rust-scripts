#!/bin/bash

USER=rust-pve
MONTH=$(date +"%-m")

touch /home/${USER}/rust/.disable_monitor
timeout 2 /usr/bin/webrcon-cli <ip>:<port> <password> "restart 3600 'weekly restart'"
while pgrep RustDedicated > /dev/null
do
  sleep 60
done
# remove lock files
find /home/${USER}/rust/lgsm/lock/ -type f -delete
/home/${USER}/rust/backup.sh
#/home/${USER}/rust/rustserver update-lgsm
/home/${USER}/rust/rustserver update > /dev/null
/home/${USER}/rust/rustserver mods-update > /dev/null
# we need to see if this is the first Thursday of the month.
if [ $(date +\%d) -le 07 ]
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
  else
    echo 'Starting normal wipe...'
    /home/${USER}/rust/rustserver wipe
  fi
fi
rm -vr /home/${USER}/rust/.disable_monitor
/home/${USER}/rust/rustserver start
sleep 10
taskset -cp 0 $(pgrep RustDedicated)