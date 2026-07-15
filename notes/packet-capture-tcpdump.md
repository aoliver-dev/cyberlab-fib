# Packet Capture and tcpdump Lab

## Objective

The objective of this lab was to capture and analyze network traffic using `tcpdump`.

The exercise focused on:

- ICMP traffic;
- DNS resolution;
- TCP connections;
- the TCP three-way handshake;
- HTTP traffic in clear text;
- capture filters;
- PCAP files.

---

## Environment

The Docker laboratory used the following network:

```text
Network: 172.31.0.0/24
Gateway: 172.31.0.1
Server:  172.31.0.2
Client:  172.31.0.3
```

Topology:

```text
pcap-client                   pcap-server
172.31.0.3                    172.31.0.2
      |                             |
      +-------- pcap-net -----------+
                                    |
                                  Nginx
                                  TCP/80
```

The Docker bridge interface was:

```text
br-cd9524385434
```

---

## Basic tcpdump usage

Available capture interfaces can be listed with:

```bash
tcpdump -D
```

A basic capture on all interfaces is:

```bash
sudo tcpdump -i any -n
```

Important options:

```text
-i    Select interface
-n    Do not resolve addresses to names
-c    Stop after a specific number of packets
-A    Display printable payload as ASCII
-w    Save packets to a PCAP file
-r    Read packets from a PCAP file
```

---

## ICMP analysis

ICMP traffic was generated using:

```bash
ping -c 3 8.8.8.8
```

The capture showed two types of packets:

```text
ICMP echo request
ICMP echo reply
```

For three successful ping requests, the expected result is:

```text
3 Echo Requests
3 Echo Replies
```

A filtered capture can be performed with:

```bash
sudo tcpdump -i any -n -c 6 icmp
```

---

## Docker communication

Connectivity between the Docker containers was verified with:

```bash
docker exec pcap-client ping -c 3 pcap-server
```

Docker resolved:

```text
pcap-server
```

to:

```text
172.31.0.2
```

This allowed the client to communicate with the server without manually specifying its IP address.

---

## TCP three-way handshake

HTTP traffic was generated using:

```bash
docker exec pcap-client curl http://pcap-server
```

The beginning of the TCP connection showed:

```text
1. SYN
2. SYN-ACK
3. ACK
```

Example:

```text
172.31.0.3:49014  -> 172.31.0.2:80    Flags [S]
172.31.0.2:80     -> 172.31.0.3:49014 Flags [S.]
172.31.0.3:49014  -> 172.31.0.2:80    Flags [.]
```

The meaning of these packets is:

- `SYN`: the client requests a TCP connection.
- `SYN-ACK`: the server accepts and acknowledges the request.
- `ACK`: the client acknowledges the server response.

After these three packets, the TCP connection is established.

---

## Duplicate packets with `-i any`

When capturing with:

```bash
sudo tcpdump -i any -n 'net 172.31.0.0/24 and tcp port 80'
```

the same SYN, SYN-ACK and ACK appeared twice.

For example, the SYN was observed through two virtual interfaces:

```text
veth992a878
vethad85f52
```

This did not mean that the client sent two SYN packets.

The same packet was simply observed at two different points while crossing Docker's virtual networking infrastructure.

The packets could be identified as duplicates because they had the same:

- source IP;
- destination IP;
- source port;
- destination port;
- TCP sequence number;
- TCP flags.

Therefore:

```text
3 real TCP packets
6 tcpdump observations
```

To obtain a cleaner capture, the Docker bridge interface can be selected directly:

```bash
sudo tcpdump -i br-cd9524385434 -n 'tcp port 80'
```

---

## HTTP analysis

HTTP traffic was captured with:

```bash
sudo tcpdump -i br-cd9524385434 -n -A 'tcp port 80'
```

The capture allowed HTTP content to be observed directly, including data such as:

```text
GET / HTTP/1.1
Host: pcap-server
```

and the server response:

```text
HTTP/1.1 200 OK
Server: nginx
```

The status code:

```text
200
```

means that the HTTP request was successfully processed.

The content was visible because plain HTTP does not encrypt the application payload.

This is an important security difference compared with HTTPS, where TLS protects the content in transit.

---

## Capture filters

Some useful `tcpdump` filters are:

```text
icmp
tcp
udp
port 80
host 172.31.0.2
src host 172.31.0.3
dst host 172.31.0.2
net 172.31.0.0/24
```

Filters can be combined using:

```text
and
or
not
```

Example:

```bash
sudo tcpdump -i br-cd9524385434 -n \
  'src host 172.31.0.3 and dst host 172.31.0.2 and tcp port 80'
```

---

## PCAP files

A packet capture can be saved with:

```bash
sudo tcpdump \
  -i br-cd9524385434 \
  -n \
  -w exercises/packet-capture-lab/captures/http-session.pcap \
  'tcp port 80'
```

The saved capture can later be read with:

```bash
tcpdump \
  -r exercises/packet-capture-lab/captures/http-session.pcap \
  -n
```

To display printable payload content:

```bash
tcpdump \
  -r exercises/packet-capture-lab/captures/http-session.pcap \
  -n \
  -A
```

This makes PCAP files useful as reusable evidence during security investigations.

---

## Mini challenge answers

### 1. Which IP addresses participated in the HTTP communication?

```text
Client: 172.31.0.3
Server: 172.31.0.2
```

### 2. Which host was the client and which was the server?

```text
172.31.0.3 -> Client
172.31.0.2 -> Server
```

### 3. Which port did the server use?

```text
TCP/80
```

### 4. What are the three steps of the TCP handshake?

```text
SYN
SYN-ACK
ACK
```

### 5. Why was the HTTP request visible?

Because HTTP transmitted the application data without encryption.

### 6. What does HTTP status code `200` mean?

The request was successfully processed.

### 7. Difference between `host` and `dst host`

```text
host 172.31.0.2
```

matches packets where the IP appears as either source or destination.

```text
dst host 172.31.0.2
```

matches only packets whose destination is `172.31.0.2`.

### 8. Difference between `-i` and `-r`

```text
-i
```

captures live traffic from a network interface.

```text
-r
```

reads packets from an existing capture file.

---

## Security relevance

Packet captures are useful during security investigations because they can reveal:

- suspicious external connections;
- unexpected protocols or ports;
- scanning activity;
- command-and-control traffic;
- DNS activity;
- unencrypted credentials or sensitive information;
- communication between compromised systems.

A PCAP file also allows captured traffic to be preserved and analyzed later with tools such as `tcpdump` or Wireshark.

---

## Lessons learned

1. `tcpdump` can capture network traffic directly from a Linux system.

2. Capture filters help reduce noise and focus only on relevant traffic.

3. A TCP connection normally begins with SYN, SYN-ACK and ACK.

4. HTTP traffic can expose application data because it is not encrypted.

5. Capturing on `any` may show the same packet multiple times when Docker virtual interfaces are involved.

6. Choosing the correct capture interface is important for obtaining clean and understandable results.

7. PCAP files provide reusable evidence that can be inspected after the original traffic has disappeared.