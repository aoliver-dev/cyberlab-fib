#!/usr/bin/env bash

set -euo pipefail

echo "================================"
echo "       SYSTEM INFORMATION"
echo "================================"

echo
echo "Current user:"
whoami

echo
echo "Hostname:"
hostname

echo
echo "Operating system:"
grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"'

echo
echo "Kernel version:"
uname -r

echo
echo "Architecture:"
uname -m

echo
echo "CPU information:"
LC_ALL=C lscpu | grep -E '^(Model name|CPU\(s\)):'

echo
echo "Memory usage:"
free -h

echo
echo "Root filesystem usage:"
df -h /

echo
echo "System uptime:"
uptime -p

echo
echo "Collection date:"
date --iso-8601=seconds