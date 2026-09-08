#!/bin/sh

# AppleScript does not support negating this setting directly, so query it
# first and then apply the opposite state.
MUTED="$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)"

if [ "$MUTED" = "true" ]; then
  osascript -e 'set volume output muted false'
else
  osascript -e 'set volume output muted true'
fi
