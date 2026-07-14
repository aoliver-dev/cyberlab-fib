# Network Fundamentals Lab

## Objective

The objective of this laboratory was to build a practical understanding of fundamental networking concepts in Linux and Docker.

The laboratory focused on:

- network interfaces;
- IPv4 addressing;
- CIDR notation;
- routing tables;
- default gateways;
- neighbour discovery;
- DNS resolution;
- listening sockets and exposed services;
- Docker bridge networks;
- container-to-container communication;
- Docker internal DNS;
- basic HTTP communication.

The laboratory combined inspection of the real host network configuration with an isolated Docker network containing a client and an Nginx web server.

---

## Host network inspection

The first step was to inspect the network interfaces configured on the Ubuntu host.

The command used was:

```bash
ip -brief addr
```

The relevant output was:

```text
lo       UNKNOWN   127.0.0.1/8 ::1/128
enp4s0   UP        192.168.1.52/24
wlo1     UP        192.168.1.51/24
docker0  DOWN      172.17.0.1/16
```

The main network interfaces were therefore:

| Interface | State | IPv4 address | Purpose |
|---|---|---|---|
| `lo` | UNKNOWN | `127.0.0.1/8` | Loopback interface |
| `enp4s0` | UP | `192.168.1.52/24` | Ethernet connection |
| `wlo1` | UP | `192.168.1.51/24` | Wireless connection |
| `docker0` | DOWN | `172.17.0.1/16` | Default Docker bridge |

Both physical interfaces were connected to the same local IPv4 network:

```text
192.168.1.0/24
```

The Ethernet interface had:

```text
Interface: enp4s0
IPv4 address: 192.168.1.52
CIDR prefix: /24
```

The Wi-Fi interface had:

```text
Interface: wlo1
IPv4 address: 192.168.1.51
CIDR prefix: /24
```

---

## Interfaces

### Loopback interface: `lo`

The loopback interface allows a host to communicate with itself.

The main IPv4 loopback address is:

```text
127.0.0.1
```

A service listening only on this address is normally accessible only from the local machine.

For example:

```text
127.0.0.1:8000
```

means that a service is listening locally on TCP or UDP port `8000`.

---

### Ethernet interface: `enp4s0`

The Ethernet interface was active with:

```text
192.168.1.52/24
```

It was the preferred interface for outgoing traffic because its route metric was lower than that of the wireless interface.

---

### Wireless interface: `wlo1`

The wireless interface was also active:

```text
192.168.1.51/24
```

It belonged to the same local network as the Ethernet interface.

However, its default route had a higher metric, so Linux normally preferred the Ethernet interface.

---

### Docker interface: `docker0`

Docker created the bridge interface:

```text
docker0
```

with address:

```text
172.17.0.1/16
```

At the time of inspection, the interface was shown as:

```text
DOWN
```

Docker bridge interfaces are virtual networking components used to provide connectivity between containers and, depending on configuration, between containers and external networks.

---

## CIDR and subnet information

The physical interfaces used the prefix:

```text
/24
```

The equivalent decimal subnet mask is:

```text
255.255.255.0
```

For the network:

```text
192.168.1.0/24
```

the theoretical IPv4 information is:

```text
Network address:      192.168.1.0
Broadcast address:    192.168.1.255
First usable host:    192.168.1.1
Last usable host:     192.168.1.254
```

A `/24` prefix means that the first 24 bits identify the network portion of the IPv4 address, while the remaining 8 bits identify hosts inside that network.

---

## Routing

The routing table was inspected with:

```bash
ip route
```

The relevant routes were:

```text
default via 192.168.1.1 dev enp4s0 proto dhcp src 192.168.1.52 metric 100
default via 192.168.1.1 dev wlo1 proto dhcp src 192.168.1.51 metric 600

192.168.1.0/24 dev enp4s0 proto kernel scope link src 192.168.1.52 metric 100
192.168.1.0/24 dev wlo1 proto kernel scope link src 192.168.1.51 metric 600
```

The system had two default routes because both Ethernet and Wi-Fi were active.

Both used the same gateway:

```text
192.168.1.1
```

However, the Ethernet route had:

```text
metric 100
```

while the Wi-Fi route had:

```text
metric 600
```

Therefore, Linux normally preferred:

```text
enp4s0
```

because its route had the lower metric.

The preferred path was confirmed with:

```bash
ip route get 8.8.8.8
```

which returned:

```text
8.8.8.8 via 192.168.1.1 dev enp4s0 src 192.168.1.52
```

This means:

```text
Destination: 8.8.8.8
Gateway:     192.168.1.1
Interface:   enp4s0
Source IP:   192.168.1.52
```

---

## How Linux selects a route

