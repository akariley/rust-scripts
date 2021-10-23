#!/bin/bash
rs_selfName=$(basename "$(readlink -f ${BASH_SOURCE[0]})")
rs_rootDir=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
if [[ ! -e ${rs_rootDir}/.config ]]
then
  echo ".config file does not exist.  Please copy ${rs_rootDir}/.config.example to ${rs_rootDir}/.config and configure the settings as needed."
  exit 1
else
  source ${rs_rootDir}/.config
fi

# ./wipe-script.sh [doforcewipe] [dowipeblueprints] [dorustupdate] [domodsupdate] [dolgsmupdate] [dobackup] [donewSeed] [dowipebackpacks]

# return codes
#
# 0 = no errors
# 1 = syntax error
# 2 = not running today

today=$(date +"%A")
todayAbbr=$(date +"%a")
wipeDoWipe=0
wipeDoWipeBlueprints=0
wipeDoRustUpdate=0
wipeDoModsUpdate=0
wipeDoLGSMUpdate=0
wipeDoBackup=0
wipeDoNewSeed=0
wipeDoWipeBackpacks=0
wipeDoRestartServer=0
wipeCron=0
wipeRestartReason=''

runStatus=0

wipeDoRunDay=''
wipeDay=''

numRegex='^[0-9]+$'

# let's parse the arguments
# it'll look something like ./$0 --option-1 --option-2 <rust server instance name>

while [ "$#" -gt 0 ]
do
  case ${1} in
    --do-backup)
      wipeDoBackup=1
      echo "${0}: will take a backup."
      ;;
      --new-seed)
      wipeDoNewSeed=1
      echo "${0}: will generate new seed."
      ;;
    --wipe-blueprints)
      wipeDoWipeBlueprints=1
      echo "${0}: will wipe blueprints."
      ;;
    --update-rust)
      wipeDoRustUpdate=1
      echo "${0}: will update Rust."
      ;;
    --restart-server)
      # TODO: currently broken for a multi-word restart message
      if [[ ! ${2} =~ $numRegex ]] 2>/dev/null 
      then
        echo "Error: --restart-server expects two parameters, <time in seconds> <restart message>"
        exit 1
      else
        if [ ! ${2} -gt 0 ] 2>/dev/null 
        then
          echo "Error: seconds needs to be greater than 0."
          exit 1
        else
          # $1 = --restart-server, $2 = seconds, $3- reason
          # got a valid restart time
          wipeRestartSeconds=${2}
          # grab the restart reason
          while [ ! ${3} == "@@" ]
          do
            wipeRestartReason+="${3} "
            shift
          done # end reason globbing
        fi # end greater than 0 check
      fi # end int check
      shift 2
      wipeDoRestartServer=1
      echo "${0}: will restart server in (${wipeRestartSeconds}) seconds with reason: ${wipeRestartReason}."
      ;;
    --update-mods)
      wipeDoModsUpdate=1
      echo "${0}: will update mods."
      ;;
    --wipe-backpacks)
      if [ ! -e ${installDir}/serverfiles/oxide/plugins/Backpacks.cs ]
      then
        # no backpack plugin loaded.
        echo "--wipe-backpacks entered, but no backpack plugin found.  Disabling this option."
        wipeDoWipeBackpacks=0
      else
        wipeDoWipeBackpacks=1
        echo "${0}: will wipe backpacks."
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
    --cron)
      wipeCron=1
      ;;
    *)
      # end of options with no match, assuming instance name.
      break
      ;;
  esac
  # echo "End of case loop: ${@}"
  shift
done

# echo "End of loop: ${@}"

# echo $wipeRestartReason

if [ -z ${1} ]
then
  # $1 is empty, assuming the default name
  instanceName=rustserver
else
  instanceName=${1}
fi

if [ ! -e ${installDir}/${instanceName} ]
then
  echo "Error: ${installDir}/${instanceName} does not exist."
  exit 1
else
  lgsmConfig=${installDir}/lgsm/config-lgsm/rustserver/${instanceName}.cfg
