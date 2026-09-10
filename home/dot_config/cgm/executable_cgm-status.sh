#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="$SCRIPT_DIR/.venv/bin/python3"
REFRESH_DEADLINE="${CGM_REFRESH_DEADLINE:-25}"

unavailable() {
  printf '{"available":false,"value":null,"trend":"","severity":"unavailable","unit":"mg/dL","fetched_at":%s}\n' "$(date +%s)"
}

if [[ ! -x "$PYTHON" ]]; then
  unavailable
  exit 0
fi

# Enforce a whole-process deadline in addition to requests' connect/read
# timeouts. This also releases the Python process's cache lock if a dependency
# hangs outside requests.
"$PYTHON" "$SCRIPT_DIR/cgm_client.py" &
child_pid=$!
watchdog_pid=""

stop_watchdog() {
  [[ -n "$watchdog_pid" ]] || return 0
  # The watchdog shell may currently be waiting on sleep. Stop both so no
  # orphan retains inherited descriptors or lingers until the deadline.
  pkill -TERM -P "$watchdog_pid" 2>/dev/null || true
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  watchdog_pid=""
}

terminate_child() {
  [[ -n "$child_pid" ]] || return 0
  kill -TERM "$child_pid" 2>/dev/null || true
  sleep 1
  kill -KILL "$child_pid" 2>/dev/null || true
  wait "$child_pid" 2>/dev/null || true
  child_pid=""
}

cleanup() {
  stop_watchdog
  terminate_child
}

handle_signal() {
  local status="$1"
  # Prevent a second signal or EXIT from interrupting or re-entering cleanup
  # while waiting for a TERM-resistant backend to die.
  trap - EXIT
  trap '' INT TERM HUP
  cleanup
  exit "$status"
}

trap cleanup EXIT
trap 'handle_signal 130' INT
trap 'handle_signal 143' TERM
trap 'handle_signal 129' HUP

(
  sleep "$REFRESH_DEADLINE"
  kill -TERM "$child_pid" 2>/dev/null || exit 0
  sleep 1
  kill -KILL "$child_pid" 2>/dev/null || true
) </dev/null >/dev/null 2>&1 &
watchdog_pid=$!

status=0
wait "$child_pid" || status=$?
child_pid=""
stop_watchdog

if ((status != 0)); then
  unavailable
fi

exit 0
