# vhosts weekly tarball
/opt/wasabi/bin/wasabi-weekly.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 750
    - source: salt://wasabi/files/wasabi-weekly.sh
    - template: jinja
    - context:
        client: {{ client_id }}
        wasabi_bucket: {{ wasabi_bucket }}