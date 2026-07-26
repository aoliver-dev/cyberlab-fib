# Nmap Basics Lab

## Objective

The objective of this lab was to learn basic host discovery and service enumeration using Nmap in a controlled Docker environment.

The lab focused on:

- discovering active hosts;
- identifying open TCP ports;
- detecting exposed services;
- comparing basic scans with version detection;
- saving scan results;
- understanding the security relevance of network enumeration.

All scans were performed against a local Docker network created specifically for this exercise.

---

## Environment

The lab used a Docker network with the following subnet:

```text
172.32.0.0/24
```

The expected hosts were:

| Host | IP address | Expected service |
|---|---:|---|
| `nmap-web` | `172.32.0.10` | HTTP / Nginx |
| `nmap-ssh` | `172.32.0.20` | SSH |
| `nmap-db` | `172.32.0.30` | MySQL / MariaDB |

The lab was created with Docker Compose:

```bash
docker compose -f exercises/nmap-lab/docker-compose.yml up -d
```

The running containers were checked with:

```bash
docker ps
```

---

## Host discovery

The first step was to discover active hosts in the Docker subnet.

Command used:

```bash
nmap -sn 172.32.0.0/24
```

The `-sn` option performs host discovery without a full port scan.

The discovered hosts were:

```text
172.32.0.1
172.32.0.10
172.32.0.20
172.32.0.30
```

The address `172.32.0.1` corresponds to the Docker network gateway.

The other three addresses correspond to the lab containers:

```text
172.32.0.10 -> nmap-web
172.32.0.20 -> nmap-ssh
172.32.0.30 -> nmap-db
```

Host discovery is useful because it helps identify which systems are alive before performing deeper enumeration.

---

## Basic port scanning

A basic Nmap scan was performed against each host.

### Web server

Command:

```bash
nmap 172.32.0.10
```

Expected relevant result:

```text
80/tcp open http
```

This indicates that the host is exposing a web service on TCP port 80.

### SSH server

Command:

```bash
nmap 172.32.0.20
```

Expected relevant result:

```text
2222/tcp open ssh
```

This indicates that the host is exposing an SSH service.

In this lab, the SSH container commonly exposes SSH on port `2222` rather than the default port `22`.

### Database server

Command:

```bash
nmap 172.32.0.30
```

Expected relevant result:

```text
3306/tcp open mysql
```

This indicates that the host is exposing a MySQL or MariaDB database service.

---

## Version detection

Version detection was performed with:

```bash
nmap -sV 172.32.0.10
nmap -sV 172.32.0.20
nmap -sV 172.32.0.30
```

The `-sV` option attempts to identify the service and version running on each open port.

Compared with a normal scan, `-sV` provides more detail.

For example, instead of only showing:

```text
80/tcp open http
```

Nmap may identify additional information such as:

```text
80/tcp open http nginx
```

Version detection is useful because knowing the exact service can help an analyst:

- understand the exposed attack surface;
- identify outdated services;
- prepare vulnerability research;
- prioritize remediation;
- validate whether an exposed port matches the expected application.

However, `-sV` is noisier than a basic scan because Nmap sends additional probes to identify the service.

---

## Targeted port scanning

A targeted scan was performed against known ports:

```bash
nmap -p 80,2222,3306 172.32.0.10 172.32.0.20 172.32.0.30
```

The `-p` option allows the analyst to define exactly which ports should be scanned.

This is useful when:

- only specific services are relevant;
- the analyst wants a faster scan;
- the scan should avoid unnecessary traffic;
- validating whether expected ports are open or closed.

The difference between a targeted scan and a default scan is:

```text
Default scan:
Nmap scans its default set of common ports.

Targeted scan:
The analyst explicitly decides which ports to test.
```

---

## Top ports scan

The following command was also used:

```bash
nmap --top-ports 20 172.32.0.10 172.32.0.20 172.32.0.30
```

This tells Nmap to scan the 20 most common ports.

This can be useful for quick enumeration when the analyst wants broader coverage than a few manually selected ports, but less traffic than a full scan of all TCP ports.

