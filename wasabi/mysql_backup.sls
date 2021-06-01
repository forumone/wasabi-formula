{% include './init.sls' with context %}

# Mysql daily
/opt/wasabi/bin/mysql-daily.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/mysql-daily.sh
    - template: jinja
    - context:
        client: {{ client }}
        wasabi_bucket: {{ wasabi_bucket }}

# Mysql backup
/usr/sbin/mysqlbackup.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/mysqlbackup.sh

#Run daily at midnight
/opt/wasabi/bin/mysql-daily.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: mysql-daily-backup
    - user: root
    - minute: random
    - hour: 0