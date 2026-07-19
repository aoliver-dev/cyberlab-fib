# TryHackMe Networking Notes

## Rooms completed

- Networking Concepts
- Networking Essentials

## Objective

The objective of these notes is to summarize the main networking concepts reviewed in TryHackMe and connect them with the practical Linux and Docker laboratories completed in this repository.

The focus is not only to understand definitions, but also to relate each concept to real commands and observations such as:

```bash
ip addr
ip route
ip neigh
resolvectl status
ss -tuln
tcpdump
docker network inspect
```

---

# Networking Concepts

## OSI model

The OSI model is a conceptual model that divides network communication into seven layers.

The layers are:

```text
7. Application
6. Presentation
5. Session
4. Transport
3. Network
2. Data Link
1. Physical
```

Each layer has a different responsibility.

### Layer 1 — Physical

The physical layer deals with the transmission of raw bits through a physical or wireless medium.

Examples include:

- Ethernet cables;
- Wi-Fi radio signals;
- electrical signals;
- fiber optics.

This layer is concerned with how data is physically transmitted.

### Layer 2 — Data Link

The data link layer handles local network communication between devices on the same network segment.

Important concepts include:

- MAC addresses;
- Ethernet frames;
- switches;
- ARP in IPv4 networks.

This layer is important because two hosts in the same local network need link-layer addressing to communicate directly.

### Layer 3 — Network

The network layer is responsible for logical addressing and routing between networks.

The main protocol studied at this layer was:

```text
IP
```

Important concepts include:

- IP addresses;
- subnets;
- routing;
- default gateways.

In my Linux lab, this layer was visible through commands such as:

```bash
ip addr
ip route
ip route get 8.8.8.8
```

### Layer 4 — Transport

The transport layer provides communication between processes running on different hosts.

The main protocols are:

```text
TCP
UDP
```

TCP provides reliable, connection-oriented communication.

UDP provides faster, connectionless communication without the same reliability guarantees.

Ports also belong to this layer because they identify which service or process should receive the traffic.

### Layer 5 — Session

The session layer is responsible for establishing, managing and terminating sessions between applications.

In practice, modern networking often discusses this functionality together with application protocols rather than treating it as a separate operational layer.

### Layer 6 — Presentation

The presentation layer deals with data representation, formatting, compression and encryption.

Examples include:

- character encoding;
- compression;
- TLS encryption.

### Layer 7 — Application

The application layer is where user-facing network protocols operate.

Examples include:

```text
HTTP
HTTPS
DNS
SSH
FTP
SMTP
```

In my `tcpdump` lab, HTTP was visible at this layer when I captured:

```text
GET / HTTP/1.1
HTTP/1.1 200 OK
```

---

## Why the OSI model is useful

The OSI model is useful because it helps organize troubleshooting and security analysis.

For example:

- If there is no physical connectivity, the problem may be at Layer 1.
- If ARP fails, the issue may involve Layer 2.
- If there is no route to a destination, the issue may involve Layer 3.
- If a TCP connection cannot be established, the issue may involve Layer 4.
- If the connection works but the application fails, the issue may involve Layer 7.

From a cybersecurity point of view, the OSI model helps classify observations during an investigation.

For example:

```text
Port scanning        -> Transport/Application
DNS tunnelling       -> Application
ARP spoofing         -> Data Link
Suspicious routing   -> Network
Clear-text HTTP      -> Application/Presentation
```

---

## TCP/IP model

The TCP/IP model is a practical model used to describe how real internet communication works.

A simplified version has four layers:

```text
Application
Transport
Internet
Network Access
```

The relationship with the OSI model can be understood approximately as:

| TCP/IP layer | Related OSI layers |
|---|---|
| Application | OSI Layers 5, 6 and 7 |
| Transport | OSI Layer 4 |
| Internet | OSI Layer 3 |
| Network Access | OSI Layers 1 and 2 |

The TCP/IP model is useful because it maps more directly to the protocols used in real networks, such as:

```text
HTTP
DNS
TCP
UDP
IP
Ethernet
```

---

## Encapsulation

Encapsulation is the process where each network layer adds its own information to the data before transmission.

For example, when a client sends an HTTP request, the process can be understood like this:

```text
HTTP data
  ↓
TCP segment
  ↓
IP packet
  ↓
Ethernet frame
  ↓
Physical transmission
```

Each layer adds its own header.

Example:

