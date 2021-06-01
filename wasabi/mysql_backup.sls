{% set client = pillar.wasabi.client_id %}
{% set wasabi_bucket = salt['cmd.shell']('aws --region us-east-2 ssm get-parameter --name "/forumone/"' + client + '"/wasabi/bucket" --with-decryption | jq -r .Parameter.Value') %}

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