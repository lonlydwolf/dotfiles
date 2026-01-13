# ==========================================================
# API Keys & Secrets
# ==========================================================
# This file sources sensitive environment variables from ~/.env_vars

secrets_file="$HOME/.env_vars"

if [[ -f "$secrets_file" ]]; then
  # Check file permissions (should be 600 for security)
  if [[ "$(stat -f '%A' "$secrets_file" 2>/dev/null)" != "600" ]]; then
    error_log "WARNING: $secrets_file has insecure permissions!"
    error_log "Fix with: chmod 600 $secrets_file"
  fi
  
  # Check if readable
  if [[ -r "$secrets_file" ]]; then
    source "$secrets_file"
    debug_log "Secrets loaded from $secrets_file"
  else
    error_log "Cannot read $secrets_file - check permissions"
  fi
else
  debug_log "No secrets file found at $secrets_file (optional)"
fi

unset secrets_file
