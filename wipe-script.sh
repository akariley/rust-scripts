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

function show_Help {
  echo "${rs_selfName} [option-name] [option-name...] instanceName"
  echo
  #echo "${rs_selfName} accepts multiple options, listed below:"
  echo "  --wipe-map"
  echo "    Will delete all *.sav and *.map files in the specified LGSM instance."
  echo "    (disabled on specified forcewipe days (currently every first Thursday of the month"
  echo "    use --force-wipe to run this on forcewipe days)"
  echo "  --force-wipe"
  echo "    Implies --new-seed, --update-rust, and --update-mods."
  echo "    Will exit completely if not a force wipe day."
  echo "  --new-seed"
  echo "    Will generate a new map seed and update the specified LGSM config."
  echo "  --update-rust"
  echo "    Will update Rust."
  echo "  --update-mods"
  echo "    Will update uMod."
  echo "  --wipe-blueprints [odd|even|now]"
  echo "    Will remove the blueprint files, based on the required option."
  echo "    (eg: if the month is divisible by two and 'even' is passed, blueprints would be wiped)."
  echo "  --restart-server <restart time in seconds> <restart reason>"
  echo "    Will restart the server when done."
  echo "    Restart reason can be multiple words; string must be terminated with '@@'"
  echo "    (requires valid webRconCmd setting in .config)."
  echo "  --update-lgsm"
  echo "    Will update LGSM."
  echo "  --do-backup"
  echo "    Will take a backup."
  #echo "  --cron"
  #echo "    Enables cronjob mode.  Useful if you want to run a command at a specific time."
  #echo "    Requires '--run'."




  exit





}


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

if [[ -z ${1} ]]
then
  show_Help
fi

# let's parse the arguments
# it'll look something like ./$0 --option-1 --option-2 <rust server instance name>

while [[ "$#" -gt 0 ]]
do
  case ${1} in
    --do-backup)
      if [[ -z ${rs_rootDir}/${backupScript} ]]
      then
        echo "Error: backupScript not set in .config."
        exit 1
      else
        if [[ ! -e ${rs_rootDir}/${backupScript} ]]
        then
          echo "Error: backupScript not a valid path."
          exit 1
        fi
      fi
      wipeDoBackup=1
      echo "${rs_selfName}: will take a backup."
      ;;
      --new-seed)
      wipeDoNewSeed=1
      echo "${rs_selfName}: will generate new seed."
      ;;
    --wipe-blueprints)
      # possible options: odd, even, or now.
      if [[ ${2} == 'odd' ]] && [[ ${month}%2 -eq 1 ]] || [[ ${2} == 'now' ]]
      then
        # param is 'odd' and it's an odd month, run.
        wipeDoWipeBlueprints=1
        echo "${rs_selfName}: will wipe blueprints."
      else
        if [[ ${2} == 'even' ]] && [[ ${month}%2 -eq 0 ]] || [[ ${2} == 'now' ]]
        then
          # param is 'even' and it's an even month, run.
          wipeDoWipeBlueprints=1
          echo "${rs_selfName}: will wipe blueprints."
        fi # end even check
      fi # end odd check
      shift
      ;;
    --wipe-map)
      # # we need to check if we can run today.
      # #if [[ ${forceWipeDay} == $(date +%d) ]]
      # if [[ ${allowWipeMapOnForceWipe} -eq 0 ]]
      # then
      #   # --wipe-map is disabled on first Thursdays of the month.
      #   # let's see if this is one of them.
      #   if [[ $(date +%w) -eq 4 ]] && [[ $(date +%-d) -lt 7 ]]
      #   then
      #     echo "${rs_selfName}: --wipe-map specified, but today is a defined force wipe day.  Ignoring for this run."
      #     echo "(change allowWipeMapOnForceWipe to '1' to disable this check)."
      #     wipeDoWipe=0
      #   else
      #     echo "${rs_selfName}: will wipe map (not blueprints)."
          # wipeDoWipe=1
      #   fi # end date check
      # else
        echo "${rs_selfName}: will wipe map (not blueprints)."
        wipeDoWipe=1
      # fi # end force wipe check.
      ;;
    --force-wipe)
      # if [[ $(date +%w) -eq 4 ]] && [[ $(date +%-d) -lt 7 ]]
      # then
        wipeDoNewSeed=1
        echo "${rs_selfName}: will generate new seed."
        wipeDoModsUpdate=1
        echo "${rs_selfName}: will update mods."
        wipeDoRustUpdate=1
        echo "${rs_selfName}: will update Rust."
        wipeDoWipe=1
        echo "${rs_selfName}: will wipe map (not blueprints)."
      # else
        # not a defined force wipe day; exit.
      #   exit 2
      # fi
      ;;
    --wipe-backpacks)
      if [[ ! -e ${installDir}/serverfiles/oxide/plugins/Backpacks.cs ]]
      then
        # no backpack plugin loaded.
        echo "--wipe-backpacks entered, but no backpack plugin found.  Disabling this option."
        wipeDoWipeBackpacks=0
      else
        wipeDoWipeBackpacks=1
        echo "${rs_selfName}: will wipe backpacks."
      fi # end backpack check
      ;;
    --restart-server)
      if [[ ! ${2} =~ $numRegex ]] 2>/dev/null 
      then
        echo "Error: --restart-server expects two parameters, <time in seconds> <restart message>"
        exit 1
      else
        if [[ ! ${2} -gt 0 ]] 2>/dev/null 
        then
          echo "Error: seconds needs to be greater than 0."
          exit 1
        else
          # $1 = --restart-server, $2 = seconds, $3- reason
          # got a valid restart time
          wipeRestartSeconds=${2}
          # grab the restart reason
          while [[ ! ${3} == "@@" ]]
          do
            wipeRestartReason+="${3} "
            shift
          done # end reason globbing
        fi # end greater than 0 check
      fi # end int check
      shift 2
      wipeDoRestartServer=1
      echo "${rs_selfName}: will restart server in (${wipeRestartSeconds}) seconds with reason: ${wipeRestartReason}."
      ;;
    --update-mods)
      wipeDoModsUpdate=1
      echo "${rs_selfName}: will update mods."
      ;;
    --update-rust)
      wipeDoRustUpdate=1
      echo "${rs_selfName}: will update Rust."
      ;;
    --update-lgsm)
      wipeDoLGSMUpdate=1
      echo "${rs_selfName}: will update LGSM."
      ;;
    --run)
      if [[ ! -z "${2}" ]]
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
      # end of options with no match, move out of loop.
      break
      ;;
  esac
  shift
