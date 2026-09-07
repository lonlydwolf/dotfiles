#!/bin/sh

# @raycast.schemaVersion 1
# @raycast.title Swap Window Right
# @raycast.mode silent
# @raycast.packageName Yabai Window Management

exec /opt/homebrew/bin/yabai -m window --swap east 2>/dev/null || exit 0
