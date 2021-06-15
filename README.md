# wasabi-formula
salt formula for wasabi s3 backups
This WILL NOT backup files NOT on shared Objective FS Volume.
Additonal states would be required for that and this is HIGHLY discouraged because servers should be ephmeral and all config managed via salt.

## Requirements
Objective FS with snapshots enabled

AWS Paramter store values in the local AWS Account:
  - WASABI_ACCESS_KEY_ID
  - WASABI_SECRET_ACCESS_KEY
  - WASABI_BUCKET

The Read Only endpoints for Aurora defined in local DNS
  - ro-mysql
  - ro-psql (if postgres is used)

Salt pillar data
  - project: project short name
  - client: client short name

Wasabi Bucket created matching the parameter above

## Description

```wasabi-daily.sh``` - this script mounts the last Objectivefs Snapshot and syncs data to the Wasabi Bucket

```wasabi-weekly.sh``` - this script mounts the last Objectivefs Snapshot and creates an Archive in the Wasabi Bucket under the /weekly folder

```mysql_backup.sh``` - uses cutom msysqlbackup script to create compressed MySql daily/weekly/monthly daatbase backups and syncs them to the wasabi bucket

```psql_backup.sh``` - uses cutom postgresqlbackup script to create compressed PostgreSQL daily/weekly/monthly database backups and syncs them to the wasabi bucket

## Usage
Make sure all requirements are met above
Include formula in salt-master config
add wasabi to Utility Server's in salt/top.sls
add postgresql_backup to Utility Server's top.sls - if required
