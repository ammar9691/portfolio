#!/usr/bin/env bash
# scan SSH auth logs for failed logins, group by source IP, and flag any IP
# over the threshold. read-only reporting to pair with fail2ban (which does the
# banning). reads journald, or a logfile with --file.
#   ./bruteforce-watch.sh
#   THRESHOLD=20 SINCE="6 hours ago" ./bruteforce-watch.sh
#   ./bruteforce-watch.sh --file /var/log/auth.log
# exits non-zero if any IP crosses the threshold.
set -euo pipefail

THRESHOLD="${THRESHOLD:-10}"
SINCE="${SINCE:-24 hours ago}"

if [[ "${1:-}" == "--file" ]]; then
  [[ -f "${2:-}" ]] || { echo "file not found: ${2:-}" >&2; exit 2; }
  src=$(grep "Failed password" "$2" || true)
else
  src=$(journalctl -u ssh -u sshd --since "$SINCE" 2>/dev/null | grep "Failed password" || true)
fi

# pull the IP that follows "from", count per IP, sort high to low
mapfile -t rows < <(printf '%s\n' "$src" \
  | grep -oE 'from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
  | awk '{print $2}' | sort | uniq -c | sort -rn)

total=$(printf '%s\n' "$src" | grep -c "Failed password" || true)
echo "== ssh bruteforce watch (since: $SINCE) =="
echo "total failed attempts: $total"
echo "threshold per ip     : $THRESHOLD"
echo

over=0
if [[ ${#rows[@]} -eq 0 ]]; then
  echo "no failed logins. clean."
else
  printf '%-8s %-18s %s\n' "count" "source ip" "status"
  for r in "${rows[@]}"; do
    c=$(awk '{print $1}' <<<"$r"); ip=$(awk '{print $2}' <<<"$r")
    if [[ "$c" -ge "$THRESHOLD" ]]; then st="OVER"; over=1; else st="ok"; fi
    printf '%-8s %-18s %s\n' "$c" "$ip" "$st"
  done
fi

exit "$over"