```text
HTTP request:
GET / HTTP/1.1

TCP adds:
source port and destination port

IP adds:
source IP and destination IP

Ethernet adds:
source MAC and destination MAC
```

When the receiving system gets the data, the process is reversed. Each layer reads and removes its corresponding header.

This is called decapsulation.

---

## IP addresses

An IP address identifies a host or interface at the network layer.

In my own machine, I observed:

```text
enp4s0 -> 192.168.1.52/24
wlo1   -> 192.168.1.51/24
```

These are private IPv4 addresses inside the local network.

An IP address allows the operating system to know where packets come from and where they should be sent.

For example:

```text
Source IP:      192.168.1.52
Destination IP: 8.8.8.8
```

The IP address alone is not enough to identify an application. For that, ports are also needed.

---

## Subnets and CIDR

A subnet is a logical division of an IP network.

CIDR notation indicates how many bits are used for the network portion of the address.

Example:

```text
192.168.1.52/24
```

The `/24` means that the first 24 bits identify the network.

For this network:

```text
Network address:   192.168.1.0
Subnet mask:       255.255.255.0
Broadcast address: 192.168.1.255
Usable range:      192.168.1.1 - 192.168.1.254
```

In my Docker networking lab, I created networks such as:

```text
172.30.0.0/24
172.31.0.0/24
```

This made it easier to understand how hosts inside the same subnet can communicate directly.

---

## TCP

TCP is a connection-oriented transport protocol.

It provides:

- reliable delivery;
- ordered delivery;
- retransmission of lost data;
- flow control;
- connection establishment before data transfer.

The beginning of a TCP connection is called the three-way handshake.

It consists of:

```text
1. SYN
2. SYN-ACK
3. ACK
```

In my `tcpdump` lab, I observed the handshake between:

```text
Client: 172.31.0.3
Server: 172.31.0.2:80
```

Example:

```text
172.31.0.3 -> 172.31.0.2 Flags [S]
172.31.0.2 -> 172.31.0.3 Flags [S.]
172.31.0.3 -> 172.31.0.2 Flags [.]
```

Meaning:

```text
SYN      -> client requests a connection
SYN-ACK  -> server accepts and acknowledges
ACK      -> client confirms
```

After this, application data such as HTTP can be exchanged.

---

## UDP

UDP is a connectionless transport protocol.

Unlike TCP, UDP does not establish a connection before sending data.

It does not guarantee:

- delivery;
- ordering;
- retransmission;
- reliability.

However, UDP has lower overhead and can be faster for certain use cases.

Examples of protocols that commonly use UDP include:

```text
DNS
DHCP
NTP
VoIP
video streaming
```

UDP is useful when speed or simplicity is more important than guaranteed delivery.

From a security perspective, UDP is important because many scanning, discovery and amplification attacks involve UDP-based services.

---

## Ports

Ports identify specific services or applications on a host.

An IP address identifies the machine or interface.

A port identifies the service.

Example:

```text
172.31.0.2:80
```

This means:

```text
Host: 172.31.0.2
Port: 80
Service: HTTP
```

Common examples:

```text
HTTP   -> TCP/80
HTTPS  -> TCP/443
SSH    -> TCP/22
DNS    -> UDP/53 and TCP/53
DHCP   -> UDP/67 and UDP/68
```

In my Linux lab, I inspected listening ports using:

```bash
ss -tuln
sudo ss -tulpn
```

This is important in security because every listening port may represent part of the system's attack surface.

A service listening on:

```text
127.0.0.1
```

is only available locally.

A service listening on:

```text
0.0.0.0
```

may be reachable through all IPv4 interfaces, depending on firewall and network configuration.

---

# Networking Essentials

## DHCP

DHCP allows a host to automatically receive network configuration.

A DHCP server can provide:

- IP address;
- subnet mask;
- default gateway;
- DNS servers;
- lease time.

In my own machine, the addresses:

```text
192.168.1.52/24
192.168.1.51/24
```

were assigned through DHCP.

The routing table showed:

```text
proto dhcp
```

which indicates that the route information was provided dynamically.

DHCP is useful because it avoids manually configuring every device in a network.

From a security point of view, DHCP is relevant because a rogue DHCP server could provide malicious network configuration, such as an attacker-controlled gateway or DNS server.

---

## ARP

ARP stands for Address Resolution Protocol.

It maps an IPv4 address to a MAC address inside a local network.

Example:

```text
192.168.1.1 -> dc:08:da:8c:9b:40
```

