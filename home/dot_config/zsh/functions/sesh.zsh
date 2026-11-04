# ==================================================
# Sesh (Session Manager)
# ==================================================

# Native picker over tmux sessions, configs and zoxide dirs.
# Same flags as the tmux prefix+K popup.
function s() {
  if ((! $+commands[sesh] )); then
    error_log "sesh not found - install: brew install sesh"
    return 1
  fi

  sesh picker --icons --hide-duplicates "$@"
}
