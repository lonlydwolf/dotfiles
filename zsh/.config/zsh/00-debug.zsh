# ==========================================================
# Debug Utilities & Dependency Checker
# ==========================================================

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check dependencies with helpful messages
check_dependency() {
  local cmd=$1
  local required=${2:-false}
  local install_hint=$3
  
  if command_exists "$cmd"; then
    [[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] ✓ Found: $cmd"
    return 0
  else
    if [[ "$required" == "true" ]]; then
      echo "[ERROR] Required dependency missing: $cmd" >&2
      [[ -n "$install_hint" ]] && echo "        Install: $install_hint" >&2
      return 1
    else
      [[ -n "$ZSH_DEBUG" ]] && echo "[WARN]  Optional dependency missing: $cmd"
      return 0
    fi
  fi
}

# Pre-flight dependency check (run only once)
if [[ -z "$ZSH_DEPS_CHECKED" ]]; then
  export ZSH_DEPS_CHECKED=1
  
  # Required dependencies
  check_dependency "nvim" true "brew install neovim"
  check_dependency "fzf" true "brew install fzf"
  check_dependency "fd" true "brew install fd"
  check_dependency "bat" true "brew install bat"
  check_dependency "eza" true "brew install eza"
  check_dependency "rg" true "brew install ripgrep"
  check_dependency "oh-my-posh" true "brew install jandedobbeleer/oh-my-posh/oh-my-posh"
  
  # Optional dependencies
  check_dependency "zoxide" false "brew install zoxide"
  check_dependency "yazi" false "brew install yazi"
  check_dependency "jj" false "brew install jj"
  check_dependency "sesh" false "go install github.com/joshmedeski/sesh@latest"
  check_dependency "conda" false "Visit: https://docs.conda.io/en/latest/miniconda.html"
  check_dependency "thefuck" false "brew install thefuck"
  check_dependency "carapace" false "brew install carapace"
  check_dependency "delta" false "brew install git-delta"
fi

# Debug logging helper - FIXED: Always return 0
debug_log() {
  [[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] $*"
  return 0
}

# Error logging helper
error_log() {
  echo "[ERROR] $*" >&2
}

# Performance profiling (enable with: zmodload zsh/zprof at start of .zshrc)
if [[ -n "$ZSH_PROFILE" ]]; then
  zmodload zsh/zprof
fi
