# ==========================================================
# Oh-My-Zsh Framework Configuration
# ==========================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # We use Oh-My-Posh instead

# Disable security check globally for performance
ZSH_DISABLE_COMPFIX="true"

MAGIC_ENTER_GIT_COMMAND='jj st'
MAGIC_ENTER_OTHER_COMMAND='clear'
ZSH_TMUX_AUTOSTART_ONCE=false
ZSH_TMUX_AUTONAME_SESSION=true

plugins=(
  aliases
  alias-finder
  docker
  eza
  fzf
  fzf-tab
  git
  grc
  jj
  magic-enter
  npm
  python
  thefuck
  tmux
  uv
  zoxide
)

zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status' yes
zstyle ':omz:plugins:eza' 'icons' yes

zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' longer yes
zstyle ':omz:plugins:alias-finder' exact yes
zstyle ':omz:plugins:alias-finder' cheaper yes

# OPTIMIZED: Function-wrapped compinit with smart caching
function compinit() {
  # Remove this wrapper so it doesn't loop
  unset -f compinit
  autoload -Uz compinit

  local dump="$HOME/.zcompdump-${HOST%%.*}-${ZSH_VERSION}"
  [[ -f "$dump" ]] || dump="$HOME/.zcompdump"

  # Use a simple age check (72000s = 20h)
  # stat -f %m is the BSD/Mac way to get Unix timestamp of modification
  if [[ -s "$dump" && $(( $(date +%s) - $(stat -f %m "$dump" 2>/dev/null || echo 0) )) -lt 72000 ]]; then
    compinit -C -d "$dump" "$@"
    debug_log "Loaded compinit from cache (fast mode)"
  else
    compinit -i -d "$dump" "$@"
    touch "$dump" # Ensure timestamp is updated
    debug_log "Regenerated compinit cache"
  fi
}

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
  debug_log "Oh-My-Zsh initialized"
else
  error_log "Oh-My-Zsh not found at $ZSH"
fi

[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh && \
  debug_log "zsh-autosuggestions loaded"

[[ -f /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ]] && \
  source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh && \
  debug_log "zsh-fast-syntax-highlighting loaded"

[[ -s "/opt/homebrew/etc/grc.zsh" ]] && \
  source /opt/homebrew/etc/grc.zsh && \
  debug_log "GRC loaded"

true
