#!/usr/bin/env bash
set -euo pipefail

wasabi_cmd_suffix="--endpoint-url=https://s3.wasabisys.com"

bucket=$WASABI_BUCKET
target="/var/www/vhosts"
timestamp=$(date +%F-%H%M)

if cd ${target}
then
    for i in *
    do
        logger -t wasabi backup of ${target} beginning at ${timestamp}
        tar -czf - $i | aws --profile wasabi s3 ${wasabi_cmd_suffix} cp - s3://${bucket}${target}-weekly/${i}-${timestamp}.tar.gz --endpoint-url=https://s3.wasabisys.com
        if [ $? ]
        then
            logger -t wasabi ${target}/$i backup success up at ${timestamp}
        else
            logger -t wasabi ${target}/$i error at ${timestamp}
        fi
    done
fi
