#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-glucose"
CACHE_FILE="$CACHE_DIR/last.txt"
CACHE_TTL=55

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$CACHE_DIR"

fetch_fresh() {
  local python="$SCRIPT_DIR/.venv/bin/python3"

  if [[ -x "$python" ]]; then
    "$python" "$SCRIPT_DIR/glucose_client.py" 2>/dev/null || echo "--|"
  else
    echo "--|"
  fi
}

render() {
  local value="$1"
  local trend="$2"

  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf "%s %s" "$value" "$trend"
  else
    printf -- "--"
  fi
}

now=$(date +%s)

if [[ -f "$CACHE_FILE" ]]; then
  read -r ts value trend <"$CACHE_FILE" || true

  if [[ -n "${ts:-}" && $((now - ts)) -lt $CACHE_TTL ]]; then
    render "$value" "$trend"
    exit 0
  fi
fi

result="$(fetch_fresh)"

value="${result%%|*}"
trend="${result##*|}"

echo "$now $value $trend" >"$CACHE_FILE"

render "$value" "$trend"
