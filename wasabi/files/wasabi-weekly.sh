#! /usr/bin/env bash
set -eo pipefail

lockfile -r 0 /tmp/prebackup.lock || exit 1

timestamp=$(date +%F_%H-%M-%S)


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
if test -z $snap; then
echo "Unable to get latest OFS Snapshot"
exit 1
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
        tar czfP - /mnt/ofs_snapshot/vhosts/$i | aws --profile wasabi s3 cp - s3://{{ wasabi_bucket }}/vhosts-weekly/${i}-${timestamp}.tar.gz --endpoint-url=https://s3.wasabisys.com
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
rm -f /tmp/prebackup.lock

