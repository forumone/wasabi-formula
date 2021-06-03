#! /usr/bin/env bash
set -eo pipefail

#use flock to set a lock file to keep multiple copies of the script from running
scriptname=$(basename $0)
lock="/var/run/${scriptname}"
exec 200>$lock
flock -n 200 || exit 1

timestamp=$(date +%F_%H-%M-%S)

function run {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
       echo "Error with $1"
    fi
    return $status
}

#Get Objective FS mount from fstab entry
ofs=$(grep ofs /etc/fstab | awk '{print $1}')

#Get todays day in a in the proper format for objective fs snapshots
snap=$(date +%Y-%m-%d)

#Get the latest ObjectiveFS Snapshot
ofs_snapshot=$(/sbin/mount.objectivefs list -sz $ofs@$snap | tail -n 1 | awk '{print $1}')

#Create the mount point if it does not exist
if test -e /mnt/ofs_snapshot/; then
    mkdir /mnt/ofs_snapshot/
fi

#Check to see if snapshot was available - exit with error if not
if test -z $ofs_snapshot
then
  echo "Unable to get latest OFS Snapshot"
  exit 1
#Test to see if snapshot is already mounted - fail if it is
elif test -f "/mnt/ofs_snapshot/README"; then
  echo "Unable to mount snapshot!"
  exit 1
else
  /sbin/mount.objectivefs $ofs_snapshot /mnt/ofs_snapshot
fi

if test -f "/mnt/ofs_snapshot/README"; then
#Back up folders to tar.gz format
for i in $(ls /mnt/ofs_snapshot/vhosts/)
  do
  if [[ "$i" != "healthcheck" ]]; then
        logger -t wasabi tar backup of vhosts beginning at ${timestamp}
        run tar czfP - /mnt/ofs_snapshot/vhosts/$i | aws --profile wasabi s3 cp - s3://{{ wasabi_bucket }}/vhosts-weekly/${i}-${timestamp}.tar.gz --endpoint-url=https://s3.wasabisys.com
        if [ $? ]; then
            logger -t wasabi $i backup success up at ${timestamp}
        else
            logger -t wasabi $i error at ${timestamp}
        fi
  fi
    done
else
echo "Objective FS Snapshot is not mounted, Unable to backup"
exit 1
fi

#cleanup
umount /mnt/ofs_snapshot
rm -f $lock

