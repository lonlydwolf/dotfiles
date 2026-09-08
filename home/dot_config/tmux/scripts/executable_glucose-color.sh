#!/usr/bin/env bash

CGM_STATUS="$HOME/.config/cgm/cgm-status.sh"
JQ=/opt/homebrew/bin/jq

# Wrap variables in tmux format syntax.
GREEN="#{E:@thm_green}"
YELLOW="#{E:@thm_yellow}"
RED="#{E:@thm_red}"
SUBTLE="#{E:@thm_mauve}"

print_color() {
  tmux display-message -p "$1"
}

if [[ ! -x "$CGM_STATUS" || ! -x "$JQ" ]]; then
  print_color "$SUBTLE"
  exit 0
fi

payload="$($CGM_STATUS 2>/dev/null || true)"
severity="$(printf '%s' "$payload" | "$JQ" -r '.severity // "unavailable"' 2>/dev/null || true)"

case "$severity" in
  critical) print_color "$RED" ;;
  warning) print_color "$YELLOW" ;;
  normal) print_color "$GREEN" ;;
  *) print_color "$SUBTLE" ;;
esac
