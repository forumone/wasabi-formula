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

function run {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
       echo "Error with $1"
    fi
    return $status
}

run /usr/sbin/postgresqlbackup.sh
run aws --profile wasabi s3 sync /var/backups/postgresql s3://"{{ wasabi_bucket }}/postgresql/" --no-follow-symlinks --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" WASABI PSQL BACKUP SUCCESS || logger -t wasabi "$source" baWASABI PSQL BACKUP ERROR

grep "WASABI PSQL BACKUP" /var/log/messages | aws --profile wasabi s3 cp - s3://"{{ wasabi_bucket }}/psql-backup.log" --endpoint-url=https://s3.wasabisys.com


#cleanup
rm -f $lock
