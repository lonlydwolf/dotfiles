#!/usr/bin/env bash

CGM_STATUS="$HOME/.config/cgm/cgm-status.sh"
JQ=/opt/homebrew/bin/jq

if [[ ! -x "$CGM_STATUS" || ! -x "$JQ" ]]; then
  printf -- "--"
  exit 0
fi

payload="$($CGM_STATUS 2>/dev/null || true)"
text="$(printf '%s' "$payload" | "$JQ" -r \
  'if .available == true then "\(.value) \(.trend)" else "--" end' \
  2>/dev/null || true)"

printf '%s' "${text:---}"
