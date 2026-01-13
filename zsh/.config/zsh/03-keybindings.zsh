# ==========================================================
# Vi-Mode & Keybindings
# ==========================================================

# Enable Vi-mode
bindkey -v
export KEYTIMEOUT=20

# Map 'jk' to Escape (Neovim muscle memory)
bindkey -M viins 'jk' vi-cmd-mode

# Bind Ctrl-R in Vi-insert mode to FZF history
bindkey -M viins '^R' fzf-history-widget

# Fix backspace issues in Vi-mode
bindkey "^?" backward-delete-char

# Remap clear-screen from Ctrl-L to Ctrl-E
bindkey "^E" clear-screen

debug_log "Vi-mode keybindings configured"
