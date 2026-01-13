# ==========================================================
# External Tool Integrations (Lazy-Loaded)
# ==========================================================

# Zoxide (smarter cd)
if command_exists zoxide; then
  eval "$(zoxide init zsh --cmd cd)"
  debug_log "Zoxide initialized"
fi

# Conda (lazy-loaded)
# Only initialize when actually needed to save 100-300ms on startup
if [[ -f "/opt/homebrew/anaconda3/bin/conda" ]]; then
  # Create lazy-load function
  conda() {
    unfunction conda 2>/dev/null
    
    __conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    else
      if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
      else
        export PATH="/opt/homebrew/anaconda3/bin:$PATH"
      fi
    fi
    unset __conda_setup
    
    debug_log "Conda initialized (lazy-loaded)"
    
    # Call conda with original arguments
    conda "$@"
  }
  
  debug_log "Conda lazy-load function created"
fi

# TheFuck (command correction)
if command_exists thefuck; then
  eval "$(thefuck --alias)"
  debug_log "TheFuck initialized"
fi