In my lab, I inspected ARP/neighbour information with:

```bash
ip neigh
```

This showed which MAC addresses were associated with local IP addresses.

ARP is needed because IP addresses operate at the network layer, while Ethernet communication inside the local network uses MAC addresses.

Conceptually:

```text
I want to send traffic to 192.168.1.1
        ↓
Who has 192.168.1.1?
        ↓
ARP response gives the MAC address
        ↓
Ethernet frame can be sent
```

From a security point of view, ARP is important because attacks such as ARP spoofing can redirect local network traffic through an attacker-controlled machine.

---

## ICMP

ICMP is used for network control and diagnostic messages.

The most familiar use is:

```bash
ping
```

A ping uses:

```text
ICMP Echo Request
ICMP Echo Reply
```

In my `tcpdump` lab, I captured ICMP traffic and observed that three successful ping attempts generated:

```text
3 Echo Requests
3 Echo Replies
```

ICMP is useful for troubleshooting because it helps determine whether a host is reachable.

However, ICMP can also be restricted by firewalls, so the absence of a ping response does not always prove that a host is offline.

---

## Traceroute

Traceroute helps identify the path packets take across networks.

It shows the intermediate hops between a source and a destination.

This is useful for understanding:

- where traffic is going;
- where connectivity might fail;
- whether traffic follows an expected route;
- network latency between hops.

Traceroute is useful in security investigations when analyzing unexpected routing paths or possible network segmentation issues.

---

## Routing

Routing determines where packets should be sent.

A route tells the operating system how to reach a destination network.

In Linux, routes can be inspected with:

```bash
ip route
```

A default route is used when no more specific route matches the destination.

Example from my machine:

```text
default via 192.168.1.1 dev enp4s0 metric 100
default via 192.168.1.1 dev wlo1 metric 600
```

Both Ethernet and Wi-Fi were active, but Linux preferred:

```text
enp4s0
```

because it had the lower metric:

```text
100 < 600
```

This was confirmed with:

```bash
ip route get 8.8.8.8
```

which showed that traffic to `8.8.8.8` would use:

```text
dev enp4s0
src 192.168.1.52
via 192.168.1.1
```

The gateway is the next-hop router used to reach networks outside the local subnet.

---

## NAT

NAT stands for Network Address Translation.

It allows multiple private IP addresses to share one public IP address when accessing external networks.

This is common in home and corporate networks.

Example:

```text
Private host 1: 192.168.1.52
Private host 2: 192.168.1.51
Private host 3: 192.168.1.20
        ↓
Router performs NAT
        ↓
Public IP address
```

NAT is useful because private IPv4 addresses are not directly routable on the public internet.

NAT also appears in container networking. Docker can use NAT to allow containers in private bridge networks to access external networks.

From a security perspective, NAT affects visibility and attribution because external systems may only see the translated public address, not the internal private host.

---

# Connection with my own labs

## Linux networking lab

The TryHackMe networking rooms connected directly with the Linux commands used in my own lab.

### `ip addr`

This command showed local network interfaces and IP addresses.

Example:

```text
enp4s0 -> 192.168.1.52/24
wlo1   -> 192.168.1.51/24
```

This relates to IP addressing, interfaces and CIDR notation.

### `ip route`

This command showed how Linux decides where packets should be sent.

It helped me understand:

- local routes;
- default routes;
- gateways;
- metrics.

### `ip route get`

This command showed the exact route Linux would use for a specific destination.

Example:

```bash
ip route get 8.8.8.8
```

This made routing more concrete because it showed:

- destination;
- gateway;
- interface;
- source IP.

### `ip neigh`

This command showed local neighbour information.

It relates directly to ARP because it maps IP addresses to MAC addresses on the local network.

### `resolvectl status`

This command showed DNS configuration.

It helped identify the DNS servers used by the system.

### `ss -tuln`

This command showed listening TCP and UDP sockets.

It relates to ports, services and attack surface.

---

## Docker networking lab

The Docker networking labs helped reinforce subnets, gateways, DNS and client-server communication.

I created isolated Docker networks such as:

```text
172.30.0.0/24
172.31.0.0/24
```

In one lab:

```text
net-server -> 172.30.0.2
net-client -> 172.30.0.3
gateway    -> 172.30.0.1
```

In another lab:

```text
pcap-server -> 172.31.0.2
pcap-client -> 172.31.0.3
gateway     -> 172.31.0.1
```

