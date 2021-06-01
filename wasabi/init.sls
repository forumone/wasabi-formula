{% set client = pillar.wasabi.client_id %}
include:
  - .credentials
  - .mysql_backup
  - .weekly_tar

# install jq
jq:
  pkg.installed:
    - name: jq

#Get wasabi buckety from Param store


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
    - context:
        client: {{ client }}
        wasabi_bucket: {{ wasabi_bucket }}

#setup crontab entries
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
