#!/bin/bash

# normal lootlogs look like this:
# forward: ./lootlogs_storagecontainer-box.wooden.large-5080033-2021-07-28.txt
# reversed: txt.22-70-1202-39239043-egral.nedoow.xob-reniatnocegarots_sgoltool/.

# A deaths lootlog is like:
# forward: ./lootlogs_baseoven-deaths-2021-07-23.txt
# reverse: txt.32-70-1202-shtaed-nevoesab_sgoltool/.
LOGDIR="/home/${USER}/rust/serverfiles/oxide/logs/LootLogs"

cd ${LOGDIR}

touch -t `date +%m%d0000` /tmp/${USER}/$$

find . -maxdepth 1 -type f -not -newer /tmp/${USER}/$$ -name "lootlogs_*.txt" | while read _name; do
  _id=''
  _dir=''
  if [[ "$_name" == *deaths* ]]; then
    _dir=$(echo $_name | rev | cut -d- -f4- | awk -F'_sgoltool' '{print $1}' | rev) # output: baseoven
  else
    _id=$(echo $_name | rev | cut -d- -f4 | rev) # output: 123456789
    _dir=$(echo $_name | rev | cut -d- -f5- | awk -F'_sgoltool' '{print $1}' | rev) # output: storagecontainer-box.wooden.large
  fi
  mkdir -p ./${_dir}/${_id}
  mv $_name ./${_dir}/${_id}
done
rm /tmp/${USER}/$$
