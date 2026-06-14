#!/usr/bin/env bash
# safe WordPress maintenance over WP-CLI. takes a DB backup before touching
# anything, then updates core, plugins and themes. has a --dry-run mode.
#   ./wp-maintenance.sh /var/www/site
#   ./wp-maintenance.sh /var/www/site --dry-run
# run as the site owner, not root.
set -euo pipefail

WP_PATH="${1:-}"
DRY=0; [[ "${2:-}" == "--dry-run" ]] && DRY=1
[[ -n "$WP_PATH" && -f "$WP_PATH/wp-load.php" ]] || { echo "usage: $0 /path/to/wordpress [--dry-run]" >&2; exit 2; }
command -v wp >/dev/null || { echo "wp-cli not found on PATH" >&2; exit 2; }

wp(){ command wp --path="$WP_PATH" "$@"; }
ts=$(date +%Y%m%d-%H%M%S)
backup_dir="${WP_BACKUP_DIR:-$WP_PATH/.maint-backups}"
mkdir -p "$backup_dir"

echo "== wp-maintenance: $(wp option get siteurl) =="

echo "[1/4] database backup"
if [[ "$DRY" == "1" ]]; then
  echo "  (dry-run) would export to $backup_dir/db-$ts.sql"
else
  wp db export "$backup_dir/db-$ts.sql" --quiet
  gzip -f "$backup_dir/db-$ts.sql"
  echo "  saved $backup_dir/db-$ts.sql.gz"
  ls -1t "$backup_dir"/db-*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f
fi

update(){
  echo "[$2] $1 updates"
  if [[ "$DRY" == "1" ]]; then
    [[ "$1" == "core" ]] && wp core check-update || wp "$1" list --update=available --fields=name,version,update_version 2>/dev/null || true
  else
    [[ "$1" == "core" ]] && wp core update || wp "$1" update --all
  fi
}
update core   "2/4"
update plugin "3/4"
update theme  "4/4"

echo
[[ "$DRY" == "1" ]] && echo "dry-run complete, nothing changed." || echo "maintenance complete. core: $(wp core version)"
