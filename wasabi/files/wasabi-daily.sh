#! /usr/bin/env bash
set -eo pipefail
#use flock to set a lock file to keep multiple copies of the script from running
scriptname=$(basename $0)
lock="/var/run/${scriptname}"
exec 200>$lock
flock -n 200 || exit 1

# exclude
exclude="*>*"

# timestamp
now=$(date +%F_%H-%M-%S)

#creates a run function to drop exit codes on command failures
function run {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
       echo "Error with $1"
    fi
    return $status
}
#check for open ofs mount and close it
if test -f "/mnt/ofs_snapshot/README"; then
  umount /mnt/ofs_snapshot
fi

#Get Objective FS mount from fstab entry
ofs=$(grep s3 /etc/fstab | awk '{print $1}')

#Get todays day in a in the proper format for objective fs snapshots
snap=$(date +%Y-%m-%d)

#Get the latest ObjectiveFS Snapshot
ofs_snapshot=$(/sbin/mount.objectivefs list -sz $ofs@$snap | tail -n 1 | awk '{print $1}')

#Create the mount point if it does not exist
if test ! -d /mnt/ofs_snapshot ; then
    mkdir -p /mnt/ofs_snapshot/
fi

#Check to see if snapshot was available - exit with error if not
if test -z $ofs_snapshot; then
  echo "Unable to get latest OFS Snapshot"
  exit 1
#Test to see if snapshot is already mounted - fail if it is
elif test -f "/mnt/ofs_snapshot/README"; then
  echo "Unable to mount snapshot!"
  exit 1
else
  /sbin/mount.objectivefs $ofs_snapshot /mnt/ofs_snapshot
fi
#Mount snapshot and backup
if test -f "/mnt/ofs_snapshot/README"; then
#Back up Snapshot
  run aws --profile wasabi s3 sync /mnt/ofs_snapshot/ s3://"{{ wasabi_bucket }}/" --no-follow-symlinks --exclude "*healthcheck*" --exclude "${exclude}" --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" WASABI DAILY BACKUP SUCCESS || logger -t wasabi "$source" WASABI DAILY BACKUP ERROR
else
  echo "Objective FS Snapshot is not mounted, Unable to backup"
  exit 1
fi
grep "WASABI DAILY BACKUP" /var/log/messages | aws --profile wasabi s3 cp - s3://"{{ wasabi_bucket }}/daily-backup.log" --endpoint-url=https://s3.wasabisys.com

#cleanup
umount /mnt/ofs_snapshot
rm -f $lock
