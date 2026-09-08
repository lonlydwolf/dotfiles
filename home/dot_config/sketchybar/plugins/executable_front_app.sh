#!/usr/bin/env bash
# shellcheck disable=SC1090

SKETCHYBAR=/opt/homebrew/bin/sketchybar
YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq
ICON_MAP="$HOME/.config/sketchybar/helpers/icon_map.sh"

APP="${INFO:-}"

# A routine --update has no INFO and previously cleared the label. Query the
# focused yabai window in that case so the app name also survives a restart.
if [ -z "$APP" ] && [ -x "$YABAI" ] && [ -x "$JQ" ]; then
  APP="$($YABAI -m query --windows --window 2>/dev/null | $JQ -r '.app // empty' 2>/dev/null)"
fi

# Finder/Desktop may not have a focused yabai window.
if [ -z "$APP" ]; then
  APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)"
fi

[[ -n "$APP" ]] || APP="Desktop"

ICON=":default:"
icon_result="$ICON"
if [[ -r "$ICON_MAP" ]]; then
  source "$ICON_MAP"
  __icon_map "$APP"
  ICON="$icon_result"
fi

"$SKETCHYBAR" --set "$NAME" icon="$ICON" label="$APP" label.drawing=on
