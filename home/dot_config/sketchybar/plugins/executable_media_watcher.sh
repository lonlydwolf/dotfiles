#!/usr/bin/env bash
# Bridge media-control's event stream into a native SketchyBar event.

SKETCHYBAR=/opt/homebrew/bin/sketchybar
MEDIA_CONTROL=/opt/homebrew/bin/media-control
PID_FILE="${TMPDIR:-/tmp}/sketchybar-media-watcher.pid"

if [[ -r "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null)"
  if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
    exit 0
  fi
fi

printf '%s\n' "$$" >"$PID_FILE"
cleanup() {
  if [[ "$(cat "$PID_FILE" 2>/dev/null)" == "$$" ]]; then
    rm -f "$PID_FILE"
  fi
}
trap cleanup EXIT INT TERM HUP

# Reconnect if MediaRemote temporarily disappears, for example after sleep.
while true; do
  "$MEDIA_CONTROL" stream --no-diff --no-artwork 2>/dev/null |
    while IFS= read -r payload; do
      "$SKETCHYBAR" --trigger media_update INFO="$payload"
    done
  sleep 1
done
