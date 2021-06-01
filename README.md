# wasabi-formula
salt formula for wasabi s3 backups

## Requirements
This formula is dependent on there being three AWS Paramter store values secrets named WASABI_ACCESS_KEY_ID, WASABI_SECRET_ACCESS_KEY and WASABI_BUCKET being available to the instance this script runs on.

## Description

```wasabi-daily.sh``` - this script runs a dbdump, as well as an s3 sync on the directories defined in /etc/wasabi-backup.txt, which is defined in each instances salt pillar.

```wasabi-weekly.sh``` - this script creates a tarball of each of the vhost directories in /var/www/vhosts/, and copies to wasabi in /var/www/vhosts-weekly

```mysql_backup.sh``` - uses cutom automsysqlbackup script to run MySql backups and rotate files

```psql_backup.sh``` - uses cutom autopsqlbackup script to run Postgresql backups and rotate files

## Usage
Include formula in salt-master
add postgresql_backup to Utility Server's top.sls - if required
