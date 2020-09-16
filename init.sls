# install jq
jq:
  pkg.installed:
    - name: jq

# List of directories to back up
wasabi-backup:
  file.managed:
    - name: /etc/wasabi-backup.txt
    - source: salt://wasabi/files/wasabi-backup.tpl
    - template: jinja

# rsync / db dump script
/opt/wasabi/bin:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

/opt/wasabi/bin/wasabi-backup.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/wasabi-backup.sh
    - require:
      - file: /opt/wasabi/bin

# cron entry to run script
#  Enable DB dumps if rsync:dumpdbs is True. Set a default False value if doesn't exist
{% if salt['pillar.get']('wasabi:dumpdbs', False) %}
/opt/wasabi/bin/wasabi-backup.sh dumpdbs 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabibackup
    - user: root
    - minute: random
    - hour: 2
{% elif 'mysql' in salt['grains.get']('roles', 'roles:none') %}
/opt/wasabi/bin/wasabi-backup.sh dumpdbs 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabibackup
    - user: root
    - minute: random
    - hour: 2
{% else %}
/opt/wasabi/bin/wasabi-backup.sh 2>&1 | logger -t backups:
  cron.present:
    - identifier: wasabibackup
    - user: root
    - minute: random
    - hour: 2
{% endif %}