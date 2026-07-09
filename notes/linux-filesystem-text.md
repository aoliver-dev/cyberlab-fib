# Linux Filesystem and Text Processing Lab

## Objective

The objective of this laboratory was to practise Linux filesystem navigation, file inspection, text searching and basic log analysis.

The exercise used simulated authentication and web logs in order to practise commands commonly used in system administration and cybersecurity analysis.

## Laboratory structure

The laboratory files were stored inside:

```text
exercises/linux-filesystem-lab/
├── logs/
│   ├── auth.log
│   └── web.log
├── reports/
│   ├── basic-analysis.md
│   ├── ssh-failures.txt
│   ├── suspicious-activity.md
│   └── web-errors.txt
└── tmp/
    └── debug.txt
```

The `logs` directory contained simulated authentication and web server logs.

The `reports` directory was used to store analysis results.

The `tmp` directory contained temporary files.

## Filesystem navigation

The following commands were practised:

```bash
pwd
ls
ls -la
ls -lh
cd
find
```

### `pwd`

The `pwd` command displays the absolute path of the current working directory.

Example:

```bash
pwd
```

Example output:

```text
/home/alejandro/cyberlab-fib/exercises/linux-filesystem-lab
```

### `ls`

The `ls` command lists files and directories.

Useful variants:

```bash
ls
ls -la
ls -lh
```

- `ls`: lists visible files and directories.
- `ls -la`: includes hidden files and detailed information.
- `ls -lh`: displays file sizes in human-readable format.

### Special path symbols

The following path symbols were used:

```text
.   current directory
..  parent directory
~   current user's home directory
/   filesystem root
```

Example:

```bash
cd ..
```

moves to the parent directory.

Example:

```bash
cd ~
```

moves to the user's home directory.

## Absolute and relative paths

An absolute path starts from the filesystem root.

Example:

```text
/home/alejandro/cyberlab-fib/exercises/linux-filesystem-lab/logs/auth.log
```

A relative path depends on the current working directory.

Example:

```text
logs/auth.log
```

If the current directory is:

```text
/home/alejandro/cyberlab-fib/exercises/linux-filesystem-lab
```

then the relative path `logs/auth.log` refers to the same file as the previous absolute path.

## File inspection

The following commands were used to inspect file contents:

```bash
cat
head
tail
wc -l
```

### `cat`

Displays the full content of a file:

```bash
cat logs/auth.log
```

### `head`

Displays the first lines of a file:

```bash
head logs/auth.log
```

### `tail`

Displays the last lines of a file:

```bash
tail logs/auth.log
```

A specific number of lines can be selected:

```bash
tail -n 3 logs/auth.log
```

### `wc -l`

Counts the number of lines in a file:

```bash
wc -l logs/auth.log
```

## Searching text with grep

The `grep` command was used to search for specific patterns inside log files.

To find failed SSH login attempts:

```bash
grep "Failed password" logs/auth.log
```

To find successful authentication events:

```bash
grep "Accepted" logs/auth.log
```

To search for activity related to a specific IP address:

```bash
grep "203.0.113.10" logs/auth.log
grep "203.0.113.10" logs/web.log
```

Useful options:

```bash
grep -i "failed" logs/auth.log
grep -n "Failed password" logs/auth.log
grep -c "Failed password" logs/auth.log
```

Meaning:

- `-i`: ignore uppercase and lowercase differences.
- `-n`: display line numbers.
- `-c`: count matching lines.

Extended regular expressions were also used:

```bash
grep -E '" (401|403|404) ' logs/web.log
```

This command searches for HTTP status codes 401, 403 and 404.

## Pipes

The pipe operator:

```text
|
```

sends the output of one command as input to another command.

Example:

```bash
grep "Failed password" logs/auth.log | wc -l
```

The first command extracts failed SSH login attempts, and the second command counts the resulting lines.

This allows several small commands to be combined into a more powerful analysis pipeline.

## Redirection

The following redirection operators were practised:

```text
>   overwrite a file
>>  append to a file
```

Example:

```bash
grep "Failed password" logs/auth.log > reports/ssh-failures.txt
```

This writes the matching lines to `ssh-failures.txt`.

Example:

```bash
grep "404" logs/web.log >> reports/web-errors.txt
```

This appends matching lines to the end of `web-errors.txt`.

## Finding files

The `find` command was used to locate files.

Examples:

```bash
find . -type f
```

Lists all files below the current directory.

