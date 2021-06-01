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

touch ${lockfile}

/usr/sbin/postgresqlbackup.sh
aws --profile wasabi s3 sync /var/backups/mysql s3://"{{ wasabi_bucket }}/mysql/" --no-follow-symlinks --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" backup SUCCESS || logger -t wasabi "$source" backup ERROR

#cleanup
rm -f ${lockfile}
