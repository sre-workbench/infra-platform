#!/usr/bin/env bash
# Fail if any tracked file contains an IPv4 address outside the documentation ranges.
set -euo pipefail

allowed='^(203\.0\.113\.|198\.51\.100\.|192\.0\.2\.|127\.0\.0\.1$|0\.0\.0\.0$)'
status=0

while IFS= read -r hit; do
  ip="${hit##*:}"
  if ! [[ "$ip" =~ $allowed ]]; then
    echo "Disallowed address in ${hit%:*}"
    status=1
  fi
done < <(git ls-files -z | xargs -0 grep -InoE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' 2>/dev/null | sed -E 's/^([^:]+):[0-9]+:/\1:/')

if [ "$status" -eq 0 ]; then
  echo "Address check: clean"
fi
exit "$status"
