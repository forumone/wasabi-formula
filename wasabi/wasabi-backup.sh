#! /usr/bin/env bash
set -e

# arguments required for awscli to work with wasabi
wasabi_cmd_suffix="--profile wasabi --endpoint-url=https://s3.wasabisys.com"

# name of wasabi bucket
bucket="examplebucket"

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
  date=`date -I`
  dir=/var/lib/mysqlbackups
  databases=`/usr/bin/mysql -e 'show databases' -s --skip-column-names | /bin/grep -v information_schema | /bin/grep -v performance_schema`
  file=$date.sql.gz
  test -d $dir || /bin/mkdir -p $dir
  echo "Dumping databases"
  for i in $databases; do run /usr/bin/mysqldump --opt $i |gzip > $dir/$i.$file; done
  echo "Finished dumping databases"
  run /usr/bin/find $dir -ctime +7 -delete
fi

# read paths from file, run aws sync against every valid path.
while IFS= read -r line
do
if [ -d "$line" ] && [ -x "$line" ];
then
        echo "aws s3 sync $line s3:/${bucket}${line} ${wasabi_cmd_suffix} | logger $(basename $0) $now $line backup SUCCESS" || logger $(basename $0) $line backup FAILED
fi
done < $input

rm -f ${lockfile}