#!/usr/bin/env bash
# server health snapshot. plain run prints a report, --json is for cron/alerting.
# also surfaces failed SSH attempts. exits non-zero when a threshold trips.
set -euo pipefail

DISK_WARN="${DISK_WARN:-85}"
MEM_WARN="${MEM_WARN:-90}"
LOAD_WARN="${LOAD_WARN:-$(nproc)}"
JSON=0
[[ "${1:-}" == "--json" ]] && JSON=1

cores=$(nproc)
load1=$(awk '{print $1}' /proc/loadavg)
mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
mem_used_pct=$(awk -v t="$mem_total" -v a="$mem_avail" 'BEGIN{printf "%.0f",(t-a)/t*100}')
disk_pct=$(df -P / | awk 'NR==2{gsub("%","",$5); print $5}')
uptime_str=$(uptime -p 2>/dev/null || awk '{print int($1/86400)"d"}' /proc/uptime)
failed_ssh=$(journalctl -u ssh -u sshd --since "24 hours ago" 2>/dev/null | grep -c "Failed password" || true)

breach=0
load_alarm=$(awk -v l="$load1" -v w="$LOAD_WARN" 'BEGIN{print (l>w)?1:0}')
[[ "$disk_pct" -ge "$DISK_WARN" ]] && breach=1
[[ "$mem_used_pct" -ge "$MEM_WARN" ]] && breach=1
[[ "$load_alarm" == "1" ]] && breach=1

if [[ "$JSON" == "1" ]]; then
  printf '{"host":"%s","uptime":"%s","cores":%s,"load1":%s,"mem_used_pct":%s,"disk_pct":%s,"failed_ssh_24h":%s,"breach":%s}\n' \
    "$(hostname)" "$uptime_str" "$cores" "$load1" "$mem_used_pct" "$disk_pct" "$failed_ssh" "$breach"
  exit "$breach"
fi

bar(){ if [[ "$1" -ge "$2" ]]; then echo "  [!]"; else echo "  [ok]"; fi; }
load_mark(){ if [[ "$load_alarm" == "1" ]]; then echo "  [!]"; fi; }

echo "== health: $(hostname) =="
echo "uptime        : $uptime_str"
echo "load (1m)     : $load1 / ${cores} cores$(load_mark)"
echo "memory used   : ${mem_used_pct}%$(bar "$mem_used_pct" "$MEM_WARN")"
echo "disk / used   : ${disk_pct}%$(bar "$disk_pct" "$DISK_WARN")"
echo "failed ssh/24h: $failed_ssh"
echo
echo "top memory consumers:"
ps -eo pmem,pid,comm --sort=-pmem 2>/dev/null | head -6 | sed 's/^/  /' || true

echo
if [[ "$breach" == "1" ]]; then echo "STATUS: ATTENTION NEEDED"; else echo "STATUS: healthy"; fi
exit "$breach"
