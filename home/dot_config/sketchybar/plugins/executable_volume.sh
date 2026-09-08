#!/bin/sh

SKETCHYBAR=/opt/homebrew/bin/sketchybar
FOREGROUND=0xffcdd6f4
MUTED=0xff6c7086

VOLUME="${INFO:-}"
case "$VOLUME" in
  ''|*[!0-9]*) VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)" ;;
esac

case "$VOLUME" in
  100|[6-9][0-9]) ICON="󰕾"; COLOR="$FOREGROUND" ;;
  [3-5][0-9]) ICON="󰖀"; COLOR="$FOREGROUND" ;;
  [1-9]|[1-2][0-9]) ICON="󰕿"; COLOR="$FOREGROUND" ;;
  *) ICON="󰖁"; COLOR="$MUTED"; VOLUME=0 ;;
esac

"$SKETCHYBAR" --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$VOLUME%" label.color="$COLOR"
