#!/usr/bin/env bash
# Render the neutral CGM backend for SketchyBar.
set -u

SKETCHYBAR=/opt/homebrew/bin/sketchybar
CGM_STATUS="$HOME/.config/cgm/cgm-status.sh"
JQ=/opt/homebrew/bin/jq

GREEN=0xffa6e3a1
YELLOW=0xfff9e2af
RED=0xfff38ba8
MUTED=0xff6c7086

fields=""
if [[ -x "$CGM_STATUS" && -x "$JQ" ]]; then
  payload="$($CGM_STATUS 2>/dev/null || true)"
  fields="$(printf '%s' "$payload" | "$JQ" -r \
    'if .available == true then [.value, .trend, .severity] | @tsv else empty end' \
    2>/dev/null || true)"
fi

if [[ -n "$fields" ]]; then
  IFS=$'\t' read -r value trend severity <<<"$fields"
  label="$value $trend"
  case "$severity" in
    critical) color="$RED" ;;
    warning) color="$YELLOW" ;;
    normal) color="$GREEN" ;;
    *) color="$MUTED" ;;
  esac
else
  label="--"
  color="$MUTED"
fi

"$SKETCHYBAR" --set "$NAME" \
  icon="󱄦" \
  icon.color="$color" \
  label="$label" \
  label.color="$color"
