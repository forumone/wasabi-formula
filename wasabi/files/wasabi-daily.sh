#! /usr/bin/env bash
set -eo pipefail
#use flock to set a lock file to keep multiple copies of the script from running
scriptname=$(basename $0)
lock="/var/run/${scriptname}"
exec 200>$lock
flock -n 200 || exit 1

#include & exclude flies/folders
INCLUDES=("^\.env")
EXCLUDES=("*>*" "^\.")
#builds the list for aws s3 sync to comsume
for I in ${INCLUDES[@]}; do
 INCLUDE+="--include=$I "; done

for E in ${EXCLUDES[@]}; do
 EXCLUDE+="--exclude=$E "; done

#timestamp
now=$(date +%F_%H-%M-%S)
DOW=$(date +%a)

#creates a run function to drop exit codes on command failures
function run {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
       echo "Error with $1"
    fi
    return $status
}

#fail function to run cleanup on failures
function fail {
  echo "$(hostname) Wasabi backup Errors" | mailx -r wasabi@byf1.dev -s "$(hostname) Wasabi backup Errors" sysadmins@forumone.com
  rm -f $lock
  if test -f "/mnt/ofs_snapshot/README"; then
  umount /mnt/ofs_snapshot
  fi
  exit 1
}

#objectivefs Snapshot mount - to not backup open files

#Create the mount point if it does not exist
if test ! -d /mnt/ofs_snapshot ; then
  mkdir -p /mnt/ofs_snapshot/
fi

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

#Check to see if snapshot is available - exit with error if not
if test -z $ofs_snapshot; then
  logger -t wasabi "$now" WASABI Unable to get latest OFS Snapshot
  fail
else
  /sbin/mount.objectivefs $ofs_snapshot /mnt/ofs_snapshot
fi
#Mount snapshot and backup
if test -f "/mnt/ofs_snapshot/README"; then
#Do weekly tar archive on Saturdays
  if [[ "$DOW" == "Sat" ]]; then
    for i in $(ls /mnt/ofs_snapshot/vhosts/); do
      if [[ "$i" != "healthcheck" ]]; then
            logger -t wasabi tar backup of vhosts beginning at ${timestamp}
            run tar czfP - /mnt/ofs_snapshot/vhosts/$i | aws --profile wasabi s3 cp - s3://{{ wasabi_bucket }}/vhosts-weekly/${i}-${timestamp}.tar.gz --endpoint-url=https://s3.wasabisys.com
            if [ $? ]; then
                logger -t wasabi $i WASABI WEEKLY BACKUP SUCCESS up at ${timestamp}
            else
                logger -t wasabi $i WASABI WEEKLY BACKUP ERROR at ${timestamp}
                fail
            fi
      fi
    done
  #Daily Back up Snapshot
  else
    run aws --profile wasabi s3 sync /mnt/ofs_snapshot/ s3://{{ wasabi_bucket }}/ --no-follow-symlinks ${INCLUDE} ${EXCLUDE} --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" WASABI DAILY BACKUP SUCCESS || logger -t wasabi "$now" "$source" WASABI DAILY BACKUP ERROR
  fi
else
  logger -t wasabi "$now" Objective FS Snapshot is not mounted, Unable to backup
  fail
fi

#cleanup
if test -f "/mnt/ofs_snapshot/README"; then
  umount /mnt/ofs_snapshot
fi
rm -f $lock

#send log entries to wasabi bucket for debugging later
grep "WASABI DAILY BACKUP" /var/log/messages | aws --profile wasabi s3 cp - s3://{{ wasabi_bucket }}/daily-backup.log --endpoint-url=https://s3.wasabisys.com

#Check Log for errors
ERRORS=$(grep $now /var/log/messages | grep ERROR)
BACKUPLOG=$(grep backups /var/log/messages)
#If there is an error - send a message or clean up script or both
if [[ ! -z $ERRORS ]]; then
  echo "$BACKUPLOG" | mailx -r wasabi@byf1.dev -s "$(hostname) Wasabi backup Errors" sysadmins@forumone.com
  fail
else
  exit 0
fi