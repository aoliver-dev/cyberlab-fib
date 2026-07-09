# Bash Log Analyzer

## Objective

The objective of this project was to build a Bash script capable of analyzing simulated authentication and web logs.

The script was designed to automate repetitive log-analysis tasks and identify simple indicators of suspicious activity.

The main goals were:

- Validate user input.
- Detect the type of log automatically.
- Analyze SSH authentication events.
- Analyze web server requests.
- Detect simple brute-force patterns.
- Detect access to suspicious web paths.
- Organize the script using functions and structured control flow.

## Script location

The script is located at:

```text
scripts/analyze-logs.sh
```

It can be executed with:

```bash
./scripts/analyze-logs.sh <log-file>
```

## Usage examples

Authentication log:

```bash
./scripts/analyze-logs.sh exercises/linux-filesystem-lab/logs/auth.log
```

Web log:

```bash
./scripts/analyze-logs.sh exercises/linux-filesystem-lab/logs/web.log
```

Invalid file:

```bash
./scripts/analyze-logs.sh no-existe.log
```

No arguments:

```bash
./scripts/analyze-logs.sh
```

## Input validation

The script validates that a file path has been provided.

The following Bash expression is used:

```bash
[[ -z "$LOG_FILE" ]]
```

This checks whether the variable is empty.

If no argument is provided, the script displays:

```text
Usage: ./scripts/analyze-logs.sh <log-file>
```

The script also verifies that the file exists:

```bash
[[ ! -f "$LOG_FILE" ]]
```

If the file does not exist, the script exits with an error.

Example:

```text
Error: file 'no-existe.log' does not exist.
```

Input validation is important because it prevents the script from continuing with invalid data.

## Variables

The first positional argument is stored in:

```bash
LOG_FILE="${1:-}"
```

For example:

```bash
./scripts/analyze-logs.sh auth.log
```

means that:

```text
$1 = auth.log
```

and therefore:

```text
LOG_FILE = auth.log
```

The SSH brute-force detection threshold is stored in:

```bash
SSH_FAILURE_THRESHOLD=3
```

This means that an IP address is considered potentially suspicious when it generates at least three failed SSH authentication attempts.

## Functions

The script is divided into several functions.

This improves readability, separates responsibilities and makes the script easier to maintain.

The main functions are:

```text
print_header
validate_file
show_basic_statistics
detect_log_type
analyze_auth_log
detect_ssh_bruteforce
analyze_web_log
detect_suspicious_paths
main
```

### `print_header`

This function formats section headers.

Example:

```bash
print_header "BASIC STATISTICS"
```

Output:

```text
========================================
BASIC STATISTICS
========================================
```

### `validate_file`

This function verifies that:

- an argument was provided;
- the referenced file exists.

If validation fails, the script terminates with a non-zero exit code.

### `show_basic_statistics`

This function displays:

- file path;
- number of lines;
- file size.

Commands used:

```bash
wc -l
du -h
cut
```

Example output:

```text
File: exercises/linux-filesystem-lab/logs/auth.log
Lines: 8
Size: 4.0K
```

## Automatic log type detection

The script attempts to determine whether the input is an authentication log or a web log.

Authentication logs are detected with:

```bash
grep -q "sshd" "$LOG_FILE"
```

Web logs are detected with:

```bash
grep -qE '"(GET|POST|PUT|DELETE|PATCH) ' "$LOG_FILE"
```

Possible results are:

```text
auth
web
unknown
```

Example:

```text
Detected log type: auth
```

If the format is unknown, the script displays:

```text
Unsupported or unknown log format.
```

and exits.

## SSH authentication analysis

For authentication logs, the script counts failed and successful authentications.

Failed attempts:

```bash
grep -c "Failed password" "$LOG_FILE"
```

Successful authentications:

```bash
grep -c "Accepted" "$LOG_FILE"
```

Example output:

```text
Failed authentication attempts: 5
Successful authentications: 2
```

## Failed SSH attempts by source IP

The script extracts source IP addresses from failed authentication events and counts them.

Pipeline:

```bash
grep "Failed password" "$LOG_FILE" \
    | awk '{print $(NF-3)}' \
    | sort \
    | uniq -c \
    | sort -nr
```

The pipeline performs these steps:

1. Select only failed authentication lines.
2. Extract the source IP field.
3. Sort the IP addresses.
4. Count repeated IP addresses.
5. Sort them from highest to lowest frequency.

Example output:

```text
3 203.0.113.10
2 198.51.100.77
```

## SSH brute-force detection

The script uses the threshold:

```text
3 failed authentication attempts
```

An IP that reaches or exceeds this value generates an alert.

Example:

```text
[ALERT] 203.0.113.10 generated 3 failed SSH attempts.
```

The detection logic uses a `while` loop:

```bash
while read -r count ip; do
    if (( count >= SSH_FAILURE_THRESHOLD )); then
        echo "[ALERT] $ip generated $count failed SSH attempts."
    fi
done
```

This loop processes each IP and its corresponding number of failed attempts.

## Web log analysis

For web logs, the script counts requests by source IP.

Pipeline:

```bash
cut -d ' ' -f1 "$LOG_FILE" \
    | sort \
    | uniq -c \
    | sort -nr
```

Example output:

```text
3 203.0.113.10
3 198.51.100.77
2 192.168.1.20
1 192.168.1.21
```

This makes it easy to identify the most active source addresses.

## HTTP error detection

The script displays HTTP responses with status codes:

```text
401
403
404
```

Command:

```bash
grep -E '" (401|403|404) ' "$LOG_FILE"
```

The codes represent:

