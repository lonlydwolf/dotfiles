#!/usr/bin/env bash

SKETCHYBAR=/opt/homebrew/bin/sketchybar
MEDIA_CONTROL=/opt/homebrew/bin/media-control
JQ=/opt/homebrew/bin/jq

FOREGROUND=0xffcdd6f4
MUTED=0xff6c7086
MAUVE=0xffcba6f7

if [[ ! -x "$MEDIA_CONTROL" || ! -x "$JQ" ]]; then
  "$SKETCHYBAR" --set "$NAME" drawing=off
  exit 0
fi

# Stream events contain metadata under .payload. Routine/system-wake updates
# query once so the widget is initialized even before the next stream event.
if [[ "${SENDER:-}" == "media_update" && -n "${INFO:-}" ]]; then
  data="$(printf '%s' "$INFO" | "$JQ" -c \
    'if type == "object" and has("payload") then .payload else . end' \
    2>/dev/null || true)"
else
  data="$($MEDIA_CONTROL get --no-artwork 2>/dev/null || true)"
fi

if [[ -z "$data" || "$data" == "null" ]]; then
  "$SKETCHYBAR" --set "$NAME" drawing=off
  exit 0
fi

title="$(printf '%s' "$data" | "$JQ" -r '.title // empty' 2>/dev/null)"
artist="$(printf '%s' "$data" | "$JQ" -r '.artist // empty' 2>/dev/null)"
playing="$(printf '%s' "$data" | "$JQ" -r '.playing // false' 2>/dev/null)"

if [[ -z "$title" ]]; then
  "$SKETCHYBAR" --set "$NAME" drawing=off
  exit 0
fi

if [[ -n "$artist" ]]; then
  label="$artist · $title"
else
  label="$title"
fi

if [[ "$playing" == "true" || "$playing" == "1" ]]; then
  icon="󰎆"
  color="$FOREGROUND"
  icon_color="$MAUVE"
else
  icon="󰏤"
  color="$MUTED"
  icon_color="$MUTED"
fi

"$SKETCHYBAR" --set "$NAME" \
  drawing=on \
  icon="$icon" \
  icon.color="$icon_color" \
  label="$label" \
  label.color="$color"
