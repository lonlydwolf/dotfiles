#!/usr/bin/env bash
# Emit an update at the next exact minute boundary instead of counting 60
# seconds from SketchyBar's startup time.

SKETCHYBAR=/opt/homebrew/bin/sketchybar
PID_FILE="${TMPDIR:-/tmp}/sketchybar-clock-watcher.pid"

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

while true; do
  seconds="$(date +%S)"
  sleep "$((60 - 10#$seconds))"
  "$SKETCHYBAR" --trigger clock_update
done
