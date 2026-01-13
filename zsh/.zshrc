# ==========================================================
# Main Zsh Configuration - Modular Setup
# ==========================================================
# This file sources all modular configuration files
# Config location: ~/.config/zsh/

# Enable debug mode: export ZSH_DEBUG=1
# Enable safe mode: export ZSH_SAFE_MODE=1

# Source all configuration files in order
# Using _zshrc_config_file to avoid variable collision with oh-my-zsh
for _zshrc_config_file in ~/.config/zsh/*.zsh(N); do
  if [[ -n "$ZSH_DEBUG" ]]; then
    echo "[DEBUG] Loading: $_zshrc_config_file"
  fi
  
  if source "$_zshrc_config_file"; then
    [[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] ✓ Loaded: $_zshrc_config_file"
  else
    echo "[ERROR] ✗ Failed to load: $_zshrc_config_file" >&2
  fi
done

# Source .zshenv if it exists (environment variables)
[[ -f ~/.config/zsh/.zshenv ]] && source ~/.config/zsh/.zshenv

unset _zshrc_config_file
