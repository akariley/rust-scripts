#!/bin/bash
rs_selfName=$(basename "$(readlink -f ${BASH_SOURCE[0]})")
rs_rootDir=$(dirname "$(readlink -f ${BASH_SOURCE[0]})")
if [[ ! -e ${rs_rootDir}/.rs.config ]]
then
  echo "Config file does not exist.  Please copy ${rs_rootDir}/.rs.config.example to ${rs_rootDir}/.rs.config and configure the settings as needed."
  exit 1
else
  source ${rs_rootDir}/.rs.config
fi


today=$(date +"%A")
todayAbbr=$(date +"%a")
wipeDoWipe=0
wipeDoWipeBlueprints=0
wipeDoRustUpdate=0
wipeDoModsUpdate=0
wipeDoLGSMUpdate=0
wipeDoBackup=0

wipeDoNewSeed=0
newSeedValue=-1
customSeedFile=

wipeDoWipeBackpacks=0
wipeDoRestartServer=0
wipeCron=0
wipeRestartReason=''

runStatus=0

wipeDoRunDay=''
wipeDay=''

doInfiniteLoop=0

numRegex='^[0-9]+$'


function script_exit {
  rm -f $tmpFile
  if [[ ${wipeDoNewSeed} -eq 1 ]] && [[ ! -z ${customSeedFile} ]]
  then
    sed -i "/^${newSeedValue}/d" ${customSeedFile}
  fi # end seed check
  # We need to abort a restart in case of an script interrupt (running via command line).
  # There's no issue with aborting a non-existing restart process.
  if [[ -e ${webRconCmd} ]]
  then
    # We've got a webrconcli binary instead of 'lgsm stop', use that.
    #timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "restart -1" > /dev/null 2>&1
    #sleep 2
    echo ''

  fi
}

trap script_exit exit

function show_Help {
  exit
  echo "${rs_selfName} [option-name] [option-name...] instanceName"
  echo
  echo "  The last parameter MUST be an instance name."
  echo
  echo "  --wipe-map"
  echo "    Will delete all *.sav and *.map files in the specified LGSM instance."
  echo "  --force-wipe"
  echo "    Implies --update-rust, --update-mods, and --wipe-map."
  echo "  --new-seed [<seedfile.txt>|random]"
  echo "    Will generate a new map seed and update the specified LGSM config."
  echo "    Use seedfile.txt to use the next seed from a given file, seed is deleted on use.  Will use a random seed if file is empty."
  echo "    'random' will generate a random seed."
  echo "  --update-rust"
  echo "    Will update Rust."
  echo "  --update-mods"
  echo "    Will update uMod."
  echo "  --wipe-blueprints [odd|even|now]"
  echo "    Will remove the blueprint files, based on the required option."
  echo "    (eg: if the month is divisible by two and 'even' is passed, blueprints will be wiped)."
  echo "  --wipe-backpacks"
  echo "    Will delete all backpack data from the default location (serverfiles/oxide/data/Backpacks)"
  echo "  --restart-server <restart time in seconds> <restart reason>"
  echo "    Will restart the server when done."
  echo "    Restart reason can be multiple words; string must be quoted."
  echo "    (requires valid webRconCmd setting in .rs.config)."
  echo "  --update-lgsm"
  echo "    Will update LGSM."
  echo "  --do-backup"
  echo "    Will take a backup."
  exit
}


