# ==================================================
# Sesh (Session Manager)
# ==================================================
#
# Flow for a NEW session:
#   1. Pick a target from `sesh list -i` (tmux / zoxide / config).
#   2. If it's not already a running tmux session:
#        - dotfiles path -> mode is always "dotfiles", no prompt.
#        - anything else -> fzf-prompt for a mode, preselected by
#          _sesh_is_coding_project.
#   3. `sesh connect <target> --command "build-layout <mode>"`
#      --command only fires on session creation (sesh ignores it for
#      sessions that already exist), so reattaching never re-prompts.
#
# Tmuxinator has been fully retired: no --command handoff to it, and
# `sesh.toml`'s `default_session.startup_command` is no longer used
# (see the stripped sesh.toml). All layout logic lives in
# ~/.config/sesh/scripts/build-layout.

typeset -g SESH_DOTFILES_PATH="$HOME/dotfiles"
typeset -g SESH_BUILD_LAYOUT="$HOME/.config/sesh/scripts/build-layout"
typeset -ga SESH_MODES=(agent-coding agent-learning dotfiles learning scratch)

# Shared fzf styling (Catppuccin Mocha) so the mode picker matches the
# session picker.
_sesh_fzf_style() {
  fzf \
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
    --no-multi \
    --cycle \
    "$@"
}

# Zsh port of the old bash is_coding_project() check from `startup`.
# Used only to decide which mode is preselected in the picker.
_sesh_is_coding_project() {
  local root="$1"

  if [[ -f "$root/package.json" || -f "$root/pyproject.toml" || \
        -f "$root/go.mod" || -f "$root/Cargo.toml" ]]; then
    return 0
  fi

  if [[ -d "$root/.git" || -d "$root/.jj" ]]; then
    return 0
  fi

  local -a subrepos=( "$root"/*/.git(/N) "$root"/*/.jj(/N) )
  if ((${#subrepos} > 0 )); then
    return 0
  fi

  return 1
}

# Prompt for a mode, with $1 pre-selected (shown first in the list,
# which is also where fzf's cursor starts by default).
_sesh_pick_mode() {
  local preselect="$1"
  local -a ordered=("$preselect")
  local m
  for m in "${SESH_MODES[@]}"; do
    [[ "$m" == "$preselect" ]] && continue
    ordered+=("$m")
  done

  printf '%s\n' "${ordered[@]}" | _sesh_fzf_style \
    --prompt='⚡ Mode › ' \
    --header='ENTER (select mode) · this only shows for brand-new sessions'
}

function s() {
  if (( ! ${+commands[sesh]} )); then
    error_log "sesh not found - install: go install github.com/joshmedeski/sesh@latest"
    return 1
  fi

  local raw_line

  raw_line=$(sesh list -i | \
    awk '
      /\[34m/ && !tmux_seen {
        print "\033[1;35m━━━━━━━━ TMUX SESSIONS ━━━━━━━━\033[0m"
        tmux_seen = 1
      }
      /\[36m/ && !zoxide_seen {
        print ""
        print "\033[1;35m━━━━━━━━ ZOXIDE ━━━━━━━━━\033[0m"
        zoxide_seen = 1
      }
      { print }
    ' | \
    _sesh_fzf_style \
    --prompt='⚡ Session › ' \
    --header='󱂬 ENTER (connect) · CTRL-Y (copy) · CTRL-/ (help)' \
    --bind='ctrl-y:execute-silent(echo -n {} | sed "s/\x1b\[[0-9;]*m//g" | pbcopy)+abort' \
    --bind='ctrl-/:toggle-header' | \
    grep -v "━━━━"
  )

  [[ -z "$raw_line" ]] && return 0

  # Clean copy for our own logic only (tmux/path checks). The RAW line
  # (icons + ansi intact) is still what gets passed to `sesh connect`,
  # since sesh's own connect parsing expects the same line `sesh list -i`
  # produced.
  # NOTE: deliberately NOT named "path" - that's a special zsh array
  # tied to $PATH, and declaring it `local` here breaks command lookup
  # (sed/awk/fzf/etc) for the rest of this function and anything it calls.
  local clean_line name target_dir
  clean_line=$(print -r -- "$raw_line" | sed -E 's/\x1b\[[0-9;]*m//g' | tr -d '\r') 
  # NOTE: adjust these two fields if your `sesh list -i` layout differs -
  # run `sesh list -i` bare in a terminal to confirm column order.
  name=$(print -r -- "$clean_line" | awk '{print $NF}')
  target_dir=$(sesh list -i -H 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g' | tr -d '\r' | awk -v n="$name" '{
    for (i=1; i<=NF; i++) {
      if ($i == n) {
        print $NF
        exit
      }
    }
  }')

  target_dir=${target_dir/#\~/$HOME}
  [[ -z "$target_dir" ]] && target_dir="$name"


  if [[ -n "$SESH_DEBUG" ]]; then
    print -u2 -- "---- sesh debug ----"
    print -u2 -- "raw_line   = $raw_line"
    print -u2 -- "clean_line = $clean_line"
    print -u2 -- "name       = $name"
    print -u2 -- "target_dir = $target_dir"
    print -u2 -- "---------------------"
  fi

  # Already-running tmux session -> plain reattach, no mode prompt at all.
  if tmux has-session -t "$name" 2>/dev/null; then
    sesh connect "$raw_line"
    return
  fi

  local mode
  if [[ "$target_dir" == "$SESH_DOTFILES_PATH" ]]; then
    mode="dotfiles"
    [[ -n "$SESH_DEBUG" ]] && print -u2 -- "matched dotfiles path -> mode=dotfiles"
  else
    local preselect="learning"
    _sesh_is_coding_project "$target_dir" && preselect="agent-coding"
    [[ -n "$SESH_DEBUG" ]] && print -u2 -- "no dotfiles match, preselect=$preselect"
    mode=$(_sesh_pick_mode "$preselect")
    [[ -z "$mode" ]] && return 0
  fi

  sesh connect "$raw_line" --command "$SESH_BUILD_LAYOUT $mode"
}
