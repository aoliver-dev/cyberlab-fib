#!/usr/bin/env bash

set -euo pipefail

LOG_FILE="${1:-}"
SSH_FAILURE_THRESHOLD=3

print_header() {
    echo
    echo "========================================"
    echo "$1"
    echo "========================================"
}

validate_file() {
    if [[ -z "$LOG_FILE" ]]; then
        echo "Usage: $0 <log-file>"
        exit 1
    fi

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Error: file '$LOG_FILE' does not exist."
        exit 1
    fi
}

show_basic_statistics() {
    print_header "BASIC STATISTICS"

    echo "File: $LOG_FILE"
    echo "Lines: $(wc -l < "$LOG_FILE")"
    echo "Size: $(du -h "$LOG_FILE" | cut -f1)"
}

detect_log_type() {
    if grep -q "sshd" "$LOG_FILE"; then
        echo "auth"
    elif grep -qE '"(GET|POST|PUT|DELETE|PATCH) ' "$LOG_FILE"; then
        echo "web"
    else
        echo "unknown"
    fi
}

analyze_auth_log() {
    print_header "SSH AUTHENTICATION ANALYSIS"

    local failed_count
    local accepted_count

    failed_count=$(grep -c "Failed password" "$LOG_FILE" || true)
    accepted_count=$(grep -c "Accepted" "$LOG_FILE" || true)

    echo "Failed authentication attempts: $failed_count"
    echo "Successful authentications: $accepted_count"

    echo
    echo "Failed attempts by source IP:"

    grep "Failed password" "$LOG_FILE" \
        | awk '{print $(NF-3)}' \
        | sort \
        | uniq -c \
        | sort -nr || true
}

detect_ssh_bruteforce() {
    print_header "POTENTIAL SSH BRUTE-FORCE ACTIVITY"

    local found=0

    while read -r count ip; do
        if (( count >= SSH_FAILURE_THRESHOLD )); then
            echo "[ALERT] $ip generated $count failed SSH attempts."
            found=1
        fi
    done < <(
        grep "Failed password" "$LOG_FILE" \
            | awk '{print $(NF-3)}' \
            | sort \
            | uniq -c \
            | sort -nr
    )

    if (( found == 0 )); then
        echo "No IP exceeded the configured threshold."
    fi
}

analyze_web_log() {
    print_header "WEB LOG ANALYSIS"

    echo "Requests by source IP:"

    cut -d ' ' -f1 "$LOG_FILE" \
        | sort \
        | uniq -c \
        | sort -nr

    echo
    echo "HTTP error responses:"

    grep -E '" (401|403|404) ' "$LOG_FILE" || true
}

detect_suspicious_paths() {
    print_header "SUSPICIOUS WEB PATHS"

    local suspicious_paths=(
        "/admin"
        "/wp-admin"
        "/.env"
        "/.git"
        "/config"
    )

    local path
    local found=0

    for path in "${suspicious_paths[@]}"; do
        if grep -q " $path " "$LOG_FILE"; then
            echo "[ALERT] Request detected for suspicious path: $path"
            found=1
        fi
    done

    if (( found == 0 )); then
        echo "No predefined suspicious paths were detected."
    fi
}

main() {
    validate_file
    show_basic_statistics

    local log_type
    log_type="$(detect_log_type)"

    echo
    echo "Detected log type: $log_type"

    case "$log_type" in
        auth)
            analyze_auth_log
            detect_ssh_bruteforce
            ;;
        web)
            analyze_web_log
            detect_suspicious_paths
            ;;
        *)
            echo "Unsupported or unknown log format."
            exit 2
            ;;
    esac
}

main