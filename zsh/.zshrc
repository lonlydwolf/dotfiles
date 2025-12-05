# ==========================================================
# Zsh Configuration - "The Construct"
# ==========================================================

# --- 1. Path & Environment ---
export ZSH="$HOME/.oh-my-zsh"
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
# Prefer Neovim as the default editor
export EDITOR='nvim'
export VISUAL='nvim'

# --- 2. Oh-My-Zsh Setup ---
# Disable internal theme (Starship handles this)
ZSH_THEME=""

# Plugins (Lazy loading not needed for these small lists)
plugins=(
	git
	docker
	python
	fzf          # Fuzzy Finder integration
	zoxide       # Smarter 'cd'
	vi-mode      # Standard Vim bindings helper
	thefuck      # Fix previous command with 'fuck'
)

source $ZSH/oh-my-zsh.sh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# --- 3. Advanced Navigation (Zoxide + FZF) ---
# Initialize Zoxide (Replaces 'cd')
eval "$(zoxide init zsh --cmd cd)"

# FZF Integration
# Ctrl+T: Find files
# Ctrl+R: Find history
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --prompt='Matrix> '"

# --- 4. Vi-Mode & Keybindings ---
# Enable Vi-mode
bindkey -v
export KEYTIMEOUT=1

# Map 'jk' to Escape (The ultimate Neovim cheat code)
bindkey -M viins 'jk' vi-cmd-mode

# Fix backspace issues in Vi-mode
bindkey "^?" backward-delete-char

# --- 5. History Management ---
HISTSIZE=10000
SAVEHIST=10000
unsetopt SHARE_HISTORY        # Disable history sharing between concurrent sessions
setopt APPEND_HISTORY         # Append to history file instead of overwriting
setopt INC_APPEND_HISTORY     # Append commands immediately, don't wait for shell exit
setopt HIST_IGNORE_DUPS       # Don't record duplicates
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicates
setopt HIST_FIND_NO_DUPS      # Don't show duplicates in search
setopt HIST_SAVE_NO_DUPS      # Don't save duplicates

# --- Colorization Tools ---
export BAT_THEME="ansi"
# Enable GRC (Generic Colouriser) if installed
[[ -s "/opt/homebrew/etc/grc.zsh" ]] && source /opt/homebrew/etc/grc.zsh

# --- 6. Aliases ---
# Modern Replacements
alias ls='eza --icons --git --group-directories-first'
alias ll='eza -l --icons --git --group-directories-first'
alias la='eza -la --icons --git'
alias cat='bat'
alias find='fd'
alias grep='rg'

# Neovim
alias v='nvim'
alias vim='nvim'

# Tmux
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'

# Config editing shortcuts
alias zshconfig="nvim ~/.zshrc"
alias ompconfig="nvim ~/.config/oh-my-posh/bubblesextra.omp.json"
alias ghosttyconfig="nvim ~/.config/ghostty/config"
alias tmuxconfig="nvim ~/.tmux.conf"

# Logic to detect languages ONLY inside Git repositories
# Optimized for ZERO LATENCY using native Zsh globbing (No external processes like 'fd')
check_languages() {
  # Reset state immediately
  unset OMP_MULTI_LANG_DETECTED

  # 1. Fast Git Check
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    unset OMP_IS_GIT_REPO
    return
  fi
  export OMP_IS_GIT_REPO=1

  # 2. Zero-Fork Language Detection
  # Use Zsh array count with (N) nullglob qualifier. 
  # This is the correct way to check for existence without false positives.
  local lang_count=0
  
  # Python
  local py_files=( *.py(N) */*.py(N) )
  if [[ ${#py_files[@]} -gt 0 || -f "requirements.txt" || -f "pyproject.toml" ]]; then
    ((lang_count++))
  fi
  
  # Go
  local go_files=( *.go(N) */*.go(N) )
  if [[ ${#go_files[@]} -gt 0 || -f "go.mod" ]]; then
    ((lang_count++))
  fi
  
  # Lua
  local lua_files=( *.lua(N) */*.lua(N) )
  if [[ ${#lua_files[@]} -gt 0 ]]; then
    ((lang_count++))
  fi
  
  # Node/TS
  local ts_files=( *.ts(N) */*.ts(N) *.js(N) */*.js(N) )
  if [[ -f "package.json" || ${#ts_files[@]} -gt 0 ]]; then
    ((lang_count++))
  fi

  # 3. Set Skeleton Flag
  if [[ $lang_count -gt 1 ]]; then
    export OMP_MULTI_LANG_DETECTED=1
  fi
}

# Hook this function to run before every prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd check_languages
add-zsh-hook chpwd check_languages

# Toggle function (Forces SHOW ALL logic)
toggle_langs() {
  if [[ -z "$OMP_SHOW_ALL_LANGS" ]]; then
    export OMP_SHOW_ALL_LANGS=1
    echo "Showing ALL languages (Override)."
  else
    unset OMP_SHOW_ALL_LANGS
    echo "Showing Smart/Skeleton mode."
  fi
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

# --- 8. Window Resize Handler ---
# Force prompt redraw when the terminal window is resized to fix alignment
TRAPWINCH() {
  zle && zle reset-prompt
}

# --- Custom Environment Variables ---
# Source the separate secrets file if it exists and is readable.
# This keeps secrets out of the primary configuration file.
if [ -f ~/.env_vars ] && [ -r ~/.env_vars ]; then
  source ~/.env_vars
fi
# ------------------------------------



# --- 7. Initialization (Optimized Speed) ---
# Cache the Oh-My-Posh init script to avoid generating it on every shell start
if [[ ! -f ~/.config/oh-my-posh/init.zsh ]]; then
  mkdir -p ~/.config/oh-my-posh
  oh-my-posh init zsh --config ~/.config/oh-my-posh/bubblesextra.omp.json --print > ~/.config/oh-my-posh/init.zsh
fi
source ~/.config/oh-my-posh/init.zsh