```bash
find . -type f -name "*.log"
```

Lists all files ending in `.log`.

```bash
find . -type f -name "*.txt"
```

Lists all `.txt` files.

```bash
find . -type f -name "*incident*"
```

Finds filenames containing the word `incident`.

## Basic log analysis

The following command extracts the first field from each web log line, which contains the client IP address:

```bash
cut -d ' ' -f1 logs/web.log
```

To count requests by IP:

```bash
cut -d ' ' -f1 logs/web.log | sort | uniq -c
```

To sort them by frequency:

```bash
cut -d ' ' -f1 logs/web.log | sort | uniq -c | sort -nr
```

This pipeline performs four steps:

1. Extract the IP address.
2. Sort the IP addresses.
3. Count identical values.
4. Sort the counts from highest to lowest.

## HTTP error analysis

The web log contained several suspicious or failed requests.

Examples:

```text
GET /admin HTTP/1.1" 403
GET /wp-admin HTTP/1.1" 404
GET /.env HTTP/1.1" 404
POST /login HTTP/1.1" 401
```

The status codes mean:

- `401`: authentication required or failed.
- `403`: access forbidden.
- `404`: resource not found.

Repeated failed requests may indicate scanning, enumeration or brute-force activity.

## Mini challenge results

### 1. Number of failed SSH attempts

The number of failed SSH login attempts was obtained with:

```bash
grep "Failed password" logs/auth.log | wc -l
```

Result:

```text
5
```

### 2. IP with the highest number of web requests

The following command was used:

```bash
cut -d ' ' -f1 logs/web.log | sort | uniq -c | sort -nr
```

Result:

```text
3 198.51.100.77
3 203.0.113.10
2 192.168.1.20
1 192.168.1.21
```

Therefore, `198.51.100.77` and `203.0.113.10` had the highest number of requests, with three requests each.

### 3. Suspicious web paths

The suspicious paths observed were:

```text
/admin
/wp-admin
/.env
/login
```

These may indicate:

- attempts to access restricted administration pages;
- scanning for WordPress installations;
- attempts to expose environment files;
- repeated authentication attempts.

### 4. IP that requested `/.env`

The IP was identified with:

```bash
grep "/.env" logs/web.log
```

Result:

```text
203.0.113.10
```

### 5. Suspicious activity summary

Two IP addresses showed suspicious behaviour.

`203.0.113.10` generated:

- several failed SSH login attempts;
- access attempts to `/admin`;
- access attempts to `/wp-admin`;
- an attempt to access `/.env`.

This behaviour is consistent with reconnaissance and enumeration activity.

`198.51.100.77` generated:

- repeated failed SSH login attempts;
- repeated HTTP `401` responses against `/login`.

This behaviour may indicate credential guessing or brute-force attempts.

## Example suspicious activity report

The following structure was used for `reports/suspicious-activity.md`:

```markdown
# Suspicious Activity Report

## IP address: 203.0.113.10

Observed activity:

- Failed SSH login attempts against several usernames.
- Request to `/admin`.
- Request to `/wp-admin`.
- Request to `/.env`.

Assessment:

The IP shows signs of reconnaissance and enumeration activity.

## IP address: 198.51.100.77

Observed activity:

- Repeated failed SSH attempts.
- Repeated POST requests to `/login` returning HTTP 401.

Assessment:

The activity may indicate credential guessing or brute-force attempts.
```

## Security relevance

Linux text-processing tools are very useful in cybersecurity because logs are often stored as plain text.

Commands such as `grep`, `cut`, `sort`, `uniq` and `wc` allow an analyst to:

- filter large volumes of logs;
- identify suspicious IP addresses;
- count repeated failed events;
- detect authentication failures;
- search for specific indicators;
- correlate activity across different log sources.

These commands are especially useful during initial investigation, troubleshooting and incident response.

## Lessons learned

- `pwd`, `ls` and `cd` are fundamental for navigating the filesystem.
- Absolute paths begin from `/`, while relative paths depend on the current directory.
- `cat`, `head`, `tail` and `wc` are useful for inspecting files.
- `grep` is useful for searching specific events inside logs.
- Pipes allow multiple commands to be combined.
- `>` overwrites a file, while `>>` appends content.
- `find` can locate files by type or name.
- `cut`, `sort` and `uniq` can be combined to count repeated IP addresses.
- Basic command-line tools are powerful for log analysis and cybersecurity investigations.