{% from "wasabi/map.jinja" import client, wasabi_bucket with context %}

# vhosts weekly tarball
/opt/wasabi/bin/wasabi-weekly.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/wasabi-weekly.sh
    - template: jinja
    - context:
        client: {{ client }}
        wasabi_bucket: {{ wasabi_bucket }}

/opt/wasabi/bin/wasabi-weekly.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabi-weekly
    - user: root
    - minute: random
    - hour: 3
    - dayweek: 0
