#! /usr/bin/env bash
set -eo pipefail

# exclude
exclude="*>*"

# timestamp
now=$(date +%F_%H-%M-%S)

lockfile=/tmp/prebackup.lock

function run {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
       echo "Error with $1"
    fi
    return $status
}

#mount OFS Snapshot
#get S3 FS
snap=$(date +%Y-%m-%d)
ofs_snapshot=$(/sbin/mount.objectivefs list -sz james-ofs-q7fc1co4/www@$snap | tail -n 1 | awk '{print $1}')

if test -z $ofs_snapshot
then
  echo "Unable to get latest OFS Snapshot"
  exit 1
elif test -f "/mnt/ofs_snapshot/README"
then
  echo "Unable to mount snapshot!"
  exit 1
else
  /sbin/mount.objectivefs $ofs_snapshot /mnt/ofs_snapshot
fi

if test -f "/mnt/ofs_snapshot/README"
then
  touch $lockfile
#Back up Snapshot
  run aws --profile wasabi  s3 sync /mnt/ofs_snapshot/ s3://"{{ wasabi_bucket }}/" --no-follow-symlinks --exclude "*healthcheck*" --exclude "${exclude}" --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" backup SUCCESS || logger -t wasabi "$source" backup ERROR
else
  echo "Objective FS Snapshot is not mounted, Unable to backup"
  exit 1
fi

#cleanup
umount /mnt/ofs_snapshot
rm -f ${lockfile}
