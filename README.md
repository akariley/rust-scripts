# Scripts for Rust (game)

These scripts are intended to ease your wipe days for [Rust](https://rust.facepunch.com) servers and generate smaller backups than the stock [LGSM](https://linuxgsm.com/lgsm/) backups by only backing up the map/sav files as opposed to the entire install.

## Requirements
- [LGSM](https://linuxgsm.com/lgsm/)
- [webrcon-cli](https://www.npmjs.com/package/webrcon-cli) (optional, but highly recommended)

### rs-backup.sh

`./rs-backup.sh [--full]`
This syntax will take a backup of all instances under the user account running the script.  No save commands are sent.

`./rs-backup.sh <instancename> <instancename...>`
This invocation will only save the data needed to restore the specific instance(s).  If you have webrcon-cli installed and defined, it will also send a save command prior to the backup.
