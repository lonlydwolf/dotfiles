#!/bin/sh

# @raycast.schemaVersion 1
# @raycast.title Move Window to Workspace 2
# @raycast.mode silent
# @raycast.packageName Yabai Window Management

/opt/homebrew/bin/yabai -m window --space 2 && exec /opt/homebrew/bin/yabai -m space --focus 2
