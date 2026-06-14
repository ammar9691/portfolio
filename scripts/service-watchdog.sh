#!/usr/bin/env bash
# keep a systemd unit running. if it is not active, restart it, with a cooldown
# so a crash-looping service is not hammered. logs to syslog. meant for cron.
#   ./service-watchdog.sh nginx
#   COOLDOWN=600 ./service-watchdog.sh php8.2-fpm
set -euo pipefail

unit="${1:-}"
[[ -n "$unit" ]] || { echo "usage: $0 <systemd-unit>" >&2; exit 2; }
COOLDOWN="${COOLDOWN:-300}"
stamp="/tmp/.watchdog-${unit//\//_}"

if systemctl is-active --quiet "$unit"; then
  exit 0
fi

now=$(date +%s)
if [[ -f "$stamp" ]]; then
  last=$(cat "$stamp" 2>/dev/null || echo 0)
  if [[ $((now - last)) -lt "$COOLDOWN" ]]; then
    logger -t watchdog "$unit down but within cooldown, not restarting"
    echo "$unit down, within cooldown, skipping"
    exit 1
  fi
fi

echo "$now" > "$stamp"
logger -t watchdog "$unit is down, restarting"
systemctl restart "$unit"
if systemctl is-active --quiet "$unit"; then
  echo "$unit restarted ok"
else
  echo "$unit failed to restart" >&2
  exit 1
fi
