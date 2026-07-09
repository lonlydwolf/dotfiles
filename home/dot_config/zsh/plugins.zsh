# ==================================================
# Plugins Management
# ==================================================

ZPLUGINDIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${2}..."
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; return 1; }
  fi
  
  # Account for repository naming differences dynamically
  if [[ -f "${plugin_path}/${2}.plugin.zsh" ]]; then
    source "${plugin_path}/${2}.plugin.zsh"
  elif [[ -f "${plugin_path}/${2}.zsh" ]]; then
    source "${plugin_path}/${2}.zsh"
  fi
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}

# --------------------------------------------------
# CRITICAL LOADING ORDER (Do Not Rearrange)
# --------------------------------------------------

# 1. Base Frameworks & UI Interactive Overlays
_zplugin_load jeffreytse zsh-vi-mode
# _zplugin_load marlonrichert zsh-autocomplete

# 2. Interactive Search & Utility Hooks
# _zplugin_load unixorn fzf-zsh-plugin
_zplugin_load MichaelAquilina zsh-you-should-use
_zplugin_load Aloxaf fzf-tab
_zplugin_load zsh-users zsh-autosuggestions

# 3. Core Highlighting Engine (Must be near the end)
_zplugin_load zdharma-continuum fast-syntax-highlighting

# 4. History Search (Must be loaded AFTER syntax highlighting)
_zplugin_load zsh-users zsh-history-substring-search
