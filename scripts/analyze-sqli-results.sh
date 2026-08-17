#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-exercises/web-sql-injection/requests}"

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

validate_input() {
  if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: directory '$BASE_DIR' does not exist."
    exit 1
  fi
}

count_users() {
  local file="$1"
  grep -c "^user_id=" "$file" || true
}

main() {
  validate_input

  print_header "SQL INJECTION RESULT ANALYSIS"
  echo "Directory: $BASE_DIR"

  print_header "USER LOOKUP INJECTION"

  vulnerable_file="$BASE_DIR/user-injection-vulnerable.txt"
  secure_file="$BASE_DIR/user-injection-secure.txt"

  vuln_users=$(count_users "$vulnerable_file")
  secure_users=$(count_users "$secure_file")

  if (( vuln_users > 1 )); then
    echo "[ALERT] Vulnerable endpoint returned $vuln_users users for injected id parameter."
  else
    echo "[OK] Vulnerable endpoint did not return multiple users."
  fi

  if (( secure_users == 0 )); then
    echo "[OK] Secure endpoint did not return users for injected id parameter."
  else
    echo "[RISK] Secure endpoint returned $secure_users user(s) for injected id parameter."
  fi

  print_header "LOGIN BYPASS TEST"

  if grep -q "HTTP/1.0 200 OK" "$BASE_DIR/login-bypass-vulnerable.txt"; then
    echo "[ALERT] Vulnerable login accepted SQL injection payload."
  else
    echo "[OK] Vulnerable login did not accept SQL injection payload."
  fi

  if grep -q "HTTP/1.0 401 Unauthorized" "$BASE_DIR/login-bypass-secure.txt"; then
    echo "[OK] Secure login rejected SQL injection payload."
  else
    echo "[RISK] Secure login did not reject SQL injection payload."
  fi
}

main
