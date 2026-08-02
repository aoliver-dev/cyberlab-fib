#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-}"
THRESHOLD="${2:-5}"

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

validate_input() {
  if [[ -z "$LOG_FILE" ]]; then
    echo "Usage: $0 <auth-log-file> [threshold]"
    exit 1
  fi

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: file '$LOG_FILE' does not exist."
    exit 1
  fi

  if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: threshold must be a number."
    exit 1
  fi
}

extract_ip() {
  sed -E 's/.* from ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) port .*/\1/'
}

main() {
  validate_input

  print_header "FAIL2BAN-STYLE SSH BAN SIMULATION"
  echo "File: $LOG_FILE"
  echo "Threshold: $THRESHOLD failed attempt(s)"

  print_header "FAILED ATTEMPTS BY IP"

  grep "Failed password" "$LOG_FILE" \
    | extract_ip \
    | sort \
    | uniq -c \
    | sort -nr \
    || true

  print_header "BAN DECISIONS"

  local banned=0

  while read -r count ip; do
    if (( count >= THRESHOLD )); then
      echo "[BAN] $ip exceeded threshold with $count failed SSH attempt(s)."
      banned=1
    else
      echo "[ALLOW] $ip has $count failed SSH attempt(s), below threshold."
    fi
  done < <(
    grep "Failed password" "$LOG_FILE" \
      | extract_ip \
      | sort \
      | uniq -c \
      | sort -nr
  )

  if (( banned == 0 )); then
    echo "No IPs would be banned."
  fi
}

main
