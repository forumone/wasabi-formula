#! /usr/bin/env bash
set -exuo pipefail

# add aws secretsmanager commands to set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$(aws secretsmanager get-secret-value --secret-id WASABI_SECRET_ACCESS_KEY --region us-east-1 | jq -r .SecretString) && export AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID=$(aws secretsmanager get-secret-value --secret-id WASABI_ACCESS_KEY_ID --region us-east-1 | jq -r .SecretString) && export AWS_ACCESS_KEY_ID

# exit 1 if access key not set
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]
then
    echo "awscli access key or secret not set, exiting"
    exit
fi

# arguments required for awscli to work with wasabi
wasabi_cmd_suffix="--endpoint-url=https://s3.wasabisys.com"

# name of wasabi bucket
bucket="{{ pillar['wasabi']['bucket'] }}"

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

if [[ "$1" == "dumpdbs" ]]
then
  date=$(date -I)
  dir=/var/lib/mysqlbackups
  databases=$(/usr/bin/mysql -e 'show databases' -s --skip-column-names | /bin/grep -v information_schema | /bin/grep -v performance_schema)
  file=$date.sql.gz
  test -d $dir || /bin/mkdir -p $dir
  echo "Dumping databases"
  for i in $databases; do run /usr/bin/mysqldump --opt "$i" |gzip > "$dir"/"$i"."$file"; done
  echo "Finished dumping databases"
  run /usr/bin/find $dir -ctime +7 -delete
fi

# read paths from file, run aws sync against every valid path.
while IFS= read -r line
do
   source=$(realpath "$line")
    if [ -d "$source" ] && [ -x "$source" ];
    then
        aws s3 sync --dryrun "$source" s3://"${bucket}${source}" ${wasabi_cmd_suffix} | logger "$now" "$source" backup SUCCESS || logger "$source" backup FAILED
    fi
done < $input

#cleanup
rm -f ${lockfile}