The basic routing decision can be understood using two principles.

### 1. Prefer the most specific route

A route such as:

```text
192.168.1.0/24
```

is more specific than:

```text
default
```

Therefore, traffic destined for the local `192.168.1.0/24` network uses the specific local route instead of the default route.

### 2. When comparable routes exist, prefer the lower metric

In this laboratory:

```text
enp4s0 -> metric 100
wlo1   -> metric 600
```

Therefore, Ethernet was preferred.

The routing table can be interpreted as:

```text
Destination matches 192.168.1.0/24?
        |
       Yes
        |
        v
Use local subnet route
        |
        v
Prefer enp4s0 because metric 100 < 600
```

For a destination outside known local networks:

```text
No more specific route exists
        |
        v
Use default route
        |
        v
Prefer enp4s0 because metric 100 < 600
        |
        v
Send traffic to gateway 192.168.1.1
```

---

## Default gateway

The default gateway was inspected with:

```bash
ip route show default
```

The host had two default routes:

```text
default via 192.168.1.1 dev enp4s0 metric 100
default via 192.168.1.1 dev wlo1 metric 600
```

The default gateway was:

```text
192.168.1.1
```

A default gateway is the next-hop router used when the destination cannot be reached through a more specific route in the local routing table.

For example, when accessing:

```text
8.8.8.8
```

the machine does not have a specific route for that destination. It therefore sends the packet to:

```text
192.168.1.1
```

using the preferred interface:

```text
enp4s0
```

---

## Local route versus remote route

The command:

```bash
ip route get 192.168.1.1
```

returned:

```text
192.168.1.1 dev enp4s0 src 192.168.1.52
```

Unlike the route towards `8.8.8.8`, there was no additional:

```text
via ...
```

because `192.168.1.1` belongs directly to the local subnet:

```text
192.168.1.0/24
```

Therefore, the host can reach it directly at the local network layer.

By contrast:

```text
8.8.8.8 via 192.168.1.1
```

means that `8.8.8.8` is reached indirectly through the router.

---

## Neighbour table

The local neighbour table was inspected using:

```bash
ip neigh
```

Among the results were entries such as:

```text
192.168.1.1 dev wlo1 lladdr dc:08:da:8c:9b:40 REACHABLE
192.168.1.1 dev enp4s0 lladdr dc:08:da:8c:9b:40 REACHABLE
```

This associates the IPv4 address:

```text
192.168.1.1
```

with the MAC address:

```text
dc:08:da:8c:9b:40
```

The gateway was reachable through both active interfaces.

For IPv4 local communication, ARP is used to discover the link-layer MAC address associated with an IP address on the same network.

Conceptually:

```text
IP address
192.168.1.1
       |
       | ARP resolution
       v
MAC address
dc:08:da:8c:9b:40
```

---

## DNS configuration

DNS configuration was inspected using:

```bash
resolvectl status
```

For both active physical interfaces, the configured DNS servers were:

```text
80.58.61.250
80.58.61.254
```

The current DNS server was:

```text
80.58.61.250
```

DNS resolution was tested with:

```bash
getent hosts github.com
```

The result included:

```text
140.82.121.4 github.com
```

Another test was performed using:

```bash
getent hosts example.com
```

which returned IPv6 addresses.

DNS translates human-readable names such as:

```text
github.com
```

into network addresses that systems can use for communication.

Conceptually:

```text
github.com
    |
    | DNS lookup
    v
140.82.121.4
```

---

## DNS versus routing

DNS and routing solve different problems.

### DNS

DNS answers:

> What IP address corresponds to this hostname?

Example:

```text
github.com
    |
    v
140.82.121.4
```

### Routing

Routing answers:

> Through which interface and next hop should a packet be sent to reach this IP address?

Example:

```text
140.82.121.4
       |
       v
default via 192.168.1.1 dev enp4s0
```

The full process can therefore be represented as:

```text
github.com
    |
    | DNS
    v
140.82.121.4
    |
    | Routing decision
    v
Gateway 192.168.1.1
    |
    v
Interface enp4s0
```

DNS identifies the destination address.

Routing determines how packets reach that destination.

---

## Listening sockets

Listening network sockets were inspected using:

```bash
ss -tuln
```

To associate sockets with processes, the following command was used:

```bash
sudo ss -tulpn
```

Relevant TCP listeners included:

```text
127.0.0.54:53
127.0.0.1:631
127.0.0.1:36045
127.0.0.53:53
[::1]:631
```

Some identified processes included:

```text
systemd-resolve
cupsd
confighandler
avahi-daemon
firefox
NetworkManager
```

For example, the CUPS printing service was listening on:

```text
127.0.0.1:631
```

and:

```text
[::1]:631
```

