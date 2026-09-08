#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="$SCRIPT_DIR/.venv/bin/python3"

if [[ ! -x "$PYTHON" ]]; then
  printf '{"available":false,"value":null,"trend":"","severity":"unavailable","unit":"mg/dL","fetched_at":%s}\n' "$(date +%s)"
  exit 0
fi

exec "$PYTHON" "$SCRIPT_DIR/cgm_client.py"