fi


if [ ${wipeCron} -eq 1 ]
then
  if [ {$wipeDoRunDay} ]
  then
    # user entered a day to --run and we're in cron mode; lets see if we're running today.
    if [[ ${wipeDoRunDay} == ${today} ]] || [[ ${wipeDoRunDay} == ${todayAbbr} ]]
    then
      # we're running today.
      runStatus=1
    else
      # not running today; exit.
      exit 2
    fi # end date check
  fi # end --run check
fi # end --cron check

# read in lgsm vars we need

if [ ! -e ${webRconCmd} ]
then
  echo "Error: webRconCmd is not set and we need it.  Aborting."
  exit 1
fi

rconIp=$(awk -F'=' '/[Ii][Pp]="?([0-9]{1,3}[\.]){3}[0-9]{1,3}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
rconPort=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Oo][Rr][Tt]="?\d{0,5}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
rconPassword=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Aa][Ss]{2}[Ww][Oo][Rr][Dd]="?[[:alnum:]]{0,63}"?/ {print $2}' ${lgsmConfig} | tr -d '"')


if [ ${execLogging} -eq 1 ]
then
  exec  >> ${fullLog} 2>&1
fi


echo "Wipe cycle start: $(date +"%c")"
touch ${installDir}/.disable_monitor


if [ ${wipeDoBackup} -eq 1 ]
then
  ${backupScript} ${instanceName} >/dev/null
  echo "Backup complete, continuing..."
fi

if [ ${wipeDoLGSMUpdate} -eq 1 ]
then
  ${installDir}/${instanceName} update-lgsm
fi

if [ ${wipeDoRustUpdate} -eq 1 ]
then
  echo "Checking for Rust update..."
  ${installDir}/${instanceName} check-update | grep -q 'Update available'
  statuscode=$?
  # echo "Status code for Rust update check was: $statuscode"
  if [[ $statuscode -eq 0 ]];
  then
    # there's a rust update
    echo "Rust update found, updating..."
    ${installDir}/${instanceName} update > /dev/null
  else
    echo "No Rust update found, proceeding..."
  fi # end rust update check
fi

if [ ${wipeDoModsUpdate} -eq 1 ]
then
  ${installDir}/${instanceName} mods-update > /dev/null
fi

#################
# wipe stuff here
#################

if [ ${wipeDoWipeBackpacks} -eq 1 ]
then
  find ${installDir}/serverfiles/oxide/data/Backpacks -type f -delete
fi


if [ ${wipeDoNewSeed} -eq 1 ]
then
  # let's get a new map seed.
  newSeed=$(shuf -i 1-2147483647 -n1)
  echo "New seed is ${newSeed}."
  sed -i "s/seed=".*"/seed="${newSeed}"/g" ${lgsmConfig}
fi # end seed check


if [ ${wipeDoWipeBlueprints} -eq 1 ]
then
  echo 'Removing blueprints...'
  /bin/rm -v ${installDir}/serverfiles/server/${instanceName}/player.blueprints.4.db
  /bin/rm -v ${installDir}/serverfiles/server/${instanceName}/player.blueprints.4.db-journal
fi

if [ ${wipeDoRestartServer} -eq 1 ]
then
  echo "Sending restart command to server via rcon..."
  timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "restart ${wipeRestartSeconds} '${wipeRestartReason}'"
  while pgrep -u $(whoami) RustDedicated > /dev/null
  do
    sleep 5
  done
  # remove lock files
  echo "Shutdown complete, proceeding." 
  find ${installDir}/lgsm/lock/ -type f -delete
fi


# start the server again
rm -vr ${installDir}/.disable_monitor
if [ ${wipeDoRestartServer} -eq 1 ]
then
  echo "Starting server."
  ${installDir}/${instanceName} start
fi
sleep 2
echo "Done!"
echo "Wipe cycle ended: $(date +"%c")"

if [ ${execLogging} -eq 1 ]
then
  sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ${fullLog}
fi
