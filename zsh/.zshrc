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

# --- FZF Performance ---
# Use fd instead of find for speed and respecting .gitignore
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ==========================================================
# Enhanced FZF Configuration
# ==========================================================

# Base FZF options with Catppuccin Mocha
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi \
--height 40% \
--layout=reverse \
--border=rounded \
--prompt='⚡ ' \
--pointer='▶' \
--marker='✓' \
--bind='ctrl-/:toggle-preview' \
--bind='ctrl-a:select-all' \
--bind='ctrl-d:deselect-all' \
--bind='ctrl-y:execute-silent(echo -n {+} | pbcopy)'"


# Enhanced Ctrl+R (History Search)
export FZF_CTRL_R_OPTS="
  --preview-window hidden \
  --with-nth=2.. \
  --height 70% \
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' \
  --color header:#cba6f7 \
  --header 'Press CTRL-Y to copy command into clipboard' \
  --border-label=' Command History ' \
  --prompt='  '"

# Enhanced Ctrl+T (File Search)
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target,.venv \
  --preview 'if [ -d {} ]; then eza --tree --level=2 --icons --color=always {}; else bat -n --color=always --line-range :500 {}; fi' \
  --bind 'ctrl-/:change-preview-window(down|hidden|)' \
  --bind 'ctrl-y:execute-silent(echo -n {} | pbcopy)+abort' \
  --border-label=' Find Files ' \
  --prompt='  ' \
  --header 'CTRL-/ (preview) · CTRL-Y (copy path)' \
  --color header:#cba6f7"

# Alt+C (Directory Jump) - Enhanced
# Sort alphabetically
export FZF_ALT_C_COMMAND="fd --type d --hidden --strip-cwd-prefix --exclude .git . | sort"
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,.venv \
  --preview 'eza --tree --level=2 --icons --color=always {}' \
  --border-label=' Change Directory ' \
  --prompt='  ' \
  --header 'Select directory to jump to' \
  --color header:#cba6f7"

# ==========================================================
# Enhanced Tab Completion (fzf-tab)
# ==========================================================

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# Preview for files and directories
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons "$realpath"'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat -n --color=always --line-range :500 "$realpath"'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat -n --color=always --line-range :500 "$realpath"'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'bat -n --color=always --line-range :500 "$realpath"'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat -n --color=always --line-range :500 "$realpath"'

# Preview for kill command
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == *"process"* ]] && ps -p $word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

# Preview for environment variables
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
  fzf-preview 'echo ${(P)word}'

# Preview for jj (Jujutsu)
zstyle ':fzf-tab:complete:jj-(diff|show):*' fzf-preview \
  'jj diff $word'
zstyle ':fzf-tab:complete:jj-log:*' fzf-preview \
  'jj log --color=always -r $word'
zstyle ':fzf-tab:complete:jj-show:*' fzf-preview \
  'jj show --color=always $word'
zstyle ':fzf-tab:complete:jj-(edit|new|squash):*' fzf-preview \
  'jj log --color=always -r $word'
zstyle ':fzf-tab:complete:jj-file:*' fzf-preview \
  'bat -n --color=always --line-range :500 $word'

# Preview for git (if you still use it occasionally)
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
  'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git log --color=always $word'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
  'git show --color=always $word | delta'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
  'case "$group" in
    "modified file") git diff $word | delta ;;
    "recent commit object name") git show --color=always $word | delta ;;
    *) git log --color=always $word ;;
  esac'

# Switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Apply Catppuccin Mocha colors to fzf-tab
zstyle ':fzf-tab:*' fzf-flags \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --prompt='⚡ ' \
  --pointer='▶' \
  --marker='✓'

# Continuous completion
zstyle ':fzf-tab:*' continuous-trigger '/'

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

# Sesh (Session Manager)
function s() {
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

# Neovim
alias v='nvim'
alias vim='nvim'

# Config editing shortcuts
alias zshconfig="nvim ~/.zshrc"
alias ompconfig="nvim ~/.config/oh-my-posh/oh-my-posh.toml"
alias ghosttyconfig="nvim ~/.config/ghostty/config"

# Yazi Shell Wrapper
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# ==========================================================
# Additional Useful Functions
# ==========================================================

# Enhanced cd with fzf - interactive directory selection
function cdi() {
  local dir
  dir=$(fd --type d --follow --exclude .git --exclude node_modules --exclude .venv \
    --exclude Library --exclude Applications --exclude Desktop --exclude Downloads \
    --exclude Movies --exclude Music --exclude Pictures --exclude Public --exclude .Trash \
    . "$HOME" | \
    fzf --prompt='  ' \
        --header='Select directory (from ~)' \
        --border-label=' Change Directory ' \
        --preview 'eza --tree --level=2 --icons --color=always {}' \
        --bind 'ctrl-/:toggle-preview')
  [[ -n "$dir" ]] && cd "$dir"
}

# Quick edit with fzf - find and edit files
function vf() {
  local file
  file=$(fd --type f --hidden --exclude .git --exclude node_modules | \
    fzf --prompt='  ' \
        --header='Select file to edit' \
        --border-label=' Edit File ' \
        --preview 'bat -n --color=always --line-range :500 {}' \
        --bind 'ctrl-/:toggle-preview')
  [[ -n "$file" ]] && nvim "$file"
}

# Process killer with fzf
function fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='Select process to kill' | awk '{print $2}')
  if [[ -n "$pid" ]]; then
    echo "$pid" | xargs kill -"${1:-9}"
  fi
}

# JJ: Interactive change switcher
function jjsw() {
  local change
  change=$(jj log --no-graph --color=always -r 'all()' -T 'change_id.short() ++ " " ++ description.first_line()' | \
    fzf --ansi \
        --prompt='  ' \
        --header='Select change to edit' \
        --border-label=' JJ Changes ' \
        --preview 'jj show --color=always -r {1}' \
        --preview-window=right:60% \
        --bind 'ctrl-/:toggle-preview' | \
    awk '{print $1}')
  [[ -n "$change" ]] && jj edit "$change"
}

# JJ: Interactive file selection for diff
function jjf() {
  local file
  file=$(jj file list | \
    fzf --prompt='  ' \
        --header='Select file to view diff' \
        --border-label=' JJ Files ' \
        --preview 'jj diff {}' \
        --preview-window=right:60% \
        --bind 'ctrl-/:toggle-preview')
  [[ -n "$file" ]] && echo "$file"
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

