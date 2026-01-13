# ==========================================================
# History Management
# ==========================================================
# Optimized for tmux with separate pane history

HISTSIZE=50000
SAVEHIST=50000

# CRITICAL: For separate tmux pane history
unsetopt SHARE_HISTORY         # Each tmux pane has its own history
setopt APPEND_HISTORY          # Append to history file
setopt INC_APPEND_HISTORY      # Append commands immediately
setopt HIST_IGNORE_DUPS        # Don't record duplicates
setopt HIST_IGNORE_ALL_DUPS    # Remove older duplicates
setopt HIST_FIND_NO_DUPS       # Don't show duplicates in search
setopt HIST_SAVE_NO_DUPS       # Don't save duplicates

debug_log "History configured (separate tmux panes)"
