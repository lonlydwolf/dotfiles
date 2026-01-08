# Logic to detect languages ONLY inside Git repositories
# Optimized for ZERO LATENCY using native Zsh globbing (No external processes like 'fd')
check_languages() {
  # Reset state immediately
  unset OMP_MULTI_LANG_DETECTED

  # 1. Fast Repo Check (Git or Jujutsu)
  local is_repo=0
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    is_repo=1
  elif command -v jj &>/dev/null && jj root &>/dev/null; then
    is_repo=1
  fi

  if [[ $is_repo -eq 0 ]]; then
    unset OMP_IS_REPO
    return
  fi
  export OMP_IS_REPO=1

  # 2. Zero-Fork Language Detection
  local lang_count=0
  
  # Python
  local py_local=( *.py(N) )
  local py_deep=( */*.py(N) )
  if [[ ${#py_local[@]} -gt 0 || -f "requirements.txt" || -f "pyproject.toml" ]]; then
    unset OMP_PYTHON_DEEP
    ((lang_count++))
  elif [[ ${#py_deep[@]} -gt 0 ]]; then
    export OMP_PYTHON_DEEP=1
    ((lang_count++))
  else
    unset OMP_PYTHON_DEEP
  fi
  
  # Go
  local go_local=( *.go(N) )
  local go_deep=( */*.go(N) )
  if [[ ${#go_local[@]} -gt 0 || -f "go.mod" ]]; then
    unset OMP_GO_DEEP
    ((lang_count++))
  elif [[ ${#go_deep[@]} -gt 0 ]]; then
    export OMP_GO_DEEP=1
    ((lang_count++))
  else
    unset OMP_GO_DEEP
  fi
  
  # Lua
  local lua_local=( *.lua(N) )
  local lua_deep=( */*.lua(N) )
  if [[ ${#lua_local[@]} -gt 0 ]]; then
    unset OMP_LUA_DEEP
    ((lang_count++))
  elif [[ ${#lua_deep[@]} -gt 0 ]]; then
    export OMP_LUA_DEEP=1
    ((lang_count++))
  else
    unset OMP_LUA_DEEP
  fi
  
  # Node/TS
  local ts_local=( *.ts(N) *.js(N) )
  local ts_deep=( */*.ts(N) */*.js(N) )
  if [[ -f "package.json" || ${#ts_local[@]} -gt 0 ]]; then
    unset OMP_NODE_DEEP
    ((lang_count++))
  elif [[ ${#ts_deep[@]} -gt 0 ]]; then
    export OMP_NODE_DEEP=1
    ((lang_count++))
  else
    unset OMP_NODE_DEEP
  fi

  # Rust
  local rust_local=( *.rs(N) )
  local rust_deep=( */*.rs(N) )
  if [[ ${#rust_local[@]} -gt 0 || -f "Cargo.toml" ]]; then
    unset OMP_RUST_DEEP
    ((lang_count++))
  elif [[ ${#rust_deep[@]} -gt 0 ]]; then
    export OMP_RUST_DEEP=1
    ((lang_count++))
  else
    unset OMP_RUST_DEEP
  fi

  # 3. Set Skeleton Flag
  if [[ $lang_count -gt 1 ]]; then
    export OMP_MULTI_LANG_DETECTED=1
  fi
}

# Hook this function to run before every prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd check_languages
add-zsh-hook chpwd check_languages

# Toggle function (Forces SHOW ALL logic)
toggle_langs() {
  if [[ -z "$OMP_SHOW_ALL_LANGS" ]]; then
    export OMP_SHOW_ALL_LANGS=1
    echo "Showing ALL languages (Override)."
  else
    unset OMP_SHOW_ALL_LANGS
    echo "Showing Smart/Skeleton mode."
  fi
}

# Debug function to see what languages are detected
debug_langs() {
  echo "--- OMP State ---"
  echo "OMP_IS_REPO: $OMP_IS_REPO"
  echo "OMP_MULTI_LANG_DETECTED: $OMP_MULTI_LANG_DETECTED"
  echo "OMP_SHOW_ALL_LANGS: $OMP_SHOW_ALL_LANGS"
  echo "--- Deep Detection ---"
  echo "PYTHON_DEEP: $OMP_PYTHON_DEEP"
  echo "GO_DEEP:     $OMP_GO_DEEP"
  echo "LUA_DEEP:    $OMP_LUA_DEEP"
  echo "NODE_DEEP:   $OMP_NODE_DEEP"
  echo "RUST_DEEP:   $OMP_RUST_DEEP"
  echo "-----------------"
}
