# ==========================================================
# Vi Mode Integration for Oh-My-Posh
# ==========================================================
# This script manually handles Vi mode detection and forces 
# Oh-My-Posh to redraw the prompt when switching modes.

function posh_vi_mode_update {
  case "${KEYMAP}" in
    vicmd) export POSH_VI_MODE="N" ;;
    *)     export POSH_VI_MODE="I" ;;
  esac
  
  # Force Oh-My-Posh to regenerate the prompt with the new variable state
  eval "$(_omp_get_prompt primary --eval)"
  zle reset-prompt
}

function zle-keymap-select {
  posh_vi_mode_update
}

# Bind the widget
zle -N zle-keymap-select

# Ensure default state
export POSH_VI_MODE="I"