done

if [[ -z ${1} ]]
then
  # we're out of the loop and we processed some options; there should be a parameter.
  echo "Error: you must specify an instance name."
  show_Help
fi

if [[ ! -e ${installDir}/${1} ]]
then
  echo "Error: ${1} is not a valid instance name."
  show_Help
  exit 1
else
  lgsmConfig=${installDir}/lgsm/config-lgsm/rustserver/${1}.cfg
  instanceName=${1}
fi


if [[ ${wipeCron} -eq 1 ]]
then
  if [[ {$wipeDoRunDay} ]]
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

if [[ ! -e ${webRconCmd} ]]
then
  echo "Error: webRconCmd is not set and we need it.  Aborting."
  exit 1
fi

rconIp=$(awk -F'=' '/[Ii][Pp]="?([0-9]{1,3}[\.]){3}[0-9]{1,3}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
rconPort=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Oo][Rr][Tt]="?\d{0,5}"?/ {print $2}' ${lgsmConfig} | tr -d '"')
rconPassword=$(awk -F'=' '/^[Rr][Cc][Oo][Nn][Pp][Aa][Ss]{2}[Ww][Oo][Rr][Dd]="?[[:alnum:]]{0,63}"?/ {print $2}' ${lgsmConfig} | tr -d '"')


if [[ ${execLogging} -eq 1 ]]
then
  exec  >> ${fullLog} 2>&1
fi

echo "Sleeping for 5 seconds...(ctrl+c to cancel)"
sleep 5
echo "Wipe cycle start: $(date +"%c")"

if [[ ${wipeDoRestartServer} -eq 1 ]]
then
  echo "Sending restart command to server via rcon..."
  timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "restart ${wipeRestartSeconds} '${wipeRestartReason}'"
  while [[ -e ${installDir}/lgsm/lock/${instanceName}.lock ]]
  do
    sleep 5
  done
  echo "Shutdown complete, proceeding." 
fi

if [[ ${wipeDoBackup} -eq 1 ]]
then
  ${rs_rootDir}/${backupScript} ${instanceName}
  echo "Backup complete, continuing..."
fi

if [[ ${wipeDoLGSMUpdate} -eq 1 ]]
then
  ${installDir}/${instanceName} update-lgsm
fi

if [[ ${wipeDoRustUpdate} -eq 1 ]]
then
  echo "Checking for Rust update..."
  ${installDir}/${instanceName} check-update | grep -q 'Update available'
  statuscode=$?
  if [[ $statuscode -eq 0 ]];
  then
    # there's a rust update
    echo "Rust update found, updating..."
    ${installDir}/${instanceName} update > /dev/null
  else
    echo "No Rust update found, proceeding..."
  fi # end rust update check
fi

if [[ ${wipeDoModsUpdate} -eq 1 ]]
then
  ${installDir}/${instanceName} mods-update > /dev/null
fi

###################
# wipe stuff here #
###################

if [[ ${wipeDoWipe} -eq 1 ]]
then
  # we're wiping today.
  echo "Removing map files..."
  rm -f ${installDir}/serverfiles/server/${instanceName}/*.map > /dev/null
  rm -f ${installDir}/serverfiles/server/${instanceName}/*.sav* > /dev/null
fi



if [[ ${wipeDoWipeBackpacks} -eq 1 ]]
then
  find ${installDir}/serverfiles/oxide/data/Backpacks -type f -delete
fi


if [[ ${wipeDoNewSeed} -eq 1 ]]
then
  # let's get a new map seed.
  newSeed=$(shuf -i 1-2147483647 -n1)
  echo "New seed is ${newSeed}."
  sed -i "s/seed=".*"/seed="${newSeed}"/g" ${lgsmConfig}
fi # end seed check


if [[ ${wipeDoWipeBlueprints} -eq 1 ]]
then
  echo 'Removing blueprints...'
  /bin/rm -v ${installDir}/serverfiles/server/${instanceName}/player.blueprints.4.db
  /bin/rm -v ${installDir}/serverfiles/server/${instanceName}/player.blueprints.4.db-journal
fi

# if [[ ${wipeDoRestartServer} -eq 1 ]]
# then
#   echo "Sending restart command to server via rcon..."
#   timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "restart ${wipeRestartSeconds} '${wipeRestartReason}'"
#   while [[ -e ${installDir}/lgsm/lock/${instanceName}.lock ]]
#   do
#     sleep 5
#   done
#   echo "Shutdown complete, proceeding." 
# fi


# start the server again
if [[ ${wipeDoRestartServer} -eq 1 ]]
then
  echo "Starting server."
  ${installDir}/${instanceName} start
fi
sleep 2
echo "Done!"
echo "Wipe cycle ended: $(date +"%c")"

if [[ ${execLogging} -eq 1 ]]
then
  sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ${fullLog}
fi
