#!/usr/bin/env bash
set -euo pipefail

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

bucket="{{ pillar['wasabi']['bucket'] }}"
target="/var/www/vhosts"
timestamp=$(date +%F-%H%M)


#cd ${target} || echo "can't cd"

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
