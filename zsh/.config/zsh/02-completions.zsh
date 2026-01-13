# ==========================================================
# Completion System Configuration
# ==========================================================

# OPTIMIZED: Faster carapace check and caching
if (( ${+commands[carapace]} )); then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'

  local carapace_cache="$HOME/.cache/carapace_init.zsh"
  local carapace_bin="$commands[carapace]"

  # Only regenerate if necessary, using internal path logic
  if [[ ! -s "$carapace_cache" || "$carapace_bin" -nt "$carapace_cache" ]]; then
    # Ensure directory exists without a subshell
    [[ -d "${carapace_cache:h}" ]] || mkdir -p "${carapace_cache:h}"
    
    "$carapace_bin" _carapace > "$carapace_cache"
    debug_log "Regenerated carapace cache"
  fi

  source "$carapace_cache"
  debug_log "Carapace completions initialized (cached)"
fi

# ==========================================================
# FZF-Tab Configuration
# ==========================================================

zstyle ':completion:*:git-checkout:*' sort false
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
if command_exists jj; then
  zstyle ':fzf-tab:complete:jj-(diff|show):*' fzf-preview 'jj diff $word'
  zstyle ':fzf-tab:complete:jj-log:*' fzf-preview 'jj log --color=always -r $word'
  zstyle ':fzf-tab:complete:jj-show:*' fzf-preview 'jj show --color=always $word'
  zstyle ':fzf-tab:complete:jj-(edit|new|squash):*' fzf-preview 'jj log --color=always -r $word'
  zstyle ':fzf-tab:complete:jj-file:*' fzf-preview 'bat -n --color=always --line-range :500 $word'
fi

# Preview for git
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
  'case "$group" in
    "modified file") git diff $word | delta ;;
    "recent commit object name") git show --color=always $word | delta ;;
    *) git log --color=always $word ;;
  esac'

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

zstyle ':fzf-tab:*' continuous-trigger '/'
