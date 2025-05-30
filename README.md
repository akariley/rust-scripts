# Scripts for Rust (game)

These scripts are intended to ease your wipe days for [Rust](https://rust.facepunch.com) servers and generate smaller backups than the stock [LGSM](https://linuxgsm.com/lgsm/) backups by only backing up the map/sav files as opposed to the entire install.

## Requirements
- [LGSM](https://linuxgsm.com/lgsm/)
- [webrcon-cli](https://www.npmjs.com/package/webrcon-cli) (optional, but highly recommended)

### Usage

Ideally you'll want to set a cron for the wipe script to specify the day, and then use an `if` to execute on a wipe day.  For example, my force map cron looks like this:
```
0 13 * * 4 if [[ $(date +\%-d) -le 7 ]]; then sleep 20; ./rust-scripts/rs-wipe-script.sh --force-wipe --restart-server 3600 weekly server restart @@ --wipe-blueprints odd --do-backup rustserver; fi
```
This cron will fire every Thursday at 1PM server time.  It then checks if the day is less than '7' (ie, the first Thursday of the month).

### Backup

`./rs-backup.sh [--full]`

This syntax will take a backup of all instances under the user account running the script.  No save commands are sent.

~~`./rs-backup.sh <instancename> <instancename...>`~~

~~This invocation will only save the data needed to restore the specific instance(s).  If you have webrcon-cli installed and defined, it will also send a save command prior to the backup.~~

### Restore

`./rs-restore.sh [--full] backupFile [<date>]`

  This invocation will restore all Rust instances from the specified `backupFile`.  If you need a file from a different month, then pass the month in `MM` format (as `date`).  If you have redefined `backupDirSuffix` then use that format instead for `date.`

`./rs-restore.sh <instancename> backupFile [<date>]`

  This version of the command restores only the given `instancename` from the given `backupFile`

`./re-restore.sh list [<date>]`

  This will list all backup files available for the current month.  Pass `MM` for `date` if you need a different month. If you have redefined `backupDirSuffix` then use that format instead for `date.`

### Wipe script

`./rs-wipe-script.sh [option-name] [option-name...] instanceName`
```
rs-wipe-script.sh [option-name] [option-name...] instanceName

  The last parameter MUST be an instance name.

  --wipe-map
    Will delete all *.sav and *.map files in the specified LGSM instance.
  --force-wipe
    Implies --update-rust, --update-mods, and --wipe-map.
  --new-seed [<seedfile.txt>|random]
    Will generate a new map seed and update the specified LGSM config.
    Use seedfile.txt to use the next seed from a given file, seed is deleted on use.  Will use a random seed if file is empty.
   'random' will generate a random seed.
  --update-rust
    Will update Rust.
  --update-mods
    Will update uMod.
  --wipe-blueprints [odd|even|now]
    Will remove the blueprint files, based on the required option.
    (eg: if the month is divisible by two and 'even' is passed, blueprints will be wiped).
  --wipe-backpacks
    Will delete all backpack data from the default location (serverfiles/oxide/data/Backpacks)
  --restart-server <restart time in seconds> <restart reason>
    Will restart the server when done.
    Restart reason can be multiple words; string must be terminated with '@@'
    (requires valid webRconCmd setting in .rs.config).
  --update-lgsm
    Will update LGSM.
  --do-backup
    Will take a backup.

