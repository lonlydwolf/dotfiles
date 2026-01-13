# ==========================================================
# FZF Configuration
# ==========================================================

if ! command_exists fzf; then
  error_log "FZF not found - skipping FZF configuration"
  return 1
fi

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

# Alt+C (Directory Jump)
export FZF_ALT_C_COMMAND="fd --type d --hidden --strip-cwd-prefix --exclude .git . | sort"
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,.venv \
  --preview 'eza --tree --level=2 --icons --color=always {}' \
  --border-label=' Change Directory ' \
  --prompt='  ' \
  --header 'Select directory to jump to' \
  --color header:#cba6f7"

# Source FZF key bindings
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

debug_log "FZF configuration loaded"
