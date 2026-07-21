# TryHackMe Core and Secure Protocols Notes

## Rooms completed

- Networking Core Protocols
- Networking Secure Protocols

## Objective

The objective of these notes is to summarize common application-layer protocols and understand how secure versions of those protocols protect network communication.

The focus is to understand:

- what each protocol is used for;
- which ports are commonly associated with it;
- what security risks exist when protocols are used without encryption;
- how secure alternatives such as TLS, HTTPS, SSH, SFTP and VPNs reduce those risks;
- how these concepts connect with my Linux, Docker, tcpdump and incident triage labs.

---

# Networking Core Protocols

## WHOIS

WHOIS is a protocol and information service used to query registration information about domain names and IP address allocations.

WHOIS can reveal information such as:

- domain registrar;
- registration date;
- expiration date;
- name servers;
- registrant organization, when public;
- administrative or technical contact information, when available.

From a cybersecurity perspective, WHOIS is useful during reconnaissance because it can help identify who owns or manages a domain.

However, WHOIS data is often privacy-protected, so the amount of useful information may vary.

Example use cases:

- investigating suspicious domains;
- identifying domain registration patterns;
- checking domain age;
- finding related infrastructure;
- supporting phishing or malware investigations.

---

## DNS

DNS stands for Domain Name System.

DNS translates human-readable names into IP addresses.

Example:

```text
github.com
    ↓ DNS
140.82.121.4
```

Without DNS, users would need to remember IP addresses instead of names.

DNS is essential because most network communication starts with a name, but routing requires an IP address.

---

## DNS record types

| Record | Purpose |
|---|---|
| `A` | Maps a domain name to an IPv4 address |
| `AAAA` | Maps a domain name to an IPv6 address |
| `CNAME` | Creates an alias from one name to another name |
| `MX` | Specifies mail servers for a domain |
| `NS` | Specifies authoritative name servers for a domain |
| `TXT` | Stores text data, often used for SPF, DKIM, verification or security policies |

Example:

```text
A record:
example.com -> 93.184.216.34

AAAA record:
example.com -> 2606:2800:220:1:248:1893:25c8:1946

MX record:
example.com -> mail server for the domain
```

---

## DNS security relevance

DNS is important in cybersecurity investigations because many attacks involve domain names.

DNS can help identify:

- suspicious domains;
- command-and-control infrastructure;
- phishing websites;
- malware callback domains;
- DNS tunnelling;
- unauthorized DNS servers;
- unusual hostname lookups.

During an investigation, DNS evidence can answer questions such as:

```text
Which domains did the host query?
Which IP addresses did those domains resolve to?
Were the domains newly registered?
Were the domains related to known malicious infrastructure?
Did the host use an unexpected DNS server?
```

In my own labs, DNS was visible through:

```bash
resolvectl status
getent hosts github.com
nslookup pcap-server
cat /etc/resolv.conf
```

In Docker, internal DNS resolved container names such as:

```text
pcap-server -> 172.31.0.2
```

---

## HTTP

HTTP stands for Hypertext Transfer Protocol.

It is used for web communication between clients and servers.

A basic HTTP interaction contains:

```text
Client request
    ↓
Server response
```

Example request:

```text
GET / HTTP/1.1
Host: example.com
```

Example response:

```text
HTTP/1.1 200 OK
Content-Type: text/html
```

Important HTTP elements include:

- methods;
- paths;
- headers;
- status codes;
- request body;
- response body.

Common HTTP methods:

| Method | Purpose |
|---|---|
| `GET` | Request a resource |
| `POST` | Send data to the server |
| `PUT` | Replace or upload a resource |
| `PATCH` | Partially modify a resource |
| `DELETE` | Delete a resource |

Common status codes:

| Code | Meaning |
|---|---|
| `200` | OK |
| `301` / `302` | Redirect |
| `400` | Bad Request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not Found |
| `500` | Internal Server Error |

In my tcpdump lab, HTTP traffic was visible in clear text. I was able to observe:

```text
GET / HTTP/1.1
Host: pcap-server
HTTP/1.1 200 OK
Server: nginx
```

This happened because plain HTTP does not encrypt the application payload.

---

## FTP

FTP stands for File Transfer Protocol.

It is used to transfer files between a client and a server.

Traditional FTP commonly uses:

```text
TCP/21
```

for control communication.

FTP can be risky because traditional FTP does not encrypt credentials or file contents by default.

That means an observer on the network could potentially see:

- usernames;
- passwords;
- transferred files;
- commands sent to the server.

From a security point of view, plain FTP should generally be avoided on untrusted networks.

More secure alternatives include:

```text
SFTP
FTPS
```

---

## SMTP

SMTP stands for Simple Mail Transfer Protocol.

