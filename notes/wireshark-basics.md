# Wireshark Basics Notes

## Room completed

- TryHackMe — Wireshark: The Basics

## Objective

The objective of this lab was to learn how to analyze packet captures visually using Wireshark and connect that analysis with previous `tcpdump` work.

The focus was to understand:

- how Wireshark organizes packets;
- how to use display filters;
- how to identify a TCP three-way handshake;
- how to inspect HTTP traffic;
- how to follow a TCP stream;
- how Wireshark compares with `tcpdump`;
- why packet analysis is useful in cybersecurity.

---

## PCAP analyzed

The capture analyzed was:

```text
exercises/packet-capture-lab/captures/http-session.pcap
```

This capture was generated in the previous `tcpdump` lab using a Docker network with:

```text
Client: 172.31.0.3
Server: 172.31.0.2
Service: Nginx
Protocol: HTTP
Port: TCP/80
```

The traffic represented a simple HTTP session between a Docker client container and a Docker server container.

---

## Wireshark installation note

During installation, Wireshark asked whether non-superusers should be able to capture packets.

The selected option was:

```text
Yes
```

This allows users in the `wireshark` group to capture packets without running Wireshark directly as `root`.

This is recommended because running the entire Wireshark application as root increases security risk.

The user can be added to the `wireshark` group with:

```bash
sudo usermod -aG wireshark $USER
```

After that, logging out and back in, or rebooting, is required for the group change to take effect.

For this lab, live capture permissions were not essential because the main task was to analyze an existing `.pcap` file.

---

## Wireshark interface

Wireshark is divided into three main analysis areas.

### Packet list

The packet list shows all captured packets.

Important columns include:

```text
No.
Time
Source
Destination
Protocol
Length
Info
```

This panel is useful for quickly identifying conversations, protocols and suspicious traffic patterns.

### Packet details

The packet details panel shows the selected packet broken down by protocol layers.

For an HTTP packet, the layers may include:

```text
Frame
Ethernet
Internet Protocol
Transmission Control Protocol
Hypertext Transfer Protocol
```

This is useful because Wireshark structures the packet by layers, making it easier to understand encapsulation.

### Packet bytes

The packet bytes panel shows the raw packet content in hexadecimal and ASCII.

This is useful when inspecting low-level packet data or validating what Wireshark has decoded.

### Display filter bar

The display filter bar allows the analyst to show only packets matching specific conditions.

Unlike capture filters, display filters do not change the original capture. They only change what is currently visible.

---

## Display filters used

The following display filters were useful during the analysis.

### Show traffic involving the server

```text
ip.addr == 172.31.0.2
```

This shows packets where `172.31.0.2` appears either as source or destination.

### Show packets from the client

```text
ip.src == 172.31.0.3
```

This shows packets whose source IP is the client.

### Show packets going to the server

```text
ip.dst == 172.31.0.2
```

This shows packets whose destination IP is the server.

### Show HTTP server traffic

```text
tcp.port == 80
```

This shows TCP packets where either the source or destination port is `80`.

### Show HTTP packets

```text
http
```

This shows packets that Wireshark identifies as HTTP.

### Show SYN packets

```text
tcp.flags.syn == 1
```

This shows packets where the SYN flag is set.

### Show reset packets

```text
tcp.flags.reset == 1
```

This shows packets where the RST flag is set.

---

## TCP handshake analysis

The HTTP connection began with a TCP three-way handshake.

| Step | Source | Destination | Flags | Meaning |
|---|---|---|---|---|
| 1 | `172.31.0.3` | `172.31.0.2` | SYN | The client requests a TCP connection |
| 2 | `172.31.0.2` | `172.31.0.3` | SYN, ACK | The server accepts and acknowledges the request |
| 3 | `172.31.0.3` | `172.31.0.2` | ACK | The client acknowledges the server response |

Conceptually:

```text
Client                          Server
172.31.0.3                      172.31.0.2:80

   SYN ------------------------>
       <---------------- SYN, ACK
   ACK ------------------------>

TCP connection established
```

