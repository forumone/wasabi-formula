#! /usr/bin/env bash
set -eo pipefail

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
if [ $snap -z ]
then
echo "Unable to get latest OFS Snapshot"
exit 1
elif [ test -f "/mnt/ofs_snapshot/README" ]
echo "Unable to mount snapshot!"
exit 1
else
/sbin/mount.objectivefs $ofs_snapshot /mnt/ofs_snapshot
fi

if [test -f "/mnt/ofs_snapshot/README" ]
then
touch $lockfile
#Back up folders to tar.gz format
for i in $(ls /mnt/ofs_snapshot/vhosts/)
  do
        logger -t wasabi tar backup of vhosts beginning at ${timestamp}
        tar -czf - $i | aws --profile wasabi s3 cp - s3://${bucket}/vhosts-weekly/${i}-${timestamp}.tar.gz --endpoint-url=https://s3.wasabisys.com
        if [ $? ]
        then
            logger -t wasabi ${target}/$i backup success up at ${timestamp}
        else
            logger -t wasabi ${target}/$i error at ${timestamp}
        fi
    done
fi
elif
echo "Objective FS Snapshot is not mounted, Unable to backup"
exit 1
fi

#cleanup
umount /mnt/ofs_snapshot
rm -f ${lockfile}