---

## Aggressive scan

An aggressive scan was tested with:

```bash
nmap -A 172.32.0.10
```

The `-A` option enables additional functionality such as:

- version detection;
- default NSE scripts;
- possible operating system detection;
- traceroute where applicable.

This scan can provide richer information, but it is also more intrusive and more visible.

In real environments, aggressive scans should only be performed with explicit authorization.

---

## Saving scan results

Nmap results were saved using the `-oN` option.

Commands used:

```bash
mkdir -p exercises/nmap-lab/results

nmap -sV 172.32.0.10 -oN exercises/nmap-lab/results/web-scan.txt
nmap -sV 172.32.0.20 -oN exercises/nmap-lab/results/ssh-scan.txt
nmap -sV 172.32.0.30 -oN exercises/nmap-lab/results/db-scan.txt
nmap -sV 172.32.0.0/24 -oN exercises/nmap-lab/results/network-scan.txt
```

Saving results is important because it creates evidence that can be reviewed, compared or included in documentation later.

---

## Results summary

| IP address | Open port | Service | Notes |
|---|---:|---|---|
| `172.32.0.10` | `80/tcp` | HTTP | Nginx web server |
| `172.32.0.20` | `2222/tcp` | SSH | OpenSSH server container |
| `172.32.0.30` | `3306/tcp` | MySQL / MariaDB | Database service |
| `172.32.0.1` | N/A | Docker gateway | Network gateway discovered during host discovery |

The most important finding is that each container exposed the expected service:

```text
nmap-web -> HTTP
nmap-ssh -> SSH
nmap-db  -> MySQL/MariaDB
```

---

## Mini challenge answers

### 1. What hosts were active?

The active hosts were:

```text
172.32.0.1
172.32.0.10
172.32.0.20
172.32.0.30
```

`172.32.0.1` was the Docker gateway.

The three main lab hosts were:

```text
172.32.0.10
172.32.0.20
172.32.0.30
```

---

### 2. What service did `172.32.0.10` offer?

`172.32.0.10` offered an HTTP service.

Relevant port:

```text
80/tcp
```

---

### 3. What service did `172.32.0.20` offer?

`172.32.0.20` offered an SSH service.

Relevant port:

```text
2222/tcp
```

---

### 4. What service did `172.32.0.30` offer?

`172.32.0.30` offered a MySQL/MariaDB database service.

Relevant port:

```text
3306/tcp
```

---

### 5. What port did each service use?

| Host | Service | Port |
|---|---|---:|
| `172.32.0.10` | HTTP | `80/tcp` |
| `172.32.0.20` | SSH | `2222/tcp` |
| `172.32.0.30` | MySQL/MariaDB | `3306/tcp` |

---

### 6. What was the difference between normal Nmap and `nmap -sV`?

A normal Nmap scan identifies open ports and guesses the service based mainly on port numbers.

Example:

```text
80/tcp open http
```

`nmap -sV` performs service and version detection. It sends additional probes to identify more accurately what service is running.

Example:

```text
80/tcp open http nginx
```

Therefore:

```text
Normal scan -> faster and simpler
-sV scan    -> more detailed but noisier
```

---

### 7. What does `-sn` do?

The `-sn` option performs host discovery without a full port scan.

It is useful for identifying which hosts are alive in a network.

Example:

```bash
nmap -sn 172.32.0.0/24
```

---

### 8. What does `-p` do?

The `-p` option specifies which ports Nmap should scan.

Example:

```bash
nmap -p 80,2222,3306 172.32.0.10
```

This tells Nmap to test only ports `80`, `2222` and `3306`.

---

### 9. What does `-A` do?

The `-A` option enables aggressive scanning.

It can include:

- version detection;
- default scripts;
- OS detection;
- traceroute.

It can provide more information, but it is more intrusive and should only be used with authorization.

---

### 10. Why is Nmap useful in cybersecurity?

Nmap is useful because it helps identify:

- active hosts;
- open ports;
- exposed services;
- service versions;
- possible attack surface;
- unexpected network exposure;
- systems that may require further assessment.

