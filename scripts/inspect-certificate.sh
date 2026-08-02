#!/usr/bin/env bash
set -euo pipefail

CERT_FILE="${1:-}"

print_header() {
  echo
  echo "========================================"
  echo "$1"
  echo "========================================"
}

validate_input() {
  if [[ -z "$CERT_FILE" ]]; then
    echo "Usage: $0 <certificate-file>"
    exit 1
  fi

  if [[ ! -f "$CERT_FILE" ]]; then
    echo "Error: file '$CERT_FILE' does not exist."
    exit 1
  fi
}

main() {
  validate_input

  print_header "CERTIFICATE INSPECTION"
  echo "File: $CERT_FILE"

  print_header "IDENTITY"
  openssl x509 -in "$CERT_FILE" -noout -subject -issuer

  print_header "VALIDITY"
  openssl x509 -in "$CERT_FILE" -noout -dates

  print_header "SERIAL NUMBER"
  openssl x509 -in "$CERT_FILE" -noout -serial

  print_header "SHA-256 FINGERPRINT"
  openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha256

  print_header "FILE SHA-256"
  sha256sum "$CERT_FILE"
}

main
