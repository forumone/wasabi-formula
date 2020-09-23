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

# daily sync / db dump script
/opt/wasabi/bin/wasabi-daily.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/wasabi-daily.sh
    - template: jinja
    - require:
      - file: /opt/wasabi/bin

# vhosts weekly tarball
/opt/wasabi/bin/wasabi-weekly.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/wasabi-weekly.sh
    - template: jinja
    - require: 
      - file: /opt/wasabi/bin

# cron entry to run script
#  Enable DB dumps if rsync:dumpdbs is True. Set a default False value if doesn't exist
{% if salt['pillar.get']('wasabi:dumpdbs', False) %}
/opt/wasabi/bin/wasabi-daily.sh dumpdbs 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabibackup-daily
    - user: root
    - minute: random
    - hour: 2
{% elif 'mysql' in salt['grains.get']('roles', 'roles:none') %}
/opt/wasabi/bin/wasabi-daily.sh dumpdbs 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabibackup-daily
    - user: root
    - minute: random
    - hour: 2
{% else %}
/opt/wasabi/bin/wasabi-daily.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabibackup-daily
    - user: root
    - minute: random
    - hour: 2
{% endif %}