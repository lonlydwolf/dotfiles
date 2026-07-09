# ==================================================
# FZF Configuration
# ==================================================

# Fast check: Exit early if fzf isn't installed
if (( ! $+commands[fzf] )); then
    echo "fzf not installed"
    return 1
fi

if   (( $+commands[pbcopy]  )); then alias clip='pbcopy'
elif (( $+commands[wl-copy] )); then alias clip='wl-copy'
elif (( $+commands[xclip]   )); then alias clip='xclip -selection clipboard'
fi

# --------------------------------------------------
# Search Engine Overrides (Using 'fd')
# --------------------------------------------------
export FZF_DEFAULT_COMMAND="fd --type f --hidden --strip-cwd-prefix --exclude .git --exclude node_modules --exclude target --exclude .venv"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# --------------------------------------------------
# Base UI Options (Catppuccin Mocha Theme)
# --------------------------------------------------
export FZF_DEFAULT_OPTS="
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=selected-bg:#45475a
  --multi
  --height=40%
  --layout=reverse
  --border=rounded
  --prompt='⚡ '
  --pointer='▶'
  --marker='✓'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-a:select-all'
  --bind='ctrl-d:deselect-all'
  --bind='ctrl-y:execute-silent(echo -n {+} | clip)'
"

# --------------------------------------------------
# Enhanced Ctrl+R (History Search)
# --------------------------------------------------
export FZF_CTRL_R_OPTS="
  --preview-window=hidden
  --with-nth=2..
  --height=70%
  --prompt='  '
  --border-label=' Command History '
  --header='Press CTRL-Y to copy command into clipboard'
  --color=header:#cba6f7
  --bind='ctrl-y:execute-silent(echo -n {2..} | clip)+abort'
"

# --------------------------------------------------
# Enhanced Ctrl+T (File Search)
# --------------------------------------------------
export FZF_CTRL_T_OPTS="
  --prompt='  '
  --border-label=' Find Files '
  --header='CTRL-/ (preview) · CTRL-Y (copy path)'
  --color=header:#cba6f7
  --bind='ctrl-/:change-preview-window(down|hidden|)'
  --bind='ctrl-y:execute-silent(echo -n {} | clip)+abort'
  --preview='if [ -d {} ]; then
    eza --tree --level=2 --icons --color=always {}
  else
    bat -n --color=always --line-range :500 {}
  fi'
"

_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}
zle -N _fzf_file_no_hidden
