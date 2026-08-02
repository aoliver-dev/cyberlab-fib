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
    echo "Usage: $0 <auth-log-file>"
    exit 1
  fi

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: file '$LOG_FILE' does not exist."
    exit 1
  fi
}

extract_failed_user() {
  sed -E 's/.*Failed password for (invalid user )?([^ ]+) from.*/\2/'
}

extract_ip() {
  sed -E 's/.* from ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) port .*/\1/'
}

show_basic_stats() {
  print_header "BASIC STATISTICS"
  echo "File: $LOG_FILE"
  echo "Total lines: $(wc -l < "$LOG_FILE")"
  echo "Failed SSH logins: $(grep -c 'Failed password' "$LOG_FILE" || true)"
  echo "Successful SSH logins: $(grep -c 'Accepted' "$LOG_FILE" || true)"
}

show_failed_by_ip() {
  print_header "FAILED SSH LOGINS BY SOURCE IP"

  grep "Failed password" "$LOG_FILE" \
    | extract_ip \
    | sort \
    | uniq -c \
    | sort -nr \
    || true
}

show_failed_by_user() {
  print_header "FAILED SSH LOGINS BY USER"

  grep "Failed password" "$LOG_FILE" \
    | extract_failed_user \
    | sort \
    | uniq -c \
    | sort -nr \
    || true
}

detect_brute_force() {
  print_header "BRUTE FORCE DETECTION"

  local found=0

  while read -r count ip user; do
    if (( count >= BRUTE_FORCE_THRESHOLD )); then
      echo "[ALERT] Possible brute force from $ip against user '$user' with $count failed attempts."
      found=1
    fi
  done < <(
    grep "Failed password" "$LOG_FILE" \
      | while read -r line; do
          ip=$(echo "$line" | extract_ip)
          user=$(echo "$line" | extract_failed_user)
          echo "$ip $user"
        done \
      | sort \
      | uniq -c \
      | sort -nr
  )

  if (( found == 0 )); then
    echo "No brute force pattern detected."
  fi
}

detect_password_spraying() {
  print_header "PASSWORD SPRAYING DETECTION"

  local found=0

  while read -r ip; do
    user_count=$(
      grep "Failed password" "$LOG_FILE" \
        | grep " from $ip " \
        | extract_failed_user \
        | sort -u \
        | wc -l
    )

    if (( user_count >= SPRAYING_USER_THRESHOLD )); then
      echo "[ALERT] Possible password spraying from $ip against $user_count different users."
      found=1
    fi
  done < <(
    grep "Failed password" "$LOG_FILE" \
      | extract_ip \
      | sort -u
  )

  if (( found == 0 )); then
    echo "No password spraying pattern detected."
  fi
}

detect_success_after_failures() {
  print_header "SUCCESSFUL LOGINS AFTER FAILURES"

  local found=0

  grep "Accepted" "$LOG_FILE" | while read -r line; do
    ip=$(echo "$line" | extract_ip)
    user=$(echo "$line" | sed -E 's/.*Accepted [^ ]+ for ([^ ]+) from.*/\1/')

    failed_count=$(
      grep "Failed password" "$LOG_FILE" \
        | grep -c " from $ip " \
        || true
    )

    if (( failed_count > 0 )); then
      echo "[WARNING] Successful login for user '$user' from $ip after $failed_count failed attempt(s)."
      found=1
    fi
  done
}

detect_shadow_access() {
  print_header "SENSITIVE FILE ACCESS"

  if grep -q "/etc/shadow" "$LOG_FILE"; then
    grep "/etc/shadow" "$LOG_FILE" | while read -r line; do
      echo "[CRITICAL] Access to /etc/shadow detected:"
      echo "$line"
    done
  else
    echo "No /etc/shadow access detected."
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
  detect_shadow_access
}

main
