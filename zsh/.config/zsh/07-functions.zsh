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

# ==================================================
# Herdr + Zoxide Workspace Manager (JSON-Parsed)
# ==================================================

function hrd() {
  if ! command -v herdr >/dev/null 2>&1; then
    error_log "herdr not found - install it first"
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    error_log "jq not found - required for parsing herdr JSON output"
    return 1
  fi
  
  local selected
  
  # Generate the interactive list with category headers
  selected=$( (
    echo "\033[1;35m━━━━━━━━ HERDR WORKSPACES ━━━━━━━━\033[0m"
    # Use jq to extract the workspace ID and label from the JSON array natively
    herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | "\(.workspace_id // .number)  \(.label)"' 2>/dev/null | awk '{print "\033[34m" $0}'
    
    echo ""
    echo "\033[1;35m━━━━━━━━ ZOXIDE DIRECTORIES ━━━━━━━\033[0m"
    zoxide query -l 2>/dev/null | awk '{print "\033[36m" $0}'
  ) | fzf \
    --prompt='⚡ Session › ' \
    --header='󱂬 ENTER (connect) · CTRL-Y (copy) · CTRL-/ (help)' \
    --border=rounded \
    --border-label=' Herdr Session Manager ' \
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
    sed "s/\x1b\[[0-9;]*m//g" | awk '!/━━━━/'
  )

  [[ -z "$selected" ]] && return
  
  # Safe whitespace trimming
  selected=$(echo "$selected" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  # Routing Logic: Handle Zoxide directory paths vs Existing Workspaces
  if [[ "$selected" == /* ]]; then
    local workspace_name=$(basename "$selected")
    
    # Use jq to scan the JSON safely for an identical active workspace label
    local existing_id=$(herdr workspace list 2>/dev/null | jq -r --arg name "$workspace_name" '.result.workspaces[] | select(.label == $name) | .workspace_id // .number' 2>/dev/null | head -n 1)
    
    if [[ -n "$existing_id" ]]; then
      herdr workspace focus "$existing_id" >/dev/null 2>&1
    else
      # Provision a new workspace, silencing the server's confirmation JSON response
      herdr workspace create --cwd "$selected" --label "$workspace_name" --focus >/dev/null 2>&1
    fi
  else
    # Extract the exact compact Workspace ID (e.g., "w1") from the clean line
    local workspace_id=$(echo "$selected" | awk '{print $1}')
    herdr workspace focus "$workspace_id" >/dev/null 2>&1
  fi

  # Boot up the active interactive TUI client layer if you aren't already nested inside it
  if [[ "$HERDR_ENV" != "1" ]]; then
    herdr
  fi
}
