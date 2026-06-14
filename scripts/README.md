# Server scripts

Bash tooling for everyday Linux, WordPress, and security work. Each script is
self contained, has a short usage note, uses `set -euo pipefail`, and returns a
meaningful exit code so it can drive cron and alerting.

| Script | What it does |
|---|---|
| `health-check.sh` | Server health snapshot (load, memory, disk, failed SSH, top processes). `--json` for alerting; exits non-zero on a threshold breach. |
| `ssl-expiry.sh` | Checks TLS cert expiry for a list of domains, warns before they lapse, exits non-zero if any is expired or close. |
| `bruteforce-watch.sh` | Scans SSH auth logs, groups failed logins by source IP, flags any IP over the threshold. Pairs with fail2ban. |
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
```

## On the roadmap

Added as the work comes up for clients:

- `backup.sh`, rsync or tar backups with rotation and optional offsite to S3 or MinIO
- `service-watchdog.sh`, restart a unit if it is down, with a cooldown
- `nginx-vhost-test.sh`, validate config and cert and reachability before a reload
