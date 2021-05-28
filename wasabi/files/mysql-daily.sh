#! /usr/bin/env bash
set -eo pipefail

# add aws cli parameter store commands to set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and WASABI_BUCKET
AWS_SECRET_ACCESS_KEY=$(aws --region us-east-2 ssm get-parameter --name "/forumone/{{ client }}/wasabi/key" --with-decryption | jq -r .Parameter.Value) && export AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID=$(aws --region us-east-2 ssm get-parameter --name "/forumone/{{ client }}/wasabi/secret" --with-decryption | jq -r .Parameter.Value) && export AWS_ACCESS_KEY_ID
WASABI_BUCKET=$(aws --region us-east-2 ssm get-parameter --name "/forumone/{{ client }}/wasabi/bucket" --with-decryption | jq -r .Parameter.Value) && export WASABI_BUCKET
# exit 1 if access key not set
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]
then
    echo "awscli access key or secret not set, exiting"
    exit
fi

# arguments required for awscli to work with wasabi
wasabi_cmd_suffix="--endpoint-url=https://s3.wasabisys.com"

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

/usr/sbin/mysqlbackup.sh
aws s3 sync /var/backups/mysql s3://"$WASABI_BUCKET/mysql/" ${wasabi_cmd_suffix} --no-follow-symlinks 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" backup SUCCESS || logger -t wasabi "$source" backup ERROR

#cleanup
rm -f ${lockfile}
