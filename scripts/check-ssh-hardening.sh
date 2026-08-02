#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-}"

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

validate_input() {
  if [[ -z "$CONFIG_FILE" ]]; then
    echo "Usage: $0 <sshd_config-file>"
    exit 1
  fi

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: file '$CONFIG_FILE' does not exist."
    exit 1
  fi
}

get_directive() {
  local directive="$1"

  grep -Ei "^[[:space:]]*$directive[[:space:]]+" "$CONFIG_FILE" \
    | tail -n 1 \
    | awk '{print $2}' \
    || true
}

check_setting() {
  local name="$1"
  local expected="$2"
  local value

  value="$(get_directive "$name")"

  if [[ -z "$value" ]]; then
    echo "[WARNING] $name is not explicitly configured. Expected: $expected"
  elif [[ "$value" == "$expected" ]]; then
    echo "[OK] $name is set to $value"
  else
    echo "[RISK] $name is set to $value. Expected: $expected"
  fi
}

check_max_auth_tries() {
  local value
  value="$(get_directive "MaxAuthTries")"

  if [[ -z "$value" ]]; then
    echo "[WARNING] MaxAuthTries is not explicitly configured. Recommended: 3"
  elif (( value <= 3 )); then
    echo "[OK] MaxAuthTries is set to $value"
  else
    echo "[RISK] MaxAuthTries is set to $value. Recommended: 3 or lower"
  fi
}

check_allow_users() {
  if grep -Eiq "^[[:space:]]*AllowUsers[[:space:]]+" "$CONFIG_FILE"; then
    echo "[OK] AllowUsers is configured: $(grep -Ei '^[[:space:]]*AllowUsers[[:space:]]+' "$CONFIG_FILE" | tail -n 1 | cut -d' ' -f2-)"
  else
    echo "[WARNING] AllowUsers is not configured. Consider restricting SSH access to specific users."
  fi
}

main() {
  validate_input

  print_header "SSH HARDENING CHECK"
  echo "File: $CONFIG_FILE"

  print_header "AUTHENTICATION SETTINGS"
  check_setting "PermitRootLogin" "no"
  check_setting "PasswordAuthentication" "no"
  check_setting "PubkeyAuthentication" "yes"
  check_setting "PermitEmptyPasswords" "no"
  check_max_auth_tries

  print_header "ACCESS RESTRICTIONS"
  check_allow_users

  print_header "FEATURE REDUCTION"
  check_setting "X11Forwarding" "no"
  check_setting "AllowTcpForwarding" "no"
}
main
