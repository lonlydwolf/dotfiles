#!/bin/sh

SKETCHYBAR=/opt/homebrew/bin/sketchybar
FOREGROUND=0xffcdd6f4
GREEN=0xffa6e3a1
YELLOW=0xfff9e2af
RED=0xfff38ba8
MUTED=0xff6c7086

BATTERY="$(pmset -g batt)"
PERCENTAGE="$(printf '%s\n' "$BATTERY" | sed -n 's/.*[[:space:]]\([0-9][0-9]*\)%.*/\1/p')"

if [ -z "$PERCENTAGE" ]; then
  "$SKETCHYBAR" --set "$NAME" icon="" icon.color="$MUTED" label="--" label.color="$MUTED"
  exit 0
fi

case "$PERCENTAGE" in
  9[0-9]|100) ICON="" ;;
  [6-8][0-9]) ICON="" ;;
  [3-5][0-9]) ICON="" ;;
  [1-2][0-9]) ICON="" ;;
  *) ICON="" ;;
esac

COLOR="$FOREGROUND"
if printf '%s\n' "$BATTERY" | grep -q 'AC Power'; then
  ICON=""
  COLOR="$GREEN"
elif [ "$PERCENTAGE" -le 15 ]; then
  COLOR="$RED"
elif [ "$PERCENTAGE" -le 30 ]; then
  COLOR="$YELLOW"
fi

"$SKETCHYBAR" --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$PERCENTAGE%" label.color="$COLOR"
