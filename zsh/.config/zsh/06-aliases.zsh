# ==========================================================
# Command Aliases
# ==========================================================

# Modern Tool Replacements
alias cat='bat'
alias find='fd'
alias grep='rg'
alias -g -- --help='--help | bat -plhelp'

# Neovim
alias v='nvim'
alias vim='nvim'

# Config Editing Shortcuts
alias zshconfig="nvim ~/.zshrc"
alias zshreload="source ~/.zshrc"
alias ompconfig="nvim ~/.config/oh-my-posh/oh-my-posh.toml"
alias ghosttyconfig="nvim ~/.config/ghostty/config"

debug_log "Aliases loaded"