It is useful in both offensive and defensive work.

For offensive security, it helps with enumeration.

For defensive security, it helps validate what is exposed and whether firewall or segmentation rules are working correctly.

---

## Security relevance

Nmap is a fundamental tool in cybersecurity because enumeration is one of the first stages of many technical assessments.

### Asset discovery

Nmap can help identify which hosts are active in a network.

This is useful when an analyst needs to understand what systems exist in a given range.

### Exposed service identification

Open ports reveal services that may be accessible.

Examples:

```text
80/tcp   -> HTTP
22/tcp   -> SSH
3306/tcp -> MySQL
```

Each exposed service increases the attack surface.

### Attack surface mapping

By combining hosts and open ports, an analyst can build a map of the network exposure.

Example:

```text
172.32.0.10 -> web service
172.32.0.20 -> remote administration
172.32.0.30 -> database service
```

This helps prioritize what should be reviewed first.

### Vulnerability assessment preparation

Nmap does not automatically prove that a system is vulnerable.

However, service and version detection can help identify software that may need vulnerability research.

For example, if a service version is outdated, the next step may be to check whether known vulnerabilities exist for that version.

### Incident response

During incident response, Nmap can help verify:

- whether unauthorized services are running;
- whether a host exposes unexpected ports;
- whether lateral movement paths exist;
- whether network segmentation is effective.

### Firewall validation

Nmap can be used to check whether firewall rules behave as expected.

For example, if a database should not be reachable from a specific network, scanning can help validate that the port is filtered or closed.

---

## Ethical and legal considerations

Nmap should only be used against systems where scanning is authorized.

Port scanning can be considered suspicious or hostile when performed against third-party networks without permission.

In this lab, all scans were performed against local Docker containers created specifically for learning purposes.

Authorized environment:

```text
Local Docker lab
172.32.0.0/24
```

Unauthorized environment:

```text
Public IP ranges or third-party systems without permission
```

---

## Connection with previous labs

This Nmap lab connects directly with previous networking work.

### Network fundamentals

The host discovery scan required understanding:

- IP addresses;
- subnets;
- gateways;
- routing.

The target network was:

```text
172.32.0.0/24
```

### tcpdump

The tcpdump lab showed how network traffic looks at packet level.

Nmap scans also generate network traffic that could be captured and analyzed with:

```bash
tcpdump
```

For example, a TCP scan may generate connection attempts or SYN packets depending on scan type and privileges.

### Wireshark

Wireshark can be used to visually inspect the packets generated by Nmap.

This helps connect scan results with actual network behavior.

### Protocols

The services discovered by Nmap correspond to protocols studied previously:

```text
HTTP -> TCP/80
SSH  -> TCP/22 or TCP/2222 depending on configuration
MySQL/MariaDB -> TCP/3306
```

This reinforces the relationship between:

```text
IP address
Port
Protocol
Service
```

---

## Lessons learned

1. Nmap can discover active hosts in a network using `-sn`.

2. An IP address identifies the target host, while a port identifies the exposed service.

3. A basic scan is useful for quickly identifying open ports.

4. The `-sV` option provides more detailed service information but generates more probing traffic.

5. The `-p` option allows focused scanning of specific ports.

6. The `--top-ports` option is useful for quickly checking common ports.

7. The `-A` option can provide richer information but is more intrusive.

8. Scan results should be saved when they are part of a technical investigation or lab report.

9. Nmap is useful for both offensive enumeration and defensive validation.

10. Scanning should only be performed in authorized environments.

11. Docker is useful for creating safe, isolated targets for security labs.

12. Nmap results are easier to understand when combined with knowledge of TCP, UDP, ports, services and routing.

13. Enumeration is not exploitation; it is the process of understanding what exists and what is exposed.

14. A service being open does not automatically mean it is vulnerable, but it does mean it should be reviewed.

15. Nmap, tcpdump and Wireshark are complementary tools: Nmap identifies exposure, while tcpdump and Wireshark help analyze the traffic behind that activity.