It is mainly used for sending email.

SMTP is used between:

- email clients and mail servers;
- mail servers and other mail servers.

Common ports include:

```text
TCP/25   SMTP server-to-server delivery
TCP/587  Mail submission, usually with STARTTLS
TCP/465  SMTPS
```

SMTP is important in cybersecurity because email is a common attack vector.

Security investigations may involve:

- phishing emails;
- spoofed senders;
- malicious attachments;
- suspicious mail servers;
- SPF, DKIM and DMARC records;
- unusual outbound email activity.

---

## POP3

POP3 stands for Post Office Protocol version 3.

It is used by email clients to retrieve email from a mail server.

Traditional POP3 commonly uses:

```text
TCP/110
```

Secure POP3, called POP3S, commonly uses:

```text
TCP/995
```

POP3 is often associated with downloading emails from the server to a client.

Compared with IMAP, POP3 is simpler and less focused on synchronizing mailbox state across multiple devices.

---

## IMAP

IMAP stands for Internet Message Access Protocol.

It is used by email clients to access and manage mail stored on a mail server.

Traditional IMAP commonly uses:

```text
TCP/143
```

Secure IMAP, called IMAPS, commonly uses:

```text
TCP/993
```

IMAP is useful when a user wants to access the same mailbox from multiple devices because email state is synchronized with the server.

Examples of synchronized state include:

- read/unread status;
- folders;
- message organization;
- server-side mailbox contents.

---

## Plaintext protocol risks

Protocols that do not provide encryption by default create several risks.

Main risks:

- credentials can be exposed;
- session data can be captured;
- sensitive content can be read;
- traffic can be modified by an attacker in some scenarios;
- the identity of the server may not be strongly verified.

Examples of risky plaintext protocols include:

```text
HTTP
FTP
Telnet
POP3
IMAP
SMTP without TLS
```

In a packet capture, plaintext protocols may reveal information directly.

Example:

```text
GET /login HTTP/1.1
username=admin&password=example
```

This is why encryption is important for protecting confidentiality and integrity.

---

# Networking Secure Protocols

## TLS

TLS stands for Transport Layer Security.

TLS provides three main security properties:

```text
Confidentiality
Integrity
Authenticity
```

### Confidentiality

Confidentiality means that the application data is encrypted.

An observer may still see metadata such as:

- source IP;
- destination IP;
- port;
- protocol;
- timing;
- packet sizes.

But the actual application content is protected.

### Integrity

Integrity means that tampering with the encrypted communication can be detected.

This prevents an attacker from silently modifying the protected data in transit.

### Authenticity

Authenticity means that the client can verify the identity of the server using certificates.

For example, when visiting an HTTPS website, the browser checks whether the certificate is valid for the domain.

---

## Why TLS is added to protocols

Many older protocols were designed before modern security requirements became standard.

TLS can be added to protect them.

Examples:

```text
HTTP  + TLS = HTTPS
SMTP  + TLS = SMTPS or SMTP with STARTTLS
POP3  + TLS = POP3S
IMAP  + TLS = IMAPS
FTP   + TLS = FTPS
```

TLS does not remove the original protocol. Instead, it protects the communication channel used by that protocol.

---

## HTTPS

HTTPS is HTTP protected with TLS.

Conceptually:

```text
HTTP + TLS = HTTPS
```

Plain HTTP commonly uses:

```text
TCP/80
```

HTTPS commonly uses:

```text
TCP/443
```

HTTPS protects web communication by encrypting the HTTP request and response.

With plain HTTP, a packet capture may show:

```text
GET / HTTP/1.1
Host: example.com
Cookie: session=...
```

With HTTPS, the packet capture will still show information such as:

```text
source IP
destination IP
TCP/443
TLS handshake metadata
packet sizes
timing
```

But the HTTP content itself will not be visible in clear text.

This is why HTTPS is essential for:

- login pages;
- banking;
- personal data;
- APIs;
- session cookies;
- administrative panels.

---

## Secure email protocols

Email protocols can be protected with TLS.

| Plain protocol | Secure version |
|---|---|
| SMTP | SMTPS / SMTP with STARTTLS |
| POP3 | POP3S |
| IMAP | IMAPS |

### SMTP with TLS

SMTP can use STARTTLS to upgrade an initially plaintext connection to a TLS-protected connection.

Mail submission commonly uses:

```text
TCP/587
```

SMTPS commonly uses:

```text
TCP/465
```

### POP3S

POP3S protects POP3 with TLS.

Common port:

```text
TCP/995
```

### IMAPS

IMAPS protects IMAP with TLS.

Common port:

```text
TCP/993
```

The main security improvement is that credentials and email contents are protected from passive network observers.