This means it was bound only to the local loopback interfaces rather than all available network interfaces.

---

## Difference between `127.0.0.1` and `0.0.0.0`

A service listening on:

```text
127.0.0.1:8000
```

is bound only to the IPv4 loopback interface.

It is normally accessible only from the same machine.

By contrast:

```text
0.0.0.0:8000
```

means that the service is listening on all available IPv4 interfaces.

For example, a machine with:

```text
192.168.1.52
192.168.1.51
```

could potentially accept connections through either interface when listening on:

```text
0.0.0.0
```

provided that firewall rules, routing and other security controls permit the connection.

This distinction is highly relevant to cybersecurity because unnecessary exposure of a service increases the attack surface.

---

## Docker network laboratory

An isolated Docker bridge network was created using:

```bash
docker network create \
  --driver bridge \
  --subnet 172.30.0.0/24 \
  cyberlab-net
```

The network configuration was:

```text
Name:    cyberlab-net
Driver:  bridge
Subnet:  172.30.0.0/24
Gateway: 172.30.0.1
```

The topology was:

```text
                 cyberlab-net
                 172.30.0.0/24
                        |
                  172.30.0.1
                    Gateway
                        |
            +-----------+-----------+
            |                       |
      net-server                net-client
      172.30.0.2                172.30.0.3
         TCP/80
         Nginx
```

---

## Server container

The Nginx server was created with:

```bash
docker run -d \
  --name net-server \
  --network cyberlab-net \
  nginx:alpine
```

Docker assigned the server:

```text
IPv4 address: 172.30.0.2/24
```

The server exposed:

```text
TCP port 80
```

inside the Docker network.

The server did not require publishing the port to the host for communication with another container connected to the same Docker network.

---

## Client container

The client was created with:

```bash
docker run --rm -it \
  --name net-client \
  --network cyberlab-net \
  alpine:3.20 sh
```

Inside the client, the interface configuration showed:

```text
Interface: eth0
IPv4 address: 172.30.0.3/24
Broadcast: 172.30.0.255
```

Its routing table was:

```text
default via 172.30.0.1 dev eth0
172.30.0.0/24 dev eth0 scope link src 172.30.0.3
```

Therefore:

```text
Client IP: 172.30.0.3
Gateway:   172.30.0.1
Subnet:    172.30.0.0/24
```

---

## Client-server connectivity

Connectivity was tested from `net-client` with:

```sh
ping -c 3 net-server
```

The hostname was resolved to:

```text
172.30.0.2
```

The result showed:

```text
3 packets transmitted
3 packets received
0% packet loss
```

This confirmed successful IP connectivity between the containers.

---

## Docker internal DNS

Name resolution was tested with:

```sh
nslookup net-server
```

The result showed:

```text
Server:  127.0.0.11
Address: 127.0.0.11:53

Name:    net-server
Address: 172.30.0.2
```

Docker provided an internal DNS resolver at:

```text
127.0.0.11
```

This allowed the client to resolve the container name:

```text
net-server
```

to:

```text
172.30.0.2
```

Therefore, it was not necessary to know or manually configure the server IP address beforehand.

Conceptually:

```text
net-client
     |
     | "What IP belongs to net-server?"
     v
Docker internal DNS
127.0.0.11
     |
     | "net-server = 172.30.0.2"
     v
net-client
     |
     | Communicates with 172.30.0.2
     v
net-server
```

---

## HTTP communication

HTTP connectivity was tested with:

```sh
wget -qO- http://net-server
```

The server returned the default Nginx HTML page containing:

```text
Welcome to nginx!
```

This confirmed successful application-layer communication.

The communication flow was:

```text
net-client
    |
    | DNS query for net-server
    v
Docker DNS
    |
    | Returns 172.30.0.2
    v
net-client
    |
    | TCP connection to port 80
    v
net-server
    |
    | HTTP response
    v
Nginx HTML page
```

The application protocol was:

```text
HTTP
```

The default port used was:

```text
TCP/80
```

---

## Container DNS configuration

Inside `net-client`, the file:

```text
/etc/resolv.conf
```

contained:

```text
nameserver 127.0.0.11
```

This confirmed that the container used Docker's embedded DNS resolver.

The container hostname was:

```text
2558a3769a7c
```

Its `/etc/hosts` file included:

```text
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
172.30.0.3      2558a3769a7c
```

This associated the container's own hostname with its Docker-assigned IPv4 address.

---

## Mini challenge answers

### 1. What is the network address of `172.30.0.0/24`?

```text
172.30.0.0
```

---

### 2. What is the decimal subnet mask equivalent to `/24`?

```text
255.255.255.0
```

---

### 3. What is the theoretical host range?

For:

