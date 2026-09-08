#!/usr/bin/env bash
# Display the LibreLinkUp reading already used by tmux. glucose-status.sh owns
# the shared 55-second cache, so both bars can use it without polling the API
# independently.
set -u

SKETCHYBAR=/opt/homebrew/bin/sketchybar
STATUS_SCRIPT="$HOME/.config/tmux/scripts/glucose-status.sh"

GREEN=0xffa6e3a1
YELLOW=0xfff9e2af
RED=0xfff38ba8
MUTED=0xff6c7086

reading=""
if [[ -x "$STATUS_SCRIPT" ]]; then
  reading="$($STATUS_SCRIPT 2>/dev/null || true)"
fi

value="${reading%% *}"

if [[ "$value" =~ ^[0-9]+$ ]]; then
  if ((value < 70 || value > 180)); then
    color="$RED"
  elif ((value < 80 || value > 160)); then
    color="$YELLOW"
  else
    color="$GREEN"
  fi
  label="$reading"
else
  color="$MUTED"
  label="--"
fi

"$SKETCHYBAR" --set "$NAME" \
  icon="󱄦" \
  icon.color="$color" \
  label="$label" \
  label.color="$color"
