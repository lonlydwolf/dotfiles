# ==================================================
# Magic Enter
# ==================================================

export MAGIC_ENTER_GIT_COMMAND="git status -u ."
export MAGIC_ENTER_JJ_COMMAND="jj st --no-pager ."

# if (( $+commands[eza] )); then
#   export MAGIC_ENTER_OTHER_COMMAND="clear && eza --group-directories-first --git --icons=auto"
# else
#   export MAGIC_ENTER_OTHER_COMMAND="clear"
# fi

export MAGIC_ENTER_OTHER_COMMAND="clear"

magic-enter() {
  if [[ -n "$BUFFER" ]]; then
    zle .accept-line
    return
  fi

  if (( $+commands[jj] )) && command jj root >/dev/null 2>&1; then
    BUFFER="$MAGIC_ENTER_JJ_COMMAND"
  elif (( $+commands[git] )) && command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BUFFER="$MAGIC_ENTER_GIT_COMMAND"
  else
    BUFFER="$MAGIC_ENTER_OTHER_COMMAND"
  fi

  zle .accept-line
}

zle -N accept-line magic-enter
