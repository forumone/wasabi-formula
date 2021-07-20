{% from "wasabi/map.jinja" import project, wasabi_bucket with context %}

# PSQL daily
/opt/wasabi/bin/psql-daily.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/psql-daily.sh
    - template: jinja
    - context:
        project: {{ project }}
        wasabi_bucket: {{ wasabi_bucket }}
    - require:
      - /opt/wasabi/bin

# PSQL backup
/usr/sbin/postgresqlbackup.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/postgresqlbackup.sh

/opt/wasabi/bin/psql-daily.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: postgresql-daily-backup
    - user: root
    - minute: random
    - hour: 7
    - require:
      - /usr/sbin/postgresqlbackup.sh