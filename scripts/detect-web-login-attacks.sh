#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-}"
BRUTE_FORCE_THRESHOLD=5
SPRAYING_USER_THRESHOLD=5

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

validate_input() {
  if [[ -z "$LOG_FILE" ]]; then
    echo "Usage: $0 <web-login-log-file>"
    exit 1
  fi

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: file '$LOG_FILE' does not exist."
    exit 1
  fi
}

extract_field() {
  local field="$1"
  sed -nE "s/.*${field}=([^ ]+).*/\1/p"
}

show_basic_stats() {
  print_header "BASIC STATISTICS"
  echo "File: $LOG_FILE"
  echo "Total login attempts: $(grep -c 'path=/login' "$LOG_FILE" || true)"
  echo "Failed login attempts: $(grep -c 'result=failed' "$LOG_FILE" || true)"
  echo "Successful login attempts: $(grep -c 'result=success' "$LOG_FILE" || true)"
}

show_failed_by_ip() {
  print_header "FAILED LOGINS BY SOURCE IP"

  grep "result=failed" "$LOG_FILE" \
    | extract_field "ip" \
    | sort \
    | uniq -c \
    | sort -nr \
    || true
}

show_failed_by_user() {
  print_header "FAILED LOGINS BY USER"

  grep "result=failed" "$LOG_FILE" \
    | extract_field "username" \
    | sort \
    | uniq -c \
    | sort -nr \
    || true
}

detect_brute_force() {
  print_header "WEB LOGIN BRUTE FORCE DETECTION"

  results=$(
    grep "result=failed" "$LOG_FILE" \
      | while read -r line; do
          ip=$(echo "$line" | extract_field "ip")
          username=$(echo "$line" | extract_field "username")
          echo "$ip $username"
        done \
      | sort \
      | uniq -c \
      | sort -nr \
      | awk -v threshold="$BRUTE_FORCE_THRESHOLD" '
          $1 >= threshold {
            printf("[ALERT] Possible login brute force from %s against user '\''%s'\'' with %s failed attempts.\n", $2, $3, $1)
          }
        '
  )

  if [[ -n "$results" ]]; then
    echo "$results"
  else
    echo "No brute-force pattern detected."
  fi
}

detect_password_spraying() {
  print_header "WEB PASSWORD SPRAYING DETECTION"

  local found=0

  while read -r ip; do
    user_count=$(
      grep "result=failed" "$LOG_FILE" \
        | grep "ip=$ip " \
        | extract_field "username" \
        | sort -u \
        | wc -l
    )

    if (( user_count >= SPRAYING_USER_THRESHOLD )); then
      echo "[ALERT] Possible password spraying from $ip against $user_count different users."
      found=1
    fi
  done < <(
    grep "result=failed" "$LOG_FILE" \
      | extract_field "ip" \
      | sort -u
  )

  if (( found == 0 )); then
    echo "No password-spraying pattern detected."
  fi
}

detect_success_after_failures() {
  print_header "SUCCESSFUL LOGINS AFTER FAILURES"

  local found=0

  while read -r line; do
    ip=$(echo "$line" | extract_field "ip")
    username=$(echo "$line" | extract_field "username")

    failed_count=$(
      grep "result=failed" "$LOG_FILE" \
        | grep "ip=$ip " \
        | wc -l
    )

    if (( failed_count > 0 )); then
      echo "[WARNING] Successful login for user '$username' from $ip after $failed_count failed attempt(s)."
      found=1
    fi
  done < <(
    grep "result=success" "$LOG_FILE"
  )

  if (( found == 0 )); then
    echo "No successful logins after failures detected."
  fi
}

main() {
  validate_input
  show_basic_stats
  show_failed_by_ip
  show_failed_by_user
  detect_brute_force
  detect_password_spraying
  detect_success_after_failures
}

main
