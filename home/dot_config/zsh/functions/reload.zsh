# ==================================================
# Minimal Reload Command (Tmux Aware)
# ==================================================
reload() {
  # Only wipe completion cache if 'clean' or '-c' is passed as an optional argument
  if [[ "$1" == "clean" || "$1" == "-c" || "$2" == "clean" || "$2" == "-c" ]]; then
    command rm -f "$XDG_CACHE_HOME/zsh/zcompdump" "$HOME/.zcompdump"
    print -P "%F{yellow}::%f Completion cache cleared."
  fi

  # Handle TMUX panes propagation if requested
  if [[ "$1" == "tmux" && -n "$TMUX" ]]; then
    tmux list-panes -a -F "#{pane_id}" | grep -v "$(tmux display-message -p '#{pane_id}')" | xargs -I {} tmux send-keys -t {} "reload" Enter
  fi

  # Instantly swap process memory space
  exec zsh
}
