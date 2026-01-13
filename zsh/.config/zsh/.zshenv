# ==========================================================
# Core Environment Variables
# ==========================================================
# Loaded first by all shells (login, interactive, non-interactive)

export XDG_CONFIG_HOME="$HOME/.config"
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# Colorization
export BAT_THEME="Catppuccin Mocha"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# FZF Performance - Use fd instead of find
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Locale (if needed)
# export LANG=en_US.UTF-8
# export LC_ALL=en_US.UTF-8
