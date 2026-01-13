# ==========================================================
# Oh-My-Posh Prompt Initialization
# ==========================================================

if ! command_exists oh-my-posh; then
  error_log "oh-my-posh not found - install: brew install jandedobbeleer/oh-my-posh/oh-my-posh"
  return 1
fi

omp_config="$HOME/.config/oh-my-posh/oh-my-posh.toml"
omp_cache="$HOME/.config/oh-my-posh/init.zsh"

# Verify config exists
if [[ ! -f "$omp_config" ]]; then
  error_log "Oh-My-Posh config not found: $omp_config"
  return 1
fi

# Export theme globally
export POSH_THEME="$omp_config"

# OPTIMIZED: mkdir-based atomic locking (flock not available on macOS by default)
if [[ ! -f "$omp_cache" || "$omp_config" -nt "$omp_cache" ]]; then
  local lockdir="/tmp/omp_init_$USER.lock"
  
  # Atomic lock via mkdir
  if mkdir "$lockdir" 2>/dev/null; then
    trap 'rmdir "$lockdir" 2>/dev/null' EXIT INT TERM
    
    debug_log "Regenerating Oh-My-Posh cache..."
    
    # Generate directly (no sed needed since POSH_THEME is exported globally)
    if oh-my-posh init zsh --config "$omp_config" --print > "$omp_cache.tmp" 2>/dev/null; then
      if [[ -s "$omp_cache.tmp" ]]; then
        mv "$omp_cache.tmp" "$omp_cache"
        debug_log "Oh-My-Posh cache regenerated"
      else
        rm -f "$omp_cache.tmp"
        error_log "Oh-My-Posh cache generation produced empty file"
      fi
    else
      rm -f "$omp_cache.tmp"
      error_log "Oh-My-Posh cache generation failed"
    fi
    
    rmdir "$lockdir" 2>/dev/null
    trap - EXIT INT TERM
  else
    debug_log "Another process is regenerating Oh-My-Posh cache"
  fi
fi

# Source the cache
if [[ -f "$omp_cache" ]]; then
  source "$omp_cache"
  debug_log "Oh-My-Posh prompt loaded"
else
  error_log "Oh-My-Posh cache not found - prompt may not display correctly"
fi

# Window Resize Handler
TRAPWINCH() {
  local new_size
  new_size=$(stty size 2>/dev/null)
  if [[ -n "$new_size" ]]; then
    export LINES=${new_size%% *}
    export COLUMNS=${new_size##* }
  fi
  
  if typeset -f _omp_precmd >/dev/null; then
    _omp_precmd
  fi
  
  if [[ -o zle ]]; then
    zle reset-prompt
    zle -R
  fi
}
