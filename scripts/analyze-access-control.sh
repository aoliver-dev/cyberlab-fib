#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-}"

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

validate_input() {
  if [[ -z "$LOG_FILE" ]]; then
    echo "Usage: $0 <access-control-log-file>"
    exit 1
  fi

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: file '$LOG_FILE' does not exist."
    exit 1
  fi
}

main() {
  validate_input

  print_header "ACCESS CONTROL ANALYSIS"
  echo "File: $LOG_FILE"

  print_header "POTENTIAL IDOR EVENTS"

  grep "PROFILE_VULN" "$LOG_FILE" \
    | grep "result=allowed" \
    | while read -r line; do
        requester=$(echo "$line" | sed -nE 's/.*requester=([^ ]+).*/\1/p')
        target=$(echo "$line" | sed -nE 's/.*target=([^ ]+).*/\1/p')

        if [[ "$requester" != "$target" ]]; then
          echo "[ALERT] Possible IDOR: requester=$requester accessed target=$target through vulnerable endpoint."
        fi
      done

  print_header "FORBIDDEN ACCESS EVENTS"

  grep "result=forbidden" "$LOG_FILE" || echo "No forbidden events found."

  print_header "ADMIN PANEL EVENTS"

  grep "ADMIN_PANEL" "$LOG_FILE" || echo "No admin panel events found."
}

main
