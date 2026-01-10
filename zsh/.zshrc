# ==========================================================
# Zsh Configuration
# ==========================================================

# --- Path & Environment ---
# Add to your shell profile BEFORE switching
export XDG_CONFIG_HOME="$HOME/.config"
export ZSH="$HOME/.oh-my-zsh"
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
# Prefer Neovim as the default editor
export EDITOR='nvim'
export VISUAL='nvim'

# --- Oh-My-Zsh Setup ---
ZSH_THEME=""

# Magic Enter Plugin Binding
MAGIC_ENTER_GIT_COMMAND='jj st'
MAGIC_ENTER_OTHER_COMMAND='clear'

# Tmux Plugin Config
ZSH_TMUX_AUTOSTART_ONCE=false
ZSH_TMUX_AUTONAME_SESSION=true

# Plugins (Lazy loading not needed for these small lists)
plugins=(
	aliases		# List Available shortcuts
	alias-finder	# Force use of Alias
	docker
	eza		# Smarter ls
	fzf		# Fuzzy Finder integration
	fzf-tab
	git
	grc
	jj		# My new git
	magic-enter
	npm
	python
	thefuck		# Fix previous command with 'fuck'
	tmux
	uv
	zoxide		# Smarter 'cd'
	zsh-interactive-cd
)

# --- Eza Plugin Config ---
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'icons' yes

# --- Temp: Alias finder activation ---
zstyle ':omz:plugins:alias-finder' autoload yes # disabled by default
zstyle ':omz:plugins:alias-finder' longer yes # disabled by default
zstyle ':omz:plugins:alias-finder' exact yes # disabled by default
zstyle ':omz:plugins:alias-finder' cheaper yes # disabled by default


source $ZSH/oh-my-zsh.sh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# --- Advanced Navigation (Zoxide + FZF) ---
# Initialize Zoxide (Replaces 'cd')
eval "$(zoxide init zsh --cmd cd)"

# FZF Integration
# Ctrl+T: Find files
# Ctrl+R: Find history
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Official Catppuccin Mocha Theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi \
--height 40% --layout=reverse --border --prompt='LonlyDWolf> '"
# Better FZF History (Ctrl-R) behavior:
# - No sort: shows history chronologically (easiest to find recent commands)
# - Exact: no fuzzy matching (optional, remove if you prefer fuzzy)
export FZF_CTRL_R_OPTS="--no-sort --exact"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}'"

# --- Vi-Mode & Keybindings ---
# Enable Vi-mode
bindkey -v
export KEYTIMEOUT=20

# Map 'jk' to Escape (The ultimate Neovim cheat code)
bindkey -M viins 'jk' vi-cmd-mode

# Bind Ctrl-R in Vi-insert mode to FZF history
bindkey -M viins '^R' fzf-history-widget

# Fix backspace issues in Vi-mode
bindkey "^?" backward-delete-char

# Remap the clear-screen function from Ctrl-l to Ctrl-e
bindkey "^E" clear-screen

# --- History Management ---
HISTSIZE=50000
SAVEHIST=50000
unsetopt SHARE_HISTORY        # Disable history sharing between concurrent sessions
setopt APPEND_HISTORY         # Append to history file instead of overwriting
setopt INC_APPEND_HISTORY     # Append commands immediately, don't wait for shell exit
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates
setopt HIST_FIND_NO_DUPS      # Don't show duplicates in search
setopt HIST_SAVE_NO_DUPS      # Don't save duplicates

# --- Colorization Tools ---
export BAT_THEME="Catppuccin Mocha"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Enable GRC (Generic Colouriser) if installed
[[ -s "/opt/homebrew/etc/grc.zsh" ]] && source /opt/homebrew/etc/grc.zsh

# --- Aliases ---
# Modern Replacements
alias cat='bat'
alias find='fd'
alias grep='rg'
alias -g -- --help='--help | bat -plhelp'

# Neovim
alias v='nvim'
alias vim='nvim'

# Config editing shortcuts
alias zshconfig="nvim ~/.zshrc"
alias ompconfig="nvim ~/.config/oh-my-posh/bubblesextra.omp.toml"
alias ghosttyconfig="nvim ~/.config/ghostty/config"

# Yazi Shell Wrapper
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
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
# <<< conda initialize <<<


# --- Custom Environment Variables ---
# Source the separate secrets file if it exists and is readable.
# This keeps secrets out of the primary configuration file.
if [ -f ~/.env_vars ] && [ -r ~/.env_vars ]; then
  source ~/.env_vars
fi
# ------------------------------------



# --- Initialization (Optimized Speed) ---
# Cache the Oh-My-Posh init script to avoid generating it on every shell start
# Regenerate if the config file is newer than the cache
omp_config="$HOME/.config/oh-my-posh/oh-my-posh.toml"
omp_cache="$HOME/.config/oh-my-posh/init.zsh"

# Explicitly export the theme for the generic init script
export POSH_THEME="$omp_config"

if [[ ! -f "$omp_cache" || "$omp_config" -nt "$omp_cache" ]]; then
  mkdir -p ~/.config/oh-my-posh
  # Atomic write: generate to temp first to avoid corruption
  oh-my-posh init zsh --config "$omp_config" --print > "$omp_cache.tmp"
  
  if [[ -s "$omp_cache.tmp" ]]; then
    # Inject the POSH_THEME export into the top of the generated script
    # This ensures the script is self-contained and works even if the env var is lost
    sed -i '' "1s|^|export POSH_THEME=\"$omp_config\"\\n|" "$omp_cache.tmp"
    
    # HARDENING: Inject the config flag into the print command calls.
    # We replace '$_omp_executable print' with '$_omp_executable print --config ...'
    # This ensures the config is passed as an argument, not part of the command name.
    sed -i '' "s|\$_omp_executable print|\$_omp_executable print --config \"$omp_config\"|g" "$omp_cache.tmp"
    
    mv "$omp_cache.tmp" "$omp_cache"
  else
    rm -f "$omp_cache.tmp"
    # Fallback or silent failure (will use default/generic if cache exists, or error)
  fi
fi

if [[ -f "$omp_cache" ]]; then
  source "$omp_cache"
fi

# --- Window Resize Handler ---
# Force prompt redraw on resize.
# 1. Update Zsh's dimensions from the OS to be 100% sure.
# 2. Call _omp_precmd to recalculate the prompt spacing for the new width.
TRAPWINCH() {
  local new_size
  new_size=$(stty size 2>/dev/null)
  if [[ -n "$new_size" ]]; then
    export LINES=${new_size%% *}
    export COLUMNS=${new_size##* }
  fi
  
  # Regenerate prompt string with the new COLUMNS value
  _omp_precmd
  
  if [[ -o zle ]]; then
    zle reset-prompt
    zle -R
  fi
}

