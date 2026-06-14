#!/usr/bin/env bash
# check TLS cert expiry for one or more domains. catches certs before they lapse.
#   ./ssl-expiry.sh example.com host.com:443
#   ./ssl-expiry.sh --file domains.txt
#   WARN_DAYS=14 ./ssl-expiry.sh example.com
# exits non-zero if any cert is expired or within WARN_DAYS, for cron alerting.
set -euo pipefail

WARN_DAYS="${WARN_DAYS:-21}"
domains=()

if [[ "${1:-}" == "--file" ]]; then
  [[ -f "${2:-}" ]] || { echo "file not found: ${2:-}" >&2; exit 2; }
  mapfile -t domains < <(grep -vE '^\s*(#|$)' "$2")
else
  domains=("$@")
fi
[[ ${#domains[@]} -gt 0 ]] || { echo "usage: $0 domain [domain...] | --file domains.txt" >&2; exit 2; }

worst=0
for d in "${domains[@]}"; do
  host="${d%%:*}"; port="${d##*:}"; [[ "$host" == "$port" ]] && port=443
  end=$(echo | timeout 10 openssl s_client -servername "$host" -connect "${host}:${port}" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)
  if [[ -z "$end" ]]; then
    printf '%-32s  UNREACHABLE\n' "$host"; worst=2; continue
  fi
  end_epoch=$(date -d "$end" +%s)
  days=$(( (end_epoch - $(date +%s)) / 86400 ))
  if   [[ "$days" -lt 0 ]]; then state="EXPIRED";  worst=2
  elif [[ "$days" -le "$WARN_DAYS" ]]; then state="WARN"; [[ "$worst" -lt 1 ]] && worst=1
  else state="ok"; fi
  printf '%-32s  %-7s  %4sd left  (%s)\n' "$host" "$state" "$days" "$end"
done

exit "$worst"
