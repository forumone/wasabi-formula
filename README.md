# wasabi-formula
salt formula for wasabi s3 backups

## Requirements
This formula is dependent on there being two AWS SecretsManager secrets named WASABI_ACCESS_KEY_ID, and WASABI_SECRET_ACCESS_KEY being available to the instance this script runs on.

## To-Do
~- Make $1 optional - currently fails if no arguments given~
- Set aws s3 sync to not follow symlinks
~- Redirect stdout to /dev/null, stderr to stdout (2>&1 1>/dev/null)~
