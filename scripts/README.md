# Server scripts

Bash tooling for everyday Linux, WordPress, and security work. Each script is
self contained, has a short usage note, uses `set -euo pipefail`, and returns a
meaningful exit code so it can drive cron and alerting.

| Script | What it does |
|---|---|
| `health-check.sh` | Server health snapshot (load, memory, disk, failed SSH, top processes). `--json` for alerting; exits non-zero on a threshold breach. |
| `ssl-expiry.sh` | Checks TLS cert expiry for a list of domains, warns before they lapse, exits non-zero if any is expired or close. |
| `bruteforce-watch.sh` | Scans SSH auth logs, groups failed logins by source IP, flags any IP over the threshold. Pairs with fail2ban. |
| `backup.sh` | Compressed archive of one or more paths, with rotation and optional offsite copy to S3 or MinIO. |
| `service-watchdog.sh` | Restarts a systemd unit if it is down, with a cooldown so a crash-looping service is not hammered. |
| `nginx-vhost-test.sh` | Validates nginx config and a domain's HTTPS reachability and cert before reloading, so a broken config never goes live. |
| `wp-maintenance.sh` | Safe WordPress update run over WP-CLI: database backup first, then core, plugin and theme updates, with a `--dry-run`. |

## Examples

```bash
# health as a cron alert
DISK_WARN=80 ./health-check.sh --json || mail -s "host alert" me@example.com

# ssl expiry sweep, warn 14 days out
WARN_DAYS=14 ./ssl-expiry.sh --file domains.txt

# bruteforce watch, tighter threshold over the last 6 hours
THRESHOLD=20 SINCE="6 hours ago" ./bruteforce-watch.sh

# wordpress maintenance, dry run first
./wp-maintenance.sh /var/www/site --dry-run
./wp-maintenance.sh /var/www/site

# backup with offsite copy, restart a service if down, safe nginx reload
S3_BUCKET=s3://my-bucket/host1 ./backup.sh /etc /var/www
./service-watchdog.sh nginx
./nginx-vhost-test.sh example.com
```