# return codes
#
# 0 = no errors
# 1 = syntax error
# 2 = parameter error



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
        echo "Error: backupScript not set in .rs.config."
        #exit 1
      else
        if [[ ! -e ${rs_rootDir}/${backupScript} ]]
        then
          echo "Error: backupScript not a valid path."
          #exit 1
        fi
      fi
      wipeDoBackup=1
      echo "${rs_selfName}: will take a backup."
      ;;
    --new-seed)
      if [[ -e ${rs_rootDir}/${2} ]]
      then
        # Pull the next seed.
        newSeedValue=$(egrep '^[0-9]+$' ${rs_rootDir}/${2} | head -n 1)
        if [[ -z ${newSeedValue} ]]
        then
          # no seed returned, make a random one
          newSeedValue=$(shuf -i 1-2147483647 -n1)
          echo "${rs_selfName}: using random seed (${newSeedValue}) due to no valid seeds in ${rs_rootDir}/${2}."
        else
          # seed returned
          echo "${rs_selfName}: will use '${newSeedValue}' as new seed from ${rs_rootDir}/${2}."
          customSeedFile=${rs_rootDir}/${2}
        fi
      else
        if [[ ${2} == 'random' ]]
        then
          newSeedValue=$(shuf -i 1-2147483647 -n1)
          echo "${rs_selfName}: using random seed -- ${newSeedValue}."
        else
          newSeedValue=$(shuf -i 1-2147483647 -n1)
          echo "${rs_selfName}: using random seed (${newSeedValue}) due to invalid seed file (${rs_rootDir}/${2})."
        fi
      fi
      wipeDoNewSeed=1
      shift
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
        echo "${rs_selfName}: will wipe map (not blueprints)."
        wipeDoWipe=1
      ;;
    --force-wipe)
        wipeDoModsUpdate=1
        echo "${rs_selfName}: will update mods (--force-wipe)."
        wipeDoRustUpdate=1
        echo "${rs_selfName}: will update Rust (--force-wipe)."
        wipeDoWipe=1
        echo "${rs_selfName}: will wipe map (--force-wipe)."
      ;;
    --wipe-backpacks)
      if [[ ! -d ${installDir}/serverfiles/oxide/data/Backpacks ]]
      then
        # no backpack data found.
        echo "--wipe-backpacks entered, but no backpack data found.  Disabling this option."
        wipeDoWipeBackpacks=0
      else
        wipeDoWipeBackpacks=1
        echo "${rs_selfName}: will wipe backpacks."
      fi # end backpack check
      ;;
    --restart-server)
      if [[ ! ${2} =~ $numRegex ]] 2>/dev/null 
      then
        echo "Error: --restart-server expects two parameters, <time in seconds> <restart message>.  The restart message must be quoted."
        #exit 1
      else
        if [[ ! ${2} -gt 0 ]] 2>/dev/null 
        then
          echo "Error: seconds needs to be greater than 0."
          #exit 1
        else
          # $1 = --restart-server, $2 = seconds, $3- reason
          # got a valid restart time
          wipeRestartSeconds=${2}
          wipeRestartReason=${3}
        fi # end greater than 0 check
      fi # end int check
      shift 2
      wipeDoRestartServer=1
      if [[ ! -e ${webRconCmd} ]]
      then
        echo "Warning: webRconCmd is not set or is an invalid path.  Will shutdown server via LGSM."
      else
        echo "${rs_selfName}: will restart server in (${wipeRestartSeconds}) seconds with reason: ${wipeRestartReason}."
      fi
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
    --loop-forever)
      doInfiniteLoop=1
      ;;
    *)
      # end of options with no match, move out of loop.
      break
      ;;
  esac
  shift
done

echo ''
echo ''
echo ''

if [[ -z ${1} ]]
then
  # we're out of the loop and we processed some options; there should be a parameter.
  echo "Error: you must specify an instance name."
  if [[ ${wipeDoNewSeed} -eq 1 ]]
  then
    echo "(Did you have '--new-seed' followed by your instance name?)"
  fi
  echo ''
  show_Help
fi

if [[ ! -e ${installDir}/${1} ]]
then
  echo "Error: ${1} is not a valid instance name."
  show_Help
  #exit 1
else
  lgsmConfig=${installDir}/lgsm/config-lgsm/rustserver/${1}.cfg
  instanceName=${1}
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

exit


# we need to check for running scripts other than ours.

if [[ -e ${rs_rootDir}/tmp/${rs_selfName}* ]] || [[ -e /tmp/${rs_selfName}* ]]
then
  # there's a touch file present, abort.
  echo "Error: touch file present for ${rs_selfName}, exiting."
  exit 254
fi

tmpFile=$(createTempFile "${rs_selfName}")

if [[ ${doInfiniteLoop} -eq 1 ]]
then
  # loop forever
  echo "Looping forever, ctrl+c to exit."
  while [[ 1 -eq 1 ]]
  do
    sleep 10
  done
fi

###################
# wipe stuff here #
###################

