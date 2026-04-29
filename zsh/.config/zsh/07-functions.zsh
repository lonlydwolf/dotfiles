# ==========================================================
# Custom Shell Functions
# ==========================================================

# Sesh (Session Manager)
function s() {
  if ! command_exists sesh; then
    error_log "sesh not found - install: go install github.com/joshmedeski/sesh@latest"
    return 1
  fi
  
  local session
  
  session=$(sesh list -i | \
    awk '
      /\[34m/ && !tmux_seen { 
        print "\033[1;35m━━━━━━━━ TMUX SESSIONS ━━━━━━━━\033[0m"
        tmux_seen = 1 
      }
      /\[33m/ && !tmuxinator_seen { 
        print ""
        print "\033[1;35m━━━━━━ TMUXINATOR ━━━━━━\033[0m"
        tmuxinator_seen = 1 
      }
      /\[36m/ && !zoxide_seen { 
        print ""
        print "\033[1;35m━━━━━━━━ ZOXIDE ━━━━━━━━━\033[0m"
        zoxide_seen = 1 
      }
      { print }
    ' | \
    fzf \
    --prompt='⚡ Session › ' \
    --header='󱂬 ENTER (connect) · CTRL-Y (copy) · CTRL-/ (help)' \
    --border=rounded \
    --border-label=' Sesh Session Manager ' \
    --height=70% \
    --layout=reverse \
    --info=inline \
    --margin=1,3 \
    --padding=1 \
    --ansi \
    --color='fg:#cdd6f4,bg:#1e1e2e,hl:#89b4fa' \
    --color='fg+:#cdd6f4,bg+:#313244,hl+:#89dceb' \
    --color='info:#cba6f7,prompt:#89dceb,pointer:#f38ba8' \
    --color='marker:#a6e3a1,spinner:#f5e0dc,header:#cba6f7' \
    --pointer='▶' \
    --marker='✓' \
    --bind='ctrl-y:execute-silent(echo -n {} | sed "s/\x1b\[[0-9;]*m//g" | pbcopy)+abort' \
    --bind='ctrl-/:toggle-header' \
    --no-multi \
    --cycle | \
    grep -v "━━━━"
  )
  
  [[ -n "$session" ]] && sesh connect "$session"
}

# Yazi Shell Wrapper
function y() {
  if ! command_exists yazi; then
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

# Process killer with FZF
function fkill() {
  if ! command_exists fzf; then
    error_log "fkill requires fzf"
    return 1
  fi
  
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='Select process to kill' | awk '{print $2}')
  if [[ -n "$pid" ]]; then
    echo "$pid" | xargs kill -"${1:-9}"
  fi
}

debug_log "Custom functions loaded"
