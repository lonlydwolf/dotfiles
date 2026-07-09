#!/usr/bin/env bash
set -euo pipefail

CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-glucose/last.txt"

# Wrap variables in tmux format syntax
GREEN="#{E:@thm_green}"
YELLOW="#{E:@thm_yellow}"
RED="#{E:@thm_red}"
SUBTLE="#{E:@thm_mauve}"

# Helper function to force tmux to resolve the hex color code
print_color() {
  tmux display-message -p "$1"
}

[[ -f "$CACHE_FILE" ]] || {
  print_color "$SUBTLE"
  exit
}

read -r _ value _ <"$CACHE_FILE" || {
  print_color "$SUBTLE"
  exit
}

if ! [[ "$value" =~ ^[0-9]+$ ]]; then
  print_color "$SUBTLE"
  exit
fi

if ((value < 70 || value > 180)); then
  print_color "$RED"
elif ((value < 80 || value > 160)); then
  print_color "$YELLOW"
else
  print_color "$GREEN"
fi