```text
172.30.0.0/24
```

the theoretical usable host range is:

```text
172.30.0.1 - 172.30.0.254
```

The broadcast address is:

```text
172.30.0.255
```

In this Docker network, the gateway occupied:

```text
172.30.0.1
```

---

### 4. What was the real IP address of `net-server`?

```text
172.30.0.2
```

---

### 5. What was the real IP address of `net-client`?

```text
172.30.0.3
```

---

### 6. What gateway did the client use?

```text
172.30.0.1
```

---

### 7. Why did `ping net-server` work without knowing the server IP beforehand?

Because both containers were connected to the same user-defined Docker network:

```text
cyberlab-net
```

Docker provided internal DNS resolution through:

```text
127.0.0.11
```

The hostname:

```text
net-server
```

was automatically resolved to:

```text
172.30.0.2
```

---

### 8. What application protocol was used by `wget http://net-server`?

```text
HTTP
```

---

### 9. What port does the service use by default?

```text
TCP port 80
```

---

### 10. What is the conceptual difference between DNS and routing?

DNS translates names into IP addresses.

Example:

```text
net-server
    |
    | DNS
    v
172.30.0.2
```

Routing determines the path used to reach an IP address.

Example:

```text
172.30.0.2
    |
    | Routing decision
    v
Directly reachable through eth0 on 172.30.0.0/24
```

Therefore:

```text
DNS answers:     "What is the destination IP?"

Routing answers: "How do I reach that destination IP?"
```

---

## Security relevance

Understanding interfaces, routes, DNS and listening sockets is essential in cybersecurity.

### Network interfaces

An analyst must know which interfaces are active and which IP addresses belong to a host.

This helps identify:

- network exposure;
- unexpected interfaces;
- unauthorized tunnels;
- virtual networks;
- Docker networks;
- suspicious additional addresses.

---

### Routing tables

The routing table determines where network traffic is sent.

A malicious or incorrect route could:

- redirect traffic;
- bypass security controls;
- send packets through an unauthorized gateway;
- enable traffic interception;
- create connectivity to unexpected networks.

During an investigation, commands such as:

```bash
ip route
ip route get DESTINATION
```

help determine the actual path selected by the operating system.

---

### DNS

DNS is critical because most applications communicate using hostnames rather than directly using IP addresses.

Security incidents involving DNS may include:

- malicious domain resolution;
- DNS poisoning;
- command-and-control domains;
- DNS tunnelling;
- unauthorized DNS servers;
- unexpected modifications to resolver configuration.

Inspecting DNS configuration can reveal whether a host is using legitimate resolvers.

---

### Listening sockets

Every listening network socket represents a potentially accessible service.

Commands such as:

```bash
ss -tuln
sudo ss -tulpn
```

allow an analyst to determine:

- which ports are listening;
- whether TCP or UDP is used;
- which interface a service is bound to;
- which process owns the socket.

A service bound to:

```text
127.0.0.1
```

has a smaller network exposure than one bound to:

```text
0.0.0.0
```

because the latter potentially listens on every IPv4 interface.

---

### Docker networks

Container networking introduces additional attack surfaces and trust boundaries.

Important questions include:

- Which containers share a network?
- Which services can communicate with each other?
- Which ports are exposed only internally?
- Which ports are published to the host?
- Can containers resolve each other by name?
- Does a compromised container have network access to sensitive services?

Network segmentation remains important even inside containerized environments.

---

## Lessons learned

1. A Linux host may have several active network interfaces and more than one default route.

2. When two comparable routes exist, the route metric influences which path is preferred.

3. In this system, `enp4s0` was preferred over `wlo1` because metric `100` was lower than metric `600`.

4. A `/24` prefix corresponds to the subnet mask `255.255.255.0`.

5. The default gateway is used when no more specific route exists for a destination.

6. DNS translates hostnames into network addresses, whereas routing determines how packets reach those addresses.

7. `ip route get` is useful for determining the exact route, interface and source address Linux would use for a particular destination.

8. The neighbour table maps local IP addresses to link-layer addresses such as MAC addresses.

9. Listening only on `127.0.0.1` creates less external exposure than listening on `0.0.0.0`.

10. User-defined Docker networks provide internal DNS resolution between containers.

11. The Docker client successfully resolved `net-server` to `172.30.0.2` through the internal DNS resolver `127.0.0.11`.

12. Two containers connected to the same Docker network can communicate internally without publishing a service port to the host.

13. The successful HTTP request demonstrated communication across multiple layers: DNS resolution, IP routing, TCP transport and HTTP application traffic.

14. Network configuration is highly relevant in security investigations because interfaces, routes, DNS servers, listening ports and container networks can reveal exposure, misconfiguration or malicious activity.