---

## SSH

SSH stands for Secure Shell.

SSH is used for secure remote administration.

Common port:

```text
TCP/22
```

SSH provides:

- encrypted remote shell access;
- authentication;
- integrity protection;
- secure command execution;
- secure tunnelling capabilities;
- secure file transfer through related tools.

SSH replaced insecure remote access protocols such as Telnet.

Telnet sends data, including credentials, in clear text. SSH encrypts the session.

From a security perspective, SSH is critical because it often provides direct administrative access to systems.

Important SSH security practices include:

- disabling root login when possible;
- using key-based authentication;
- disabling password authentication when appropriate;
- using strong passphrases for private keys;
- restricting access by firewall or VPN;
- monitoring failed login attempts;
- reviewing `/var/log/auth.log`;
- using tools such as fail2ban where appropriate.

In the Linux incident triage lab, SSH authentication logs were important evidence.

---

## SFTP and FTPS

SFTP and FTPS are both secure file transfer options, but they are not the same.

### SFTP

SFTP stands for SSH File Transfer Protocol.

It runs over SSH.

Common port:

```text
TCP/22
```

SFTP uses SSH for authentication and encryption.

### FTPS

FTPS is FTP protected with TLS.

It is still based on FTP, but the communication is protected using TLS.

Common ports can vary depending on configuration, but FTPS is conceptually:

```text
FTP + TLS
```

### Key difference

```text
SFTP uses SSH.
FTPS uses FTP protected with TLS.
```

They are different protocols, even though both are used for secure file transfer.

---

## VPN

VPN stands for Virtual Private Network.

A VPN creates a protected tunnel between systems or networks over an untrusted network.

A VPN can be used to:

- connect remote users to an internal corporate network;
- connect two private networks over the internet;
- encrypt traffic over untrusted networks;
- provide access to internal services;
- enforce authentication before network access.

Conceptually:

```text
Remote user
    ↓ encrypted tunnel
VPN server
    ↓
Internal network
```

VPNs are important in security because they can reduce exposure of internal services.

Instead of exposing administrative services directly to the internet, an organization may require VPN access first.

However, VPN accounts and VPN gateways must also be protected because they can become high-value targets.

---

# Comparison table

| Insecure / Plain protocol | Secure alternative | Main security benefit |
|---|---|---|
| HTTP | HTTPS | Encrypts web traffic and verifies server identity |
| Telnet | SSH | Provides encrypted remote administration |
| FTP | SFTP / FTPS | Protects credentials and file transfers |
| SMTP | SMTPS / STARTTLS | Protects email submission or transport where supported |
| POP3 | POP3S | Protects email retrieval |
| IMAP | IMAPS | Protects synchronized mailbox access |

---

# Connection with my own labs

## tcpdump lab

The tcpdump lab showed that plain HTTP traffic can be inspected directly.

In the capture, it was possible to observe:

```text
GET / HTTP/1.1
Host: pcap-server
HTTP/1.1 200 OK
Server: nginx
```

This demonstrated that HTTP does not encrypt application data.

If the same communication had used HTTPS, the capture would still show:

```text
source IP
destination IP
TCP port 443
TLS handshake information
packet sizes
timing
```

But it would not show the HTTP request and response body in clear text.

This connects directly with the purpose of TLS.

---

## Linux incident triage lab

In the Linux incident triage lab, understanding protocols and ports helped interpret suspicious activity.

For example, the suspicious process connected to:

```text
203.0.113.55:4444
```

The port alone does not prove malicious activity, but an unusual process connecting to an external IP and uncommon port is suspicious.

Protocol knowledge helps answer questions such as:

```text
Is this port expected?
Is this protocol normally used by this system?
Is the connection inbound or outbound?
Is the destination known or suspicious?
Is the traffic encrypted?
Could credentials or payloads be exposed?
```

---

## Docker labs

The Docker networking labs helped separate several concepts that are often confused.

Important distinctions:

```text
IP address      -> identifies a host or interface
Port            -> identifies a service on that host
Protocol        -> defines communication rules
Service         -> application listening on a port
DNS name        -> human-readable name resolved to an IP
Container name  -> name Docker can resolve internally
```

Example from the Docker lab:

```text
pcap-server
    ↓ Docker DNS
172.31.0.2
    ↓ TCP connection
172.31.0.2:80
    ↓ Application protocol
HTTP
```

This connected DNS, IP, TCP, ports and HTTP in one controlled environment.

---

# Security relevance

## DNS investigation

DNS is often one of the first places to look during a security investigation.

Malware, phishing kits and command-and-control frameworks often rely on domain names.

Useful DNS-related questions include:

```text
What domains did the host query?
What IPs did those domains resolve to?
Are the domains newly registered?
Are there unusual TXT records?
Are DNS queries frequent or patterned?
Is the host using an expected DNS server?
```

---

## Domain reconnaissance with WHOIS

WHOIS can support domain reconnaissance.

It may help identify:

- domain age;
- registrar;
- name servers;
- related infrastructure;
- registration patterns.

This can be useful when investigating phishing domains or suspicious external infrastructure.

---

## Exposed web services

HTTP and HTTPS services are common targets.

Security analysts need to understand:

- which ports are exposed;
- whether the service uses HTTP or HTTPS;
- what status codes appear in logs;
- whether sensitive paths are exposed;
- whether authentication is required;
- whether clear-text traffic exists.

In earlier labs, suspicious web paths included examples such as:

```text
/admin
/.env
/.git/config
/login
```

These are typical paths to investigate during reconnaissance or web attack analysis.

---

## Clear-text credential risks

Plaintext protocols can expose credentials.

Examples:

```text
FTP username/password
HTTP login forms
Telnet sessions
POP3 credentials
IMAP credentials
SMTP authentication
```

Packet captures are especially useful for demonstrating this risk.

Secure alternatives should be used whenever credentials or sensitive data are transmitted.

---

## Secure remote administration

SSH is one of the most important protocols for Linux administration.

Because SSH can provide shell access, it must be monitored and hardened.

Important evidence sources include:

```text
/var/log/auth.log
journalctl
firewall logs
VPN logs
EDR telemetry
```

Suspicious SSH indicators include:

- repeated failed login attempts;
- login from unusual IP addresses;
- successful login after many failures;
- unexpected users;
- unusual login times;
- commands executed after login.

---

## Email security

Email protocols are important because email is a major attack vector.

Security investigations may involve:

- phishing messages;
- malicious attachments;
- spoofed sender addresses;
- suspicious SMTP activity;
- compromised mailboxes;
- unusual forwarding rules;
- abnormal IMAP logins;
- weak or missing SPF, DKIM and DMARC records.

Understanding SMTP, POP3 and IMAP helps interpret email-related logs and alerts.

---

## VPN access

VPNs protect access to internal networks, but they are also high-value entry points.

Security monitoring should include:

- failed VPN authentication attempts;
- successful logins from unusual locations;
- impossible travel events;
- use of old or weak VPN protocols;
- access outside normal working hours;
- excessive access to internal systems after VPN login.

A compromised VPN account can provide an attacker with internal network access.

---

## Packet capture analysis

Packet captures help identify what actually happened on the network.

They can reveal:

- source and destination IP addresses;
- ports;
- protocols;
- DNS queries;
- TCP handshakes;
- HTTP requests;
- clear-text data;
- suspicious beaconing;
- unexpected external communication.

However, encrypted traffic limits visibility into application content.

Even then, metadata remains useful.

For example, in HTTPS traffic, an analyst may still observe:

```text
destination IP
TCP/443
TLS handshake metadata
packet timing
packet sizes
connection frequency
```

---

# Questions or weak points

The following areas still need more practice:

1. DNS record types beyond the most common ones, especially TXT records used for email security.

2. The TLS handshake in detail, including certificate validation and key exchange.

3. The difference between implicit TLS and STARTTLS.

4. The practical difference between SFTP and FTPS in real deployments.

5. How VPNs differ depending on mode, such as remote-access VPN versus site-to-site VPN.

6. How encrypted traffic can still be analyzed using metadata.

7. How to identify suspicious protocol usage in Wireshark.

---

# Lessons learned

1. Application-layer protocols define how services communicate over the network.

2. DNS is fundamental because names must usually be resolved before communication can happen.

3. WHOIS can support reconnaissance and domain investigation, although privacy protection may limit available data.

4. HTTP is easy to inspect in packet captures because it does not encrypt content.

5. HTTPS protects HTTP by adding TLS.

6. TLS provides confidentiality, integrity and authenticity.

7. Plaintext protocols can expose credentials and sensitive data.

8. SSH is essential for secure remote administration and should be carefully monitored.

9. SFTP and FTPS are not the same: SFTP uses SSH, while FTPS uses FTP protected with TLS.

10. Email protocols have different roles: SMTP sends mail, while POP3 and IMAP retrieve or access mail.

11. Secure email variants protect credentials and email contents with TLS.

12. VPNs create protected tunnels and are useful for remote access, but VPN accounts must be strongly protected.

13. Ports help identify services, but the context of the process and destination is necessary to assess risk.

14. Packet captures can reveal clear-text protocols directly, but encrypted protocols require metadata-based analysis.

15. Understanding protocols helps interpret logs, Nmap results, tcpdump captures, Wireshark traffic and incident response evidence.