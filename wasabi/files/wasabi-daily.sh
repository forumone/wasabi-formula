#! /usr/bin/env bash
set -eo pipefail

# exclude
exclude="*>*"

# timestamp
now=$(date +%F_%H-%M-%S)

lockfile=/tmp/prebackup.lock

touch ${lockfile}
#mount OFS Snapshot
#get S3 FS
snap=$(date +%Y-%m-%d)
echo $snap
ofs_snapshot=$(/sbin/mount.objectivefs list -sz james-ofs-q7fc1co4/www@$snap | tail -n 1 | awk '{print $1}')
echo $ofs_snapshot
/sbin/mount.objectivefs $ofs_snapshot /mnt/ofs_snapshot

#Backup Snapshot
aws --profile wasabi  s3 sync /mnt/ofs_snapshot/ s3://"{{ wasabi_bucket }}/vhosts" --no-follow-symlinks --exclude "/etc/systemd/system/multi-user.target.wants/amazon-ssm-agent.service" --exclude "${exclude}" --endpoint-url=https://s3.wasabisys.com 2>&1 1>/dev/null && logger -t wasabi "$now" "$source" backup SUCCESS || logger -t wasabi "$source" backup ERROR

#cleanup
umount /mnt/ofs_snapshot
rm -f ${lockfile}
