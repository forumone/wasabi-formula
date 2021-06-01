#! /usr/bin/env bash
set -eo pipefail

# exclude
exclude="*>*"

# file containing paths to backup, one per line.
input="/etc/wasabi-backup.txt"

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

# read paths from file, run aws sync against every valid path.
while IFS= read -r line
do
    if [[ ! -z ${line} ]];
    then
        source=$(realpath "$line")
        if [ -d "$source" ] && [ -x "$source" ];
        then
            echo "[wasabi] ${now} beginning back up of ${source}..."
            aws --profile wasabi  s3 sync "$source" s3://"{{ WASABI_BUCKET}}/${source}" --no-follow-symlinks --exclude "/etc/systemd/system/multi-user.target.wants/amazon-ssm-agent.service" --exclude "${exclude}" --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" backup SUCCESS || logger -t wasabi "$source" backup ERROR
        fi
    fi
done < $input

#cleanup
rm -f ${lockfile}
