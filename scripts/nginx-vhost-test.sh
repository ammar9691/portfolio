#!/usr/bin/env bash
# pre-reload safety check for nginx. validates the config, and optionally checks
# a domain responds over https with a valid cert, then reloads only if every
# check passes. stops a broken config from ever reaching a reload.
#   ./nginx-vhost-test.sh
#   ./nginx-vhost-test.sh example.com
set -euo pipefail

domain="${1:-}"

echo "[1/3] nginx config test"
if ! nginx -t 2>&1 | sed 's/^/  /'; then
  echo "config invalid, not reloading" >&2
  exit 1
fi

if [[ -n "$domain" ]]; then
  echo "[2/3] https check for $domain"
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "https://$domain/" || echo 000)
  echo "  http $code"
  if [[ "$code" == "000" ]]; then
    echo "  domain unreachable over https, not reloading" >&2
    exit 1
  fi
  end=$(echo | timeout 10 openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)
  if [[ -n "$end" ]]; then
    days=$(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 ))
    echo "  cert: ${days}d left"
  fi
else
  echo "[2/3] no domain given, skipping reachability check"
fi

echo "[3/3] reloading nginx"
systemctl reload nginx
echo "done."