Docker internal DNS allowed containers to communicate using names such as:

```text
net-server
pcap-server
```

instead of manually using IP addresses.

This connected directly with the DNS concepts reviewed in TryHackMe.

---

## tcpdump lab

The `tcpdump` lab made several networking concepts visible.

### ICMP

I captured ping traffic and observed:

```text
Echo Request
Echo Reply
```

### DNS

I observed that names such as:

```text
pcap-server
```

could be resolved to container IP addresses.

### TCP

I captured the TCP three-way handshake:

```text
SYN
SYN-ACK
ACK
```

This helped connect theory about TCP with real packets.

### HTTP

I captured HTTP traffic and observed clear-text content such as:

```text
GET / HTTP/1.1
HTTP/1.1 200 OK
```

This demonstrated that plain HTTP does not encrypt application-layer data.

---

# Security relevance

Networking fundamentals are essential for cybersecurity.

## Exposed services

Listening ports reveal which services are available on a system.

Commands such as:

```bash
ss -tuln
```

help identify local exposure.

In offensive security, exposed services are possible entry points.

In defensive security, they are part of the system's attack surface.

---

## Scanning

Tools such as Nmap rely on networking concepts such as:

- IP addresses;
- ports;
- TCP;
- UDP;
- ICMP;
- service detection.

Understanding TCP and UDP makes scan results easier to interpret.

For example, an open TCP port means that a service is accepting connections.

---

## Suspicious outbound connections

During incident response, it is important to identify unusual outbound connections.

Suspicious indicators may include:

- unknown external IP addresses;
- unusual destination ports;
- repeated beaconing;
- unexpected DNS queries;
- traffic from processes that should not communicate externally.

The earlier Linux incident triage lab included a suspicious connection to:

```text
203.0.113.55:4444
```

Understanding routing, ports and processes helps analyze this kind of event.

---

## DNS investigation

DNS can reveal what domains a host attempted to contact.

This is important because malware often uses DNS to locate command-and-control infrastructure.

Suspicious DNS activity may include:

- rare domains;
- newly registered domains;
- long random-looking subdomains;
- DNS tunnelling patterns;
- unexpected DNS servers.

---

## Network segmentation

Subnets and routing are also important for segmentation.

Segmentation controls which systems can communicate with each other.

For example, a database server should not necessarily be reachable from every workstation.

Docker networks also demonstrate segmentation because containers on different networks may not be able to communicate unless explicitly connected.

---

## Packet capture analysis

Packet captures provide direct evidence of network activity.

They can help identify:

- source and destination IPs;
- ports;
- protocols;
- TCP handshakes;
- DNS queries;
- HTTP requests;
- unencrypted sensitive data;
- suspicious communication patterns.

A `.pcap` file is useful because it can be saved and analyzed later with tools such as:

```text
tcpdump
Wireshark
```

---

# Questions or weak points

The following areas still require more practice:

1. Subnetting beyond simple `/24` networks.

2. Interpreting all TCP flags confidently, especially beyond SYN, ACK, FIN and RST.

3. Understanding NAT in more depth, especially how port translation works.

4. Reading traceroute output and identifying where connectivity problems occur.

5. Distinguishing clearly between OSI and TCP/IP models without memorizing mechanically.

6. Understanding how DNS can be abused in attacks such as tunnelling or command-and-control communication.

---

# Lessons learned

1. Networking is easier to understand when theory is connected with real commands.

2. An IP address identifies a host or interface, while a port identifies a service.

3. CIDR notation defines the size of a network and determines which addresses are local.

4. The default gateway is used when the destination is outside the local network.

5. Linux chooses routes based on route specificity and metrics.

6. ARP maps IPv4 addresses to MAC addresses inside a local network.

7. DNS translates names into IP addresses, while routing decides how to reach those IP addresses.

8. TCP establishes a connection using SYN, SYN-ACK and ACK before transferring application data.

9. UDP is connectionless and has less overhead, but does not provide the same reliability guarantees as TCP.

10. Packet captures make invisible network activity visible.

11. HTTP traffic can expose data in clear text when it is not protected by TLS.

12. Docker networks are useful for safely building isolated networking laboratories.

13. Understanding ports and listening services is fundamental for both attack and defense.

14. Security investigations require correlating different sources: logs, routes, sockets, DNS and packet captures.

15. The same networking concepts appear repeatedly in system administration, penetration testing, incident response and malware analysis.