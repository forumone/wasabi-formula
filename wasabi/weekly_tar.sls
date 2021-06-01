{% set client = pillar.wasabi.client_id %}
{% set wasabi_bucket = salt['cmd.shell']('aws --region us-east-2 ssm get-parameter --name "/forumone/"' + client + '"/wasabi/bucket" --with-decryption | jq -r .Parameter.Value') %}

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