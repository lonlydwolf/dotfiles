# ==================================================
# Yazi (File Explorer)
# ==================================================

# Yazi Shell Wrapper
function y() {
  if ((! commands[yazi] )); then
    error_log "yazi not found - install: brew install yazi"
    return 1
  fi
  
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if [[ -f "$tmp" ]]; then
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
  fi
}