if [[ ${wipeDoRestartServer} -eq 1 ]]
then
  if [[ ! -e ${webRconCmd} ]]
  then
    echo "Sending stop command via LGSM..."
    ${installDir}/${instanceName} stop
  else
    #
    # New code goes here.
    #
    # ${wipeRestartSeconds}
    # Likely the best intervals are 1m,10m. 30m for much higher times. 
    if [[ ${wipeRestartSeconds} -le 60 ]]
    then
      # Restart time is less than 1 minute, just send the restart command.
      echo ''
      timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "say Restarting in 0 minutes, ${wipeRestartSeconds} seconds."
      timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "restart ${wipeRestartSeconds}"
      sleep 70
    else
      # let's figure out how long this is.
      # test case for now is 2145 seconds 35 minutes, 45 seconds.
      # restart time is less than an hour but larger than a minute.
      # snag the modulo (seconds)

      wipeRestartModulo=$(( ${wipeRestartSeconds} % 60 )) # 45

      # convert to minutes
      wipeRestartMinutes=$(( ${wipeRestartSeconds} / 60 )) # 35

      # ok, let's get started.  First get the reminder out of the way.
      timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "say Restarting in ${wipeRestartMinutes} minutes, ${wipeRestartModulo} seconds."
      echo "Sleeping for ${wipeRestartModulo} seconds."
      sleep ${wipeRestartModulo}
      # Modulo gone, let's get the minutes to a multiple of 10.

      # 35 % 10 = 5
      wipeRestartLoopTimes=$(( ${wipeRestartMinutes} % 10 )) # 5
      if [[ ${wipeRestartLoopTimes} -eq ${wipeRestartMinutes} ]]
      then
        # loop is the same as minutes meaning we're less than 10 already.
        # example: initial restart seconds are 300.  That's 5 minutes.
        # 5 % 10 = 5
        # We don't need to loop to get the minutes to a multiple of 10, so we bypass this.
        wipeRestartLoopTimes=0
      fi
      [[ ! ${wipeRestartLoopTimes} -eq 0 ]] && echo "Since restart minutes is ${wipeRestartMinutes}, we're going to loop for ${wipeRestartLoopTimes} cycles."
      while [[ ${wipeRestartLoopTimes} -ge 1 ]]
      do
        # now we're going to loop off the excess minute until we're at a multiple of 10.
        wipeRestartLoopTimes=$(( ${wipeRestartLoopTimes}-1 ))
        echo "${wipeRestartLoopTimes} loop(s)."
        wipeRestartMinutes=$(( ${wipeRestartMinutes} - 1 ))
        sleep 60
      done
      echo "We're now at a multiple of 10." # 30 minutes til restart.
      while [[ ${wipeRestartMinutes} -gt 10 ]]
      do
        timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "say Restarting in ${wipeRestartMinutes} minutes."
        wipeRestartMinutes=$(( ${wipeRestartMinutes} - 10 ))
        sleep 600
      done
      # Now we're at 10 minutes.
      while [[ ${wipeRestartMinutes} -gt 1 ]]
      do
        timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "say Restarting in ${wipeRestartMinutes} minutes."
        wipeRestartMinutes=$(( ${wipeRestartMinutes} - 1 ))
        sleep 60
      done
      # 1 minute until restart, send the rcon command.
      echo "Sending restart command to server via rcon..."
      timeout 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} "restart 60 ${wipeRestartReason}" > /dev/null 2>&1
      while [[ 1 -eq 1 ]]
      do
        # server running.
        timeout --preserve-status 2 ${webRconCmd} ${rconIp}:${rconPort} ${rconPassword} 'playerlist' > /dev/null 2>&1
        if [[ ! $? -eq 143 ]]
        then
          # server is down
          echo ''
          break
        fi # end server check
        sleep 10
      done
      echo ''
    fi # end global restart logic
    # placeholder
    echo ''
  fi # end webRconCmd check
rm -vf ${installDir}/lgsm/lock/${instanceName}*.lock
fi # end main restart option.


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
  echo "Updating mods..."
  ${installDir}/${instanceName} mods-update > /dev/null
fi

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
  sed -i "s/seed=".*"/seed=\""${newSeedValue}"\"/g" ${lgsmConfig} 
fi # end seed check


if [[ ${wipeDoWipeBlueprints} -eq 1 ]]
then
  echo 'Removing blueprints...'
  /bin/rm -v ${installDir}/serverfiles/server/${instanceName}/player.blueprints.5.db
  /bin/rm -v ${installDir}/serverfiles/server/${instanceName}/player.blueprints.5.db-journal
fi


# start the server again
if [[ ${wipeDoRestartServer} -eq 1 ]]
then
  echo "Starting server..."
  ${installDir}/${instanceName} start
fi
sleep 2
echo "Done!"
echo "Wipe cycle ended: $(date +"%c")"

if [[ ${execLogging} -eq 1 ]]
then
  sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" ${fullLog}
fi
