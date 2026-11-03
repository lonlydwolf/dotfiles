#!/usr/bin/env bash
# One backend read for both color and text, so they always match.

fields="$("$HOME/.config/cgm/cgm-status.sh" 2>/dev/null |
  /opt/homebrew/bin/jq -r 'if .available == true then [.severity, .text] | @tsv else empty end' 2>/dev/null)"
IFS=$'\t' read -r severity text <<<"$fields"

case "$severity" in
  critical) color="#{E:@thm_red}" ;;
  warning) color="#{E:@thm_yellow}" ;;
  normal) color="#{E:@thm_green}" ;;
  *) color="#{E:@thm_mauve}" ;;
esac

printf '#[fg=%s] 󱄦 %s ' "$(tmux display-message -p "$color")" "${text:---}"