- `401`: authentication required or failed;
- `403`: access forbidden;
- `404`: requested resource not found.

Repeated occurrences may indicate:

- credential guessing;
- access to restricted resources;
- enumeration;
- scanning.

## Suspicious web paths

The script checks for access to predefined suspicious paths.

The array is:

```bash
local suspicious_paths=(
    "/admin"
    "/wp-admin"
    "/.env"
    "/.git"
    "/config"
)
```

Each path is checked with a `for` loop.

Example:

```bash
for path in "${suspicious_paths[@]}"; do
    if grep -q " $path " "$LOG_FILE"; then
        echo "[ALERT] Request detected for suspicious path: $path"
    fi
done
```

Example output:

```text
[ALERT] Request detected for suspicious path: /admin
[ALERT] Request detected for suspicious path: /wp-admin
[ALERT] Request detected for suspicious path: /.env
```

These paths may be security-relevant because they can expose:

- administrative interfaces;
- WordPress administration panels;
- environment variables;
- Git repositories;
- configuration files.

## Control flow

The script uses a `case` statement to decide which analysis function to execute.

```bash
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
```

This is clearer than using many nested `if` statements.

## Bash concepts practised

The project used the following Bash concepts:

- shebang;
- strict mode;
- variables;
- positional arguments;
- default values;
- functions;
- conditions;
- numeric comparisons;
- arrays;
- `for` loops;
- `while` loops;
- `case` statements;
- command substitution;
- process substitution;
- pipelines;
- exit codes;
- input validation.

## Strict mode

The script begins with:

```bash
set -euo pipefail
```

This improves reliability.

### `-e`

Stops the script when a command fails.

### `-u`

Treats the use of undefined variables as an error.

### `pipefail`

Causes a pipeline to fail when one of its commands fails.

This helps detect errors that might otherwise go unnoticed.

## Command substitution

The script uses command substitution:

```bash
LOG_TYPE="$(detect_log_type)"
```

The output of the function is stored in a variable.

Another example:

```bash
echo "Lines: $(wc -l < "$LOG_FILE")"
```

The result of the command is inserted into the output.

## Local variables

Functions use local variables such as:

```bash
local failed_count
local accepted_count
```

This limits the scope of the variables to the function where they are used and reduces the risk of accidentally modifying variables elsewhere in the script.

## Security relevance

Automating log analysis is useful in cybersecurity because analysts often need to process large amounts of repetitive data.

This script demonstrates simple forms of detection engineering.

It can identify:

- repeated failed SSH authentication attempts;
- suspicious source IP addresses;
- HTTP authentication failures;
- access to restricted paths;
- potential reconnaissance activity.

The project also demonstrates that detection logic should not only identify events but explain why they may be suspicious.

## False positives

A threshold-based alert does not automatically mean that an attack occurred.

For example, three failed SSH attempts could be caused by:

- a user forgetting a password;
- an incorrectly configured automation;
- a legitimate administrator;
- a monitoring system.

Therefore, alerts should be treated as indicators that require investigation.

Real detection systems usually consider:

- time windows;
- source reputation;
- usernames targeted;
- asset criticality;
- historical behaviour;
- multiple correlated events.

## Limitations

The current version has several limitations:

- It assumes specific log formats.
- The SSH threshold is fixed at three attempts.
- It does not use time windows.
- It does not correlate activity across multiple hosts.
- It does not store historical results.
- It has not been specifically tested with IPv6.
- It does not distinguish internal and external IP ranges.
- It may produce false positives.
- It only detects a small predefined list of suspicious web paths.

These limitations are acceptable for an educational project but would need to be addressed in a production environment.

## Possible future improvements

Possible improvements include:

- accepting the SSH threshold as a command-line argument;
- detecting repeated HTTP 401 responses by IP;
- supporting additional log formats;
- generating Markdown or JSON reports;
- adding timestamps to alerts;
- grouping activity by time window;
- correlating SSH and web events;
- supporting configuration files;
- adding automated tests.

## Example output: authentication log

```text
========================================
BASIC STATISTICS
========================================
File: exercises/linux-filesystem-lab/logs/auth.log
Lines: 8
Size: 4.0K

Detected log type: auth

========================================
SSH AUTHENTICATION ANALYSIS
========================================
Failed authentication attempts: 5
Successful authentications: 2

Failed attempts by source IP:
      3 203.0.113.10
      2 198.51.100.77

========================================
POTENTIAL SSH BRUTE-FORCE ACTIVITY
========================================
[ALERT] 203.0.113.10 generated 3 failed SSH attempts.
```

## Example output: web log

```text
========================================
BASIC STATISTICS
========================================
File: exercises/linux-filesystem-lab/logs/web.log
Lines: 9
Size: 4.0K

Detected log type: web

========================================
WEB LOG ANALYSIS
========================================
Requests by source IP:
      3 203.0.113.10
      3 198.51.100.77
      2 192.168.1.20
      1 192.168.1.21

========================================
SUSPICIOUS WEB PATHS
========================================
[ALERT] Request detected for suspicious path: /admin
[ALERT] Request detected for suspicious path: /wp-admin
[ALERT] Request detected for suspicious path: /.env
```

## Lessons learned

- Bash can be used to automate repetitive security analysis tasks.
- Functions improve code organization and maintainability.
- Input validation prevents avoidable execution errors.
- Pipes allow several small Unix tools to work together.
- Arrays and loops are useful for applying the same logic to multiple indicators.
- Threshold-based detections are simple but can generate false positives.
- Logs provide valuable evidence for security monitoring and incident investigation.
- Detection logic should always be documented together with its assumptions and limitations.