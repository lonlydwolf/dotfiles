#!/bin/sh

# @raycast.schemaVersion 1
# @raycast.title Swap Window Up
# @raycast.mode silent
# @raycast.packageName Yabai Window Management

exec /opt/homebrew/bin/yabai -m window --swap north 2>/dev/null || exit 0