The handshake shows that TCP is connection-oriented. Before HTTP data can be exchanged, the client and server establish a TCP connection.

---

## TCP fields inspected

Inside the TCP section, Wireshark allows inspection of fields such as:

```text
Source Port
Destination Port
Sequence Number
Acknowledgment Number
Flags
Window Size
Checksum
```

The server port was:

```text
TCP/80
```

The client used a temporary ephemeral port.

This is normal: the server listens on a known port, while the client uses a temporary source port for the connection.

---

## HTTP analysis

After the TCP connection was established, the client sent an HTTP request.

The request was:

```text
GET / HTTP/1.1
```

This means the client requested the root path:

```text
/
```

from the web server.

The server replied with:

```text
HTTP/1.1 200 OK
```

The status code:

```text
200
```

means the request was successfully processed.

The server was:

```text
nginx
```

The communication used:

```text
HTTP over TCP/80
```

---

## Why HTTP was visible

The HTTP request and response were visible because HTTP does not encrypt the application-layer payload.

In Wireshark, it was possible to inspect information such as:

```text
GET / HTTP/1.1
Host: pcap-server
User-Agent
HTTP/1.1 200 OK
Server: nginx
Content-Type
```

This is important from a security perspective.

With plain HTTP, an observer with access to the traffic may be able to read sensitive data if it is transmitted in the request or response.

By contrast, HTTPS protects HTTP with TLS.

With HTTPS, Wireshark would still show metadata such as:

```text
Source IP
Destination IP
TCP port 443
TLS handshake information
Packet sizes
Timing
```

but it would not show the HTTP content in clear text.

---

## Follow TCP Stream

Wireshark provides the option:

```text
Follow → TCP Stream
```

This reconstructs the application conversation between the client and server.

For this capture, Follow TCP Stream allowed the HTTP exchange to be viewed as a single conversation.

It showed the request and response together, including:

```text
GET / HTTP/1.1
HTTP/1.1 200 OK
Welcome to nginx!
```

This feature is useful because it allows an analyst to understand the full application-level conversation without manually inspecting each packet one by one.

It is especially helpful for:

- HTTP analysis;
- clear-text protocol inspection;
- suspicious session reconstruction;
- malware traffic review;
- identifying leaked credentials in unencrypted protocols.

---

## Wireshark and protocol layers

A packet carrying HTTP traffic can be understood through layers:

```text
Frame
Ethernet
IP
TCP
HTTP
```

These map conceptually to networking models:

| Wireshark layer | Conceptual role |
|---|---|
| Frame / Ethernet | Local network access |
| IP | Network addressing and routing |
| TCP | Transport connection and ports |
| HTTP | Application data |

This connects directly with the OSI and TCP/IP models studied in TryHackMe.

Wireshark is useful because it makes encapsulation visible. The analyst can expand each layer and inspect the fields added by that layer.

---

## Wireshark vs tcpdump

| Tool | Main advantage | Typical use |
|---|---|---|
| `tcpdump` | Fast and lightweight | Capturing traffic from terminal or servers |
| Wireshark | Visual and detailed | Deep packet analysis |
| `tshark` | Wireshark engine in terminal | Scriptable packet analysis |

### tcpdump

`tcpdump` is useful when working directly on servers or over SSH.

Example:

```bash
sudo tcpdump -i any -n 'tcp port 80'
```

It is fast and practical, but less visual.

### Wireshark

Wireshark is better for detailed analysis.

It provides:

- protocol decoding;
- display filters;
- packet details;
- stream reconstruction;
- statistics;
- graphical interface.

### tshark

`tshark` is the command-line version of Wireshark.

Example:

```bash
tshark -r exercises/packet-capture-lab/captures/http-session.pcap
```

Filtering HTTP traffic:

```bash
tshark -r exercises/packet-capture-lab/captures/http-session.pcap -Y "http"
```

Extracting specific fields:

```bash
tshark \
  -r exercises/packet-capture-lab/captures/http-session.pcap \
  -Y "http" \
  -T fields \
  -e ip.src \
  -e ip.dst \
  -e http.request.method \
  -e http.response.code
```

---

## Capture filters vs display filters

A capture filter controls what traffic is captured.

A display filter controls what traffic is shown after the capture already exists.

### Capture filter

Example:

```text
tcp port 80
```

This limits the packets saved during capture.

### Display filter

Example:

```text
tcp.port == 80
```

This filters packets already loaded in Wireshark.

Main difference:

```text
Capture filter  -> affects what is recorded
Display filter  -> affects what is shown
```

Display filters are safer during analysis because they do not remove packets from the original capture.

---

## Connection with previous tcpdump lab

The previous `tcpdump` lab showed the same traffic from the terminal.

In `tcpdump`, the HTTP data could be observed using:

```bash
tcpdump -A
```

In Wireshark, the same communication could be inspected more clearly by expanding:

```text
Transmission Control Protocol
Hypertext Transfer Protocol
```

The main difference is:

```text
tcpdump shows packet data in terminal format.
Wireshark organizes the same information visually by protocol fields.
```

Both tools are useful and complementary.

---

## Security relevance

Wireshark is useful in cybersecurity because it can help identify what is happening on the network.

### Suspicious connections

Wireshark can reveal unexpected communication between hosts.

Useful fields include:

```text
Source IP
Destination IP
Protocol
Source port
Destination port
```

### Clear-text credentials

If a protocol does not use encryption, Wireshark may reveal credentials or sensitive content.

Examples of risky protocols include:

```text
HTTP
FTP
Telnet
POP3
IMAP
SMTP without TLS
```

### Unusual protocols

Wireshark helps detect traffic that does not match expected system behaviour.

For example, a workstation unexpectedly sending traffic to an unknown external IP on an unusual port may require investigation.

### Scanning

Port scanning or host discovery may appear as repeated connection attempts, SYN packets or ICMP probes.

Wireshark can help identify:

- scan source;
- target;
- ports contacted;
- timing;
- protocol used.

### Malware communication

Malware may communicate with command-and-control infrastructure.

Wireshark can help detect:

- repeated outbound connections;
- beaconing;
- suspicious DNS queries;
- unusual HTTP requests;
- non-standard ports;
- clear-text indicators.

### DNS anomalies

DNS traffic can reveal suspicious domains, unexpected DNS servers or unusual query patterns.

### HTTP activity

For unencrypted HTTP, Wireshark can reconstruct requests and responses, making it easier to identify paths, user agents, hosts and status codes.

---

## Questions or weak points

The following areas still need more practice:

1. Using more advanced Wireshark display filters.

2. Interpreting TCP sequence and acknowledgment numbers confidently.

3. Understanding TCP retransmissions, resets and connection termination in detail.

4. Using Wireshark statistics effectively.

5. Analyzing encrypted traffic where application data is not visible.

6. Recognizing scanning or malware-like patterns in larger captures.

---

## Lessons learned

1. Wireshark provides a visual way to inspect packet captures.

2. Display filters are essential for reducing noise during analysis.

3. A TCP connection normally begins with SYN, SYN-ACK and ACK.

4. HTTP traffic is visible in clear text when TLS is not used.

5. Follow TCP Stream is useful for reconstructing application conversations.

6. Wireshark and tcpdump analyze the same type of data but are useful in different situations.

7. `tcpdump` is better for fast terminal-based capture, while Wireshark is better for detailed visual analysis.

8. `tshark` allows Wireshark-style analysis from the command line.

9. Packet analysis connects directly with the OSI and TCP/IP models.

10. Understanding IP addresses, ports, protocols and flags is necessary to interpret captures correctly.

11. PCAP files are useful evidence because they preserve network activity for later analysis.

12. In security investigations, packet captures can help identify suspicious connections, clear-text data exposure, scanning and malware communication.