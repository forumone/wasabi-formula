{% from "wasabi/map.jinja" import wasabi_key, wasabi_secret with context %}

/root/.aws/:
  file.directory:
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

wasabi_aws_profile_exists:
  file.managed:
    - name: /root/.aws/config
    - replace: False
    - user: root
    - group: root
    - mode: '0600'
    - require:
      - /root/.aws/

wasabi_aws_credentials_exists:
  file.managed:
    - name: /root/.aws/credentials
    - replace: False
    - user: root
    - group: root
    - mode: '0600'
    - require:
      - /root/.aws/

wasabi_aws_profile:
  file.replace:
    - append_if_not_found: True
    - name: /root/.aws/config
    - pattern: |
        [wasabi]
        region=us-east-1
        output=json
    - repl: |
        [wasabi]
        region=us-east-1
        output=json
    - require:
      - wasabi_aws_profile_exists

wasabi_aws_credentials:
  file.replace:
    - append_if_not_found: True
    - name: /root/.aws/credentials
    - pattern: |
        [wasabi]
        aws_access_key_id=
        aws_secret_access_key=
    - repl: |
        [wasabi]
        aws_access_key_id={{ wasabi_key }}
        aws_secret_access_key={{ wasabi_secret }}
    - require:
      - wasabi_aws_credentials_exists