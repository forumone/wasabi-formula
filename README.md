# wasabi-formula
salt formula for wasabi s3 backups
This WILL NOT backup files NOT on shared Objective FS Volume.  Additonal states would be required for that and this is HIGHLY discouraged because servers should be ephmeral and all config managed via salt.

## Requirements
This formula is dependent on there being three AWS Paramter store values secrets named WASABI_ACCESS_KEY_ID, WASABI_SECRET_ACCESS_KEY and WASABI_BUCKET being available to the instance this script runs on.
Also need to have ro-mysql (and ro-psql) DNS entries defined in local DNS - these scripts use the Read Only Aurora endpoints to backup databases - as not to clobber open running connections
Also requires Objective FS and ONLY backups files From the latest Objective FS snapshot - again not to clobber open files


## Description

```wasabi-daily.sh``` - this script runs a dbdump, as well as an s3 sync on the directories defined in /etc/wasabi-backup.txt, which is defined in each instances salt pillar.

```wasabi-weekly.sh``` - this script creates a tarball of each of the vhost directories in /var/www/vhosts/, and copies to wasabi in /var/www/vhosts-weekly

```mysql_backup.sh``` - uses cutom automsysqlbackup script to run MySql backups and rotate files

```psql_backup.sh``` - uses cutom autopsqlbackup script to run Postgresql backups and rotate files

## Usage
Include formula in salt-master config
add wasabi to Utility Server's in salt/top.sls
add postgresql_backup to Utility Server's top.sls - if required
