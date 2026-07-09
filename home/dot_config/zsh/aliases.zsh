# ==================================================
# Aliases
# ==================================================

# --------------------------------------------------
# Modern Tool Replacments
# --------------------------------------------------
alias cat='bat'
alias find='fd'
alias grep='rg --color=auto'
alias -g -- --help='--help | bat -plhelp'

# --------------------------------------------------
# Editor
# --------------------------------------------------
alias v='nvim'
alias vim='nvim'

# --------------------------------------------------
# Eza 
# --------------------------------------------------
# Fast check: Only configure if eza is installed
if (( $+commands[eza] )); then

  # Core eza flags
  # --group-directories-first (dirs-first)
  # --git                     (git-status)
  # --icons=auto              (icons)
  local eza_base="eza --group-directories-first --git --icons=auto"

  # Aliases mapping
  alias ls="$eza_base"
  alias la="$eza_base -la"
  alias ll="$eza_base -l"
  alias lD="$eza_base -lD"
  alias lsd="$eza_base -d"
  alias lsdl="$eza_base -dl"
  
  alias ldot="$eza_base -ld .*"
  alias lDD="$eza_base -lDa"
  alias lS="$eza_base -l -ssize"
  alias lT="$eza_base -l -snewest"

fi

# --------------------------------------------------
# Tmux
# --------------------------------------------------
alias tmux-clear='tmux list-panes -a -F "#{pane_id}" | xargs -I {} tmux send-keys -t {} "clear" Enter'

# --------------------------------------------------
# Jujutsu (jj)
# --------------------------------------------------
alias jja='jj abandon'
alias jjb='jj bookmark'
alias jjba='jj bookmark advance'
alias jjbc='jj bookmark create'
alias jjbd='jj bookmark delete'
alias jjbf='jj bookmark forget'
alias jjbl='jj bookmark list'
alias jjbm='jj bookmark move'
alias jjbr='jj bookmark rename'
alias jjbs='jj bookmark set'
alias jjbt='jj bookmark track'
alias jjbu='jj bookmark untrack'
alias jjc='jj commit'
alias jjcmsg='jj commit --message'
alias jjd='jj diff'
alias jjdmsg='jj desc --message'
alias jjds='jj desc'
alias jje='jj edit'
alias jjgcl='jj git clone'
alias jjgf='jj git fetch'
alias jjgfa='jj git fetch --all-remotes'
alias jjgp='jj git push'
alias jjgpa='jj git push --all'
alias jjgpd='jj git push --deleted'
alias jjgpt='jj git push --tracked'
alias jjl='jj log'
alias jjla='jj log -r "all()"'
alias jjn='jj new'
alias jjnt='jj new "trunk()"'
alias jjrb='jj rebase'
alias jjrbm='jj rebase -d "trunk()"'
alias jjrs='jj restore'
alias jjrt='cd "$(jj root || echo .)"'
alias jjsp='jj split'
alias jjsq='jj squash'
alias jjst='jj status'
