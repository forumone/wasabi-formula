{% include './init.sls' with context %}
/root/.aws/:
  file.directory:
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

wasabi_aws_profile_exists:
  file.managed:
    - name: /root/.aws/config
    - user: root
    - group: root
    - mode: '0600'

wasabi_aws_credentials_exists:
  file.managed:
    - name: /root/.aws/credentials
    - user: root
    - group: root
    - mode: '0600'

wasabi_aws_profile:
  file.append:
    - name: /root/.aws/config
    - text: |
        [wasabi]
        region=us-east-1
        output=json

wasabi_aws_credentials:
  file.append:
    - name: /root/.aws/credentials
    - text: |
        [wasabi]
        aws_access_key_id={{ wasabi_key }}
        aws_secret_access_key={{ wasabi_secret }}