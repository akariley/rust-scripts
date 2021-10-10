#!/bin/bash

if [ ! -e ./.config ]
then
  echo ".config file does not exist.  Please copy .config.example to .config and configure the settings as needed."
  exit 1
fi

source ./.config

# ./wipe-script.sh [doforcewipe] [dowipeblueprints] [dorustupdate] [domodsupdate] [dolgsmupdate] [dobackup] [donewseed] [dowipebackpacks]

# return codes
#
# 0 = no errors
# 1 = syntax error
# 2 = not running today

today=$(date +"%A")
todayAbbr=$(date +"%a")
wipeDoForceWipe=0
wipeDoWipeBlueprints=0
wipeDoRustUpdate=0
wipeDoModsUpdate=0
wipeDoLGSMUpdate=0
wipeDoBackup=0
wipeDoNewSeed=0
wipeDoWipeBackpacks=0
wipeDoRestartServer=0
runStatus=0

wipeDoRunDay=''
wipeDay=''



# let's parse the arguments 
# it'll look something like ./$0 --option-1 --option-2 <rust server instance name>

while [ "$#" -gt 0 ]
do
  case ${1} in
    --new-seed)
      wipeDoNewSeed=1
      ;;
    --wipe-blueprints)
      wipeDoWipeBlueprints=1
      ;;
    --update-rust)
      wipeDoRustUpdate=1
      ;;
    --restart-server)
      wipeDoRestartServer=1
      ;;
    --update-mods)
      wipeDoModsUpdate=1
      ;;
    --wipe-backpacks)
      if [ ! -e ${INSTALLDIR}/serverfiles/oxide/plugins/Backpacks.cs ]
      then
        # no backpack plugin loaded.
        echo "--wipe-backpacks entered, but no backpack plugin found.  Disabling this option."
        wipeDoWipeBackpacks=0
      else
        wipeDoWipeBackpacks=1
      fi # end backpack check
      ;;
    --run)
      if [ "$2" ]
      then
        wipeDoRunDay=$2
        shift
      else
        echo "Error: --run requires a value."
        exit 1
      fi
      ;;
    *)
      # TODO: finish this.
      # Currently we just empty the rest of the arguments except the instance.
      echo "Warning: unknown option: ${1}, disregarding."
      ;;
  esac
  echo "End of case loop: ${@}"
  shift
done

echo "End of loop: ${@}"

# TODO: remove
wipeDoForceWipe=1

if [ {$wipeDoRunDay} ]
then
  # user entered a day to --run; lets see if we're running today.
  if [[ ${wipeDoRunDay} == ${today} ]] || [[ ${wipeDoRunDay} == ${todayAbbr} ]]
  then
    # we're running today.
    runStatus=1
  else
    # not running today; exit.
    exit 2
  fi
fi

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

# read in lgsm vars we need
# TODO: validate these: https://askubuntu.com/questions/367136/how-do-i-read-a-variable-from-a-file

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


echo "Wipe cycle start: $(date +"%c")"
touch ${INSTALLDIR}/.disable_monitor
if [ ${wipeDoRestartServer} -eq 1 ]
then
  echo "Sending restart command to server via rcon..."
  timeout 2 ${WEBRCONCMD} ${RCONIP}:${RCONPORT} ${RCONPASSWORD} "restart ${RESTARTSECONDS} 'weekly restart'"
  while pgrep -u $(whoami) RustDedicated > /dev/null
  do
    sleep 60
  done
  # remove lock files
  echo "Shutdown complete, proceeding." 
  find ${INSTALLDIR}/lgsm/lock/ -type f -delete
fi

if [ ${wipeDoBackup} -eq 1 ]
then
  ${SCRIPTDIR}/backup.sh
fi

if [ ${wipeDoLGSMUpdate} -eq 1 ]
then
  ${INSTALLDIR}/${instanceName} update-lgsm
fi

if [ ${wipeDoRustUpdate} -eq 1 ]
then
  echo "Checking for Rust update..."
  ${INSTALLDIR}/${instanceName} check-update | grep -q 'Update available'
  statuscode=$?
  #echo "Status code for Rust update check was: $statuscode"
  if [[ $statuscode -eq 0 ]];
  then
    # there's a rust update
    echo "Rust update found, updating..."
    ${INSTALLDIR}/${instanceName} update > /dev/null
  else
    echo "No Rust update found, proceeding..."
  fi # end rust update check
fi

if [ ${wipeDoModsUpdate} -eq 1 ]
then
  ${INSTALLDIR}/${instanceName} mods-update > /dev/null
fi

if [ ${wipeDoForceWipe} -eq 1 ]
then
  # check for backpacks.

  if [ ! -e ${INSTALLDIR}/serverfiles/oxide/plugins/Backpacks.cs ]
  then
    # no backpack plugin loaded.
    wipeDoWipeBackpacks=0
  fi # end backpack check
  

  if [ ${wipeDoNewSeed} -eq 1 ]
  then
    # let's get a new map seed.
    newseed=$(shuf -i 1-2147483647 -n1)
    echo "New seed is ${newseed}."
    sed -i "s/seed=".*"/seed="${newseed}"/g" ${LGSMCONFIG}
  else
    echo "Not changing seed."
  fi # end seed check


  if [ ${wipeDoWipeBlueprints} -eq 1 ]
  then
    echo 'Starting full wipe...'
    ${INSTALLDIR}/${instanceName} full-wipe
    if [ ${wipeDoWipeBackpacks} -eq 1 ]
    then
      find ${INSTALLDIR}/serverfiles/oxide/data/Backpacks -type f -delete
    fi
  else
    echo 'Starting normal wipe...'
    ${INSTALLDIR}/${instanceName} wipe
    if [ ${wipeDoWipeBackpacks} -eq 1 ]
    then
      find ${INSTALLDIR}/serverfiles/oxide/data/Backpacks -type f -delete
    fi
  fi # end month check
fi

# start the server again
rm -vr ${INSTALLDIR}/.disable_monitor
if [ ${wipeDoRestartServer} -eq 1 ]
then
  echo "Starting server."
  ${INSTALLDIR}/${instanceName} start
fi

sleep 2
echo "Done!"
echo "Wipe cycle ended: $(date +"%c")"

if [ ${EXECLOGGING} -eq 1 ]
then
  sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ${FULLLOG}
fi
