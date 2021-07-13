{% from "wasabi/map.jinja" import project, wasabi_bucket with context %}

include:
  - wasabi.credentials
  - wasabi.mysql_backup
  - wasabi.weekly_tar

# install jq
jq:
  pkg.installed:
    - name: jq

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
        project: {{ project }}
        wasabi_bucket: {{ wasabi_bucket }}
    - require:
      - /opt/wasabi/bin

#setup crontab entries
/opt/wasabi/bin/wasabi-daily.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabi-daily
    - user: root
    - minute: random
    - hour: 2
    - require:
      - /opt/wasabi/bin/wasabi-daily.sh