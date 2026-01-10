# ==========================================================
# OMZ Reload Extensions (Tmux Aware)
# ==========================================================
# Extends 'omz reload' with 'tmux' targeting.
# 'omz reload'      -> Reloads current shell.
# 'omz reload tmux' -> Reloads current shell + all other Tmux panes.

# --- 1. Core Logic (The Clean Restart) ---
# This replicates the original Oh My Zsh reload logic.
_omz_reload_core() {
  # Delete current completion cache
  command rm -f $_comp_dumpfile $ZSH_COMPDUMP

  # Old zsh versions don't have ZSH_ARGZERO
  local zsh_bin="${ZSH_ARGZERO:-${functrace[-1]%:*}}"
  
  # Validate binary path, fallback to system zsh if invalid
  if [[ -z "$zsh_bin" ]] || [[ ! -x "${zsh_bin#-}" ]]; then
    zsh_bin=$(command -v zsh)
  fi

  # Check whether to run a login shell
  if [[ "$zsh_bin" = -* || -o login ]]; then
    exec -l "${zsh_bin#-}"
  else
    exec "$zsh_bin"
  fi
}

# --- 2. The Command Override ---
# Overriding the internal OMZ reload function.
function _omz::reload {
  local target_tmux=0
  
  # Parse arguments
  for arg in "$@"; do
    if [[ "$arg" == "tmux" || "$arg" == "--tmux" ]]; then
      target_tmux=1
    fi
  done

  # A. Tmux Broadcast
  # We send 'omz reload' to other panes so they benefit from the same 
  # logic (cleanup, login check) without further broadcasting.
  if [[ $target_tmux -eq 1 ]] && command -v tmux &>/dev/null; then
    print -P "%F{blue}::%f Reloading all Tmux panes..."
    local current_pane
    current_pane=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
    
    # List all panes, exclude current one to avoid double-reload race
    tmux list-panes -a -F "#{pane_id}" 2>/dev/null |
    grep -v "^${current_pane}$" |
    xargs -I {} tmux send-keys -t {} "omz reload" Enter
  fi

  # B. Local Reload (Default)
  # This happens for the current shell (initiator) or if no tmux flag was passed.
  _omz_reload_core
}