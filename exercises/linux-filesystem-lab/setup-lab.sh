#!/usr/bin/env bash

set -euo pipefail

mkdir -p logs reports tmp

cat > logs/auth.log <<'EOF'
Jul 08 10:01:11 cyberlab sshd[1001]: Accepted password for analyst from 192.168.1.20 port 52210 ssh2
Jul 08 10:03:45 cyberlab sshd[1002]: Failed password for root from 203.0.113.10 port 44122 ssh2
Jul 08 10:04:02 cyberlab sshd[1003]: Failed password for admin from 203.0.113.10 port 44125 ssh2
Jul 08 10:04:28 cyberlab sshd[1004]: Failed password for test from 203.0.113.10 port 44130 ssh2
Jul 08 10:08:51 cyberlab sshd[1005]: Accepted publickey for responder from 192.168.1.21 port 53002 ssh2
Jul 08 10:15:19 cyberlab sudo: analyst : TTY=pts/0 ; PWD=/home/analyst ; USER=root ; COMMAND=/usr/bin/apt update
Jul 08 10:21:44 cyberlab sshd[1006]: Failed password for root from 198.51.100.77 port 49011 ssh2
Jul 08 10:22:01 cyberlab sshd[1007]: Failed password for root from 198.51.100.77 port 49012 ssh2
EOF

cat > logs/web.log <<'EOF'
192.168.1.20 - - [08/Jul/2026:10:01:10 +0000] "GET / HTTP/1.1" 200 1024
192.168.1.20 - - [08/Jul/2026:10:01:12 +0000] "GET /login HTTP/1.1" 200 2048
203.0.113.10 - - [08/Jul/2026:10:03:45 +0000] "GET /admin HTTP/1.1" 403 512
203.0.113.10 - - [08/Jul/2026:10:04:01 +0000] "GET /wp-admin HTTP/1.1" 404 256
203.0.113.10 - - [08/Jul/2026:10:04:18 +0000] "GET /.env HTTP/1.1" 404 256
198.51.100.77 - - [08/Jul/2026:10:21:42 +0000] "POST /login HTTP/1.1" 401 768
198.51.100.77 - - [08/Jul/2026:10:21:52 +0000] "POST /login HTTP/1.1" 401 768
198.51.100.77 - - [08/Jul/2026:10:22:03 +0000] "POST /login HTTP/1.1" 401 768
192.168.1.21 - - [08/Jul/2026:10:25:11 +0000] "GET /dashboard HTTP/1.1" 200 4096
EOF

cat > reports/incident-notes.txt <<'EOF'
Initial notes for the Linux filesystem and text processing lab.

Observed suspicious IP addresses:
- 203.0.113.10
- 198.51.100.77

Potential indicators:
- repeated SSH failures
- access to sensitive web paths
- repeated login failures
EOF

cat > tmp/debug.txt <<'EOF'
temporary debug file
EOF