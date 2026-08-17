#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://127.0.0.1:8082"
RESULTS_FILE="exercises/web-login-detection/results/traffic-summary.txt"

mkdir -p "$(dirname "$RESULTS_FILE")"
: > "$RESULTS_FILE"

attempt_login() {
  local ip="$1"
  local username="$2"
  local password="$3"
  local label="$4"

  status=$(
    curl -s -o /dev/null -w "%{http_code}" \
      -H "X-Forwarded-For: $ip" \
      -H "User-Agent: CyberLabTrafficGenerator/1.0" \
      -X POST "$BASE_URL/login" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=$username&password=$password"
  )

  echo "ip=$ip username=$username status=$status label=$label" | tee -a "$RESULTS_FILE"
}

echo "Generating simulated web login traffic..."
echo

attempt_login "203.0.113.10" "admin" "wrong1" "brute-force"
attempt_login "203.0.113.10" "admin" "wrong2" "brute-force"
attempt_login "203.0.113.10" "admin" "wrong3" "brute-force"
attempt_login "203.0.113.10" "admin" "wrong4" "brute-force"
attempt_login "203.0.113.10" "admin" "wrong5" "brute-force"

attempt_login "198.51.100.77" "alice" "Password123" "password-spraying"
attempt_login "198.51.100.77" "bob" "Password123" "password-spraying"
attempt_login "198.51.100.77" "charlie" "Password123" "password-spraying"
attempt_login "198.51.100.77" "diana" "Password123" "password-spraying"
attempt_login "198.51.100.77" "eric" "Password123" "password-spraying"

attempt_login "192.0.2.44" "admin" "badpass1" "success-after-failures"
attempt_login "192.0.2.44" "admin" "badpass2" "success-after-failures"
attempt_login "192.0.2.44" "admin" "CyberLab123!" "success-after-failures"

attempt_login "10.0.0.5" "alice" "AliceStrong123!" "normal-success"

echo
echo "Traffic generation finished."
echo "Summary saved to $RESULTS_FILE"
