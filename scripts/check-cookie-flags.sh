#!/usr/bin/env bash
set -euo pipefail

RESPONSE_FILE="${1:-}"

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

validate_input() {
  if [[ -z "$RESPONSE_FILE" ]]; then
    echo "Usage: $0 <http-response-file>"
    exit 1
  fi

  if [[ ! -f "$RESPONSE_FILE" ]]; then
    echo "Error: file '$RESPONSE_FILE' does not exist."
    exit 1
  fi
}

has_cookie_attribute() {
  local attribute="$1"

  echo "$cookie" \
    | tr -d '\r' \
    | tr ';' '\n' \
    | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
    | grep -Eiq "^${attribute}(=|$)"
}

main() {
  validate_input

  print_header "COOKIE SECURITY FLAG CHECK"
  echo "File: $RESPONSE_FILE"

  cookie=$(grep -i "^Set-Cookie:" "$RESPONSE_FILE" | head -n 1 || true)

  if [[ -z "$cookie" ]]; then
    echo "[WARNING] No Set-Cookie header found."
    exit 0
  fi

  echo "$cookie"

  print_header "FLAGS"

  if has_cookie_attribute "HttpOnly"; then
    echo "[OK] HttpOnly flag present."
  else
    echo "[RISK] HttpOnly flag missing."
  fi

  if has_cookie_attribute "SameSite"; then
    echo "[OK] SameSite attribute present."
  else
    echo "[RISK] SameSite attribute missing."
  fi

  if has_cookie_attribute "Secure"; then
    echo "[OK] Secure flag present."
  else
    echo "[WARNING] Secure flag missing. Sensitive cookies should use Secure over HTTPS."
  fi
}

main
