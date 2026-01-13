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

# Enhanced CD with FZF - Interactive directory selection
function cdi() {
  if ! command_exists fd || ! command_exists fzf; then
    error_log "cdi requires fd and fzf"
    return 1
  fi
  
  local dir
  dir=$(fd --type d --follow --exclude .git --exclude node_modules --exclude .venv \
    --exclude Library --exclude Applications --exclude Desktop --exclude Downloads \
    --exclude Movies --exclude Music --exclude Pictures --exclude Public --exclude .Trash \
    . "$HOME" | \
    fzf --prompt='  ' \
        --header='Select directory (from ~)' \
        --border-label=' Change Directory ' \
        --preview 'eza --tree --level=2 --icons --color=always {}' \
        --bind 'ctrl-/:toggle-preview')
  [[ -n "$dir" ]] && cd "$dir"
}

# Quick edit with FZF - Find and edit files
function vf() {
  if ! command_exists fd || ! command_exists fzf; then
    error_log "vf requires fd and fzf"
    return 1
  fi
  
  local file
  file=$(fd --type f --hidden --exclude .git --exclude node_modules | \
    fzf --prompt='  ' \
        --header='Select file to edit' \
        --border-label=' Edit File ' \
        --preview 'bat -n --color=always --line-range :500 {}' \
        --bind 'ctrl-/:toggle-preview')
  [[ -n "$file" ]] && nvim "$file"
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

# JJ: Interactive change switcher
function jjsw() {
  if ! command_exists jj; then
    error_log "jjsw requires jj (Jujutsu)"
    return 1
  fi
  
  local change
  change=$(jj log --no-graph --color=always -r 'all()' -T 'change_id.short() ++ " " ++ description.first_line()' | \
    fzf --ansi \
        --prompt='  ' \
        --header='Select change to edit' \
        --border-label=' JJ Changes ' \
        --preview 'jj show --color=always -r {1}' \
        --preview-window=right:60% \
        --bind 'ctrl-/:toggle-preview' | \
    awk '{print $1}')
  [[ -n "$change" ]] && jj edit "$change"
}

# JJ: Interactive file selection for diff
function jjf() {
  if ! command_exists jj; then
    error_log "jjf requires jj (Jujutsu)"
    return 1
  fi
  
  local file
  file=$(jj file list | \
    fzf --prompt='  ' \
        --header='Select file to view diff' \
        --border-label=' JJ Files ' \
        --preview 'jj diff {}' \
        --preview-window=right:60% \
        --bind 'ctrl-/:toggle-preview')
  [[ -n "$file" ]] && echo "$file"
}

debug_log "Custom functions loaded"
