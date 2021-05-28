# install jq
jq:
  pkg.installed:
    - name: jq

# list of directories to back up, defined in pillar
wasabi-backup:
  file.managed:
    - name: /etc/wasabi-backup.txt
    - source: salt://wasabi/files/wasabi-daily.tpl
    - template: jinja

# create directory
/opt/wasabi/bin:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

# daily sync
/opt/wasabi/bin/wasabi-daily.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/wasabi-daily.sh
    - template: jinja

# Mysql daily
/opt/wasabi/bin/mysql-daily.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/mysql-daily.sh

# PSQL daily
/opt/wasabi/bin/mysql-daily.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/psql-daily.sh


# Mysql backup
/usr/sbin/mysqlbackup.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/mysqlbackup.sh

# PSQL backup
/usr/sbin/postgresqlbackup.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/postgresqlbackup.sh

# vhosts weekly tarball
/opt/wasabi/bin/wasabi-weekly.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/wasabi-weekly.sh
    - template: jinja

# cron entry to run script
#  Enable DB dumps if wasabi:mysql_backup is True. Set a default True value if doesn't exist
{% if pillar.wasabi.mysql_backup('',true) %}
/opt/wasabi/bin/mysql-daily.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: mysql-daily-backup
    - user: root
    - minute: random
    - hour: 0
{% endif %}

{% if pillar.wasabi.psql_backup == true %}
/opt/wasabi/bin/psql-daily.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: postgresql-daily-backup
    - user: root
    - minute: random
    - hour: 1
{% endif %}

/opt/wasabi/bin/wasabi-daily.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabi-daily
    - user: root
    - minute: random
    - hour: 2


/opt/wasabi/bin/wasabi-weekly.sh | logger -t backups:
  cron.present:
    - identifier: wasabi-weekly
    - user: root
    - minute: random
    - hour: 3
    - dayweek: 0
