#!/usr/bin/env bash
# back up one or more paths to a compressed archive, rotate old ones, and
# optionally copy offsite to s3 or a minio bucket. meant for cron.
#   ./backup.sh /etc /var/www
#   KEEP=14 BACKUP_DIR=/srv/backups ./backup.sh /etc
#   S3_BUCKET=s3://my-bucket/host1 ./backup.sh /etc /var/www   (needs aws cli)
set -euo pipefail

[[ $# -gt 0 ]] || { echo "usage: $0 path [path...]" >&2; exit 2; }
BACKUP_DIR="${BACKUP_DIR:-/var/backups/host}"
KEEP="${KEEP:-7}"
mkdir -p "$BACKUP_DIR"
ts=$(date +%Y%m%d-%H%M%S)
archive="$BACKUP_DIR/backup-$ts.tar.gz"

echo "[1/3] creating $archive"
tar czf "$archive" --absolute-names "$@"
echo "  size $(du -h "$archive" | cut -f1)"

echo "[2/3] rotating, keeping newest $KEEP"
find "$BACKUP_DIR" -maxdepth 1 -name 'backup-*.tar.gz' -printf '%T@ %p\n' \
  | sort -rn | tail -n +"$((KEEP + 1))" | cut -d' ' -f2- | xargs -r rm -f

if [[ -n "${S3_BUCKET:-}" ]]; then
  echo "[3/3] offsite to $S3_BUCKET"
  aws s3 cp "$archive" "$S3_BUCKET/" --only-show-errors
else
  echo "[3/3] offsite skipped (set S3_BUCKET to enable)"
fi
echo "done."
