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
run aws --profile wasabi s3 sync /var/backups/psql s3://"{{ wasabi_bucket }}/psql/" --no-follow-symlinks --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" backup SUCCESS || logger -t wasabi "$source" backup ERROR

#cleanup
rm -f $lock
