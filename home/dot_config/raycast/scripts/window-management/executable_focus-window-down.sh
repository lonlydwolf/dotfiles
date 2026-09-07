#!/bin/sh

# @raycast.schemaVersion 1
# @raycast.title Focus Window Down
# @raycast.mode silent
# @raycast.packageName Yabai Window Management

exec /opt/homebrew/bin/yabai -m window --focus south 2>/dev/null || exit 0
