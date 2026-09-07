#!/bin/sh

# @raycast.schemaVersion 1
# @raycast.title Move Window to Workspace 4
# @raycast.mode silent
# @raycast.packageName Yabai Window Management

/opt/homebrew/bin/yabai -m window --space 4 && exec /opt/homebrew/bin/yabai -m space --focus 4
