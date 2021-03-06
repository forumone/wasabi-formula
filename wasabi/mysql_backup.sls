{% from "wasabi/map.jinja" import project, wasabi_bucket with context %}

#Append my.cnf
/root/.my.cnf:
  file.append:
    - text: |
        [mysqldump]
        host = ro-mysql

# Mysql daily
/opt/wasabi/bin/mysql-daily.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/mysql-daily.sh
    - template: jinja
    - context:
        project: {{ project }}
        wasabi_bucket: {{ wasabi_bucket }}
    - require:
      - /opt/wasabi/bin

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
    - hour: 6
    - require:
      - /usr/sbin/mysqlbackup.sh