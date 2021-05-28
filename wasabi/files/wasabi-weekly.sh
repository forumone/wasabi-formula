#!/usr/bin/env bash
set -euo pipefail

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

bucket=$WASABI_BUCKET
target="/var/www/vhosts"
timestamp=$(date +%F-%H%M)

if cd ${target}
then
    for i in *
    do
        logger -t wasabi backup of ${target} beginning at ${timestamp}
        tar -czf - $i | aws s3 ${wasabi_cmd_suffix} cp - s3://${bucket}${target}-weekly/${i}-${timestamp}.tar.gz
        if [ $? ]
        then
            logger -t wasabi ${target}/$i backup success up at ${timestamp}
        else
            logger -t wasabi ${target}/$i error at ${timestamp}
        fi
    done
fi
