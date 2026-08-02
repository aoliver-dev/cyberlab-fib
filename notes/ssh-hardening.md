# SSH Hardening and Fail2ban-Style Defense Lab

## Objective

The objective of this lab was to understand how SSH hardening reduces the risk of password-based attacks and how fail2ban-style logic can automatically block suspicious IP addresses based on authentication failures.

This lab connects previous work on:

- Linux permissions;
- `/etc/shadow`;
- John the Ripper;
- password attack detection;
- authentication log analysis;
- defensive Linux administration.

The lab was performed with simulated configuration files and logs. No real SSH service configuration was modified.

---

## Lab structure

The lab used the following files:

```text
exercises/ssh-hardening/
├── configs/
│   ├── sshd_config.insecure
│   └── sshd_config.hardened
├── logs/
│   └── auth.log
└── results/
    ├── insecure-config-analysis.txt
    ├── hardened-config-analysis.txt
    └── fail2ban-simulation.txt

scripts/
├── check-ssh-hardening.sh
└── simulate-fail2ban.sh
```

---

## SSH hardening

SSH is one of the most sensitive services on a Linux server because it provides remote administrative access.

If SSH is poorly configured, attackers may attempt:

- brute-force attacks;
- password spraying;
- credential stuffing;
- direct root login;
- abuse of old or forgotten user accounts;
- lateral movement through SSH tunneling.

The goal of SSH hardening is to reduce the number of ways an attacker can successfully authenticate or abuse the SSH service.

---

## Insecure SSH configuration

The insecure configuration was stored in:

```text
exercises/ssh-hardening/configs/sshd_config.insecure
```

It contained risky settings such as:

```text
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords yes
MaxAuthTries 10
X11Forwarding yes
AllowTcpForwarding yes
```

These settings increase risk because they allow:

- direct login as `root`;
- password-based SSH access;
- empty passwords;
- many authentication attempts;
- unnecessary SSH features;
- possible tunneling or forwarding abuse.

---

## Hardened SSH configuration

The hardened configuration was stored in:

```text
exercises/ssh-hardening/configs/sshd_config.hardened
```

It included safer settings:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
X11Forwarding no
AllowTcpForwarding no
AllowUsers deploy analyst
```

This configuration reduces risk by:

- blocking direct root login;
- disabling password authentication;
- requiring SSH public key authentication;
- preventing empty passwords;
- limiting authentication attempts;
- disabling unnecessary features;
- restricting SSH access to specific users.

---

## Why direct root login should be disabled

Insecure setting:

```text
PermitRootLogin yes
```

Hardened setting:

```text
PermitRootLogin no
```

The `root` account is the most privileged account on a Linux system.

If direct root login is enabled, attackers already know which account to target. They can repeatedly try to authenticate as `root`.

Example attack pattern:

```text
Failed password for root from 192.0.2.44
Failed password for root from 192.0.2.44
Accepted password for root from 192.0.2.44
```

If the attacker succeeds, they immediately gain administrative access.

Disabling direct root login forces attackers to compromise a normal user first and then attempt privilege escalation. This creates more friction and more audit evidence.

---

## Why password authentication should be disabled

Insecure setting:

```text
PasswordAuthentication yes
```

Hardened setting:

```text
PasswordAuthentication no
```

Password authentication exposes SSH to attacks such as:

- brute force;
- dictionary attacks;
- password spraying;
- credential stuffing.

If password authentication is enabled, an attacker can try credentials such as:

```text
admin:admin
admin:password123
bob:Barcelona2024
root:toor
```

Disabling password authentication prevents SSH access through guessed or leaked passwords.

This is especially important because many password attacks are automated.

---

## Why SSH keys should be used

Hardened setting:

```text
PubkeyAuthentication yes
```

SSH public key authentication uses asymmetric cryptography.

The server stores the public key, while the user keeps the private key.

Conceptually:

```text
Public key  -> stored on the server
Private key -> kept by the user
```

The user is allowed to log in only if they can prove possession of the matching private key.

This is stronger than password authentication because a properly generated private key is not realistically guessable through normal password cracking techniques.

However, private keys must also be protected:

- do not upload private keys to GitHub;
- use a passphrase for private keys;
- store private keys only on trusted devices;
- rotate keys if compromise is suspected.

---

## Why empty passwords should be disabled

Insecure setting:

```text
PermitEmptyPasswords yes
```

Hardened setting:

```text
PermitEmptyPasswords no
```

Empty passwords are extremely dangerous because they allow access without knowing any secret.

A user account with no password could become an immediate entry point into the system.

This setting should be disabled on any real server.

---

## Why authentication attempts should be limited

Insecure setting:

```text
MaxAuthTries 10
```

Hardened setting:

```text
MaxAuthTries 3
```

`MaxAuthTries` controls how many authentication attempts are allowed per SSH connection.

A high value gives attackers more opportunities to test credentials before the connection is closed.

Example:

```text
MaxAuthTries 10
→ one connection can test many passwords

MaxAuthTries 3
→ the connection is closed sooner
```

This does not stop all attacks by itself, but it reduces attacker efficiency and creates more visible authentication failures in logs.

It is especially useful when combined with tools such as fail2ban.

---

## Why unnecessary features should be disabled

Two unnecessary features were disabled in the hardened configuration:

```text
X11Forwarding no
AllowTcpForwarding no
```

The principle is:

```text
Less exposed functionality means less attack surface.
```

### X11 forwarding

Insecure setting:

```text
X11Forwarding yes
```

Hardened setting:

```text
X11Forwarding no
```

X11 forwarding allows graphical applications to be forwarded over SSH.

Most production servers do not need graphical forwarding. If enabled unnecessarily, it increases attack surface.

### TCP forwarding

Insecure setting:

```text
AllowTcpForwarding yes
```

Hardened setting:

```text
AllowTcpForwarding no
```

TCP forwarding allows SSH to create tunnels.

This can be useful for legitimate administration, but it can also be abused by attackers.

Example attack path:

```text
Attacker compromises SSH user
        ↓
Creates SSH tunnel
        ↓
Accesses internal services through the server
```

Possible internal targets include:

```text
databases
internal admin panels
Redis
MySQL
Docker API
private web services
```

If SSH tunneling is not required, it should be disabled.

---

## Why SSH users should be restricted

Hardened setting:

```text
AllowUsers deploy analyst
```

This restricts SSH access to specific users.

Without this restriction, attackers can try many possible local usernames:

```text
root
admin
test
backup
deploy
oracle
ubuntu
user
```

With `AllowUsers`, only explicitly listed users can authenticate through SSH.

This reduces the number of accounts exposed to remote login attacks.

---

## SSH hardening checker script

The script was created as:

```text
scripts/check-ssh-hardening.sh
```

It checks SSH configuration files for risky or missing settings.

The script verifies:

- `PermitRootLogin`;
- `PasswordAuthentication`;
- `PubkeyAuthentication`;
- `PermitEmptyPasswords`;
- `MaxAuthTries`;
- `AllowUsers`;
- `X11Forwarding`;
- `AllowTcpForwarding`.

It was executed against the insecure configuration:

```bash
./scripts/check-ssh-hardening.sh exercises/ssh-hardening/configs/sshd_config.insecure
```

And against the hardened configuration:

```bash
./scripts/check-ssh-hardening.sh exercises/ssh-hardening/configs/sshd_config.hardened
```

---

## Insecure configuration analysis

The insecure configuration produced several risks:

```text
[RISK] PermitRootLogin is set to yes. Expected: no
[RISK] PasswordAuthentication is set to yes. Expected: no
[OK] PubkeyAuthentication is set to yes
[RISK] PermitEmptyPasswords is set to yes. Expected: no
[RISK] MaxAuthTries is set to 10. Recommended: 3 or lower
[WARNING] AllowUsers is not configured. Consider restricting SSH access to specific users.
[RISK] X11Forwarding is set to yes. Expected: no
[RISK] AllowTcpForwarding is set to yes. Expected: no
```

Interpretation:

The insecure configuration allows several dangerous behaviors:

- direct root login;
- password-based authentication;
- empty passwords;
- too many authentication attempts;
- unrestricted SSH users;
- unnecessary forwarding features.

This configuration would be more exposed to credential-based attacks and post-compromise abuse.

---

## Hardened configuration analysis

The hardened configuration produced only successful checks:

```text
[OK] PermitRootLogin is set to no
[OK] PasswordAuthentication is set to no
[OK] PubkeyAuthentication is set to yes
[OK] PermitEmptyPasswords is set to no
[OK] MaxAuthTries is set to 3
[OK] AllowUsers is configured: deploy analyst
[OK] X11Forwarding is set to no
[OK] AllowTcpForwarding is set to no
```

Interpretation:

The hardened configuration reduces the SSH attack surface significantly.

It does not make SSH perfectly secure, but it removes common weaknesses and makes password-based attacks much less effective.

---

## Fail2ban-style defense

Fail2ban is commonly used to monitor authentication logs and temporarily ban IP addresses that produce too many failed login attempts.

This lab implemented a simplified fail2ban-style simulation.

The simulated log was stored in:

```text
exercises/ssh-hardening/logs/auth.log
```

The simulation script was:

```text
scripts/simulate-fail2ban.sh
```

The script was executed with a threshold of five failed attempts:

```bash
./scripts/simulate-fail2ban.sh exercises/ssh-hardening/logs/auth.log 5
```

---

## Failed attempts by IP

The simulation detected:

```text
5 203.0.113.10
5 198.51.100.77
2 192.0.2.44
```

This means:

```text
203.0.113.10 generated 5 failed SSH attempts
198.51.100.77 generated 5 failed SSH attempts
192.0.2.44 generated 2 failed SSH attempts
```

---

## Ban decisions

With a threshold of five failed attempts, the simulator produced:

```text
[BAN] 203.0.113.10 exceeded threshold with 5 failed SSH attempt(s).
[BAN] 198.51.100.77 exceeded threshold with 5 failed SSH attempt(s).
[ALLOW] 192.0.2.44 has 2 failed SSH attempt(s), below threshold.
```

Interpretation:

- `203.0.113.10` would be banned because it reached the threshold.
- `198.51.100.77` would be banned because it reached the threshold.
- `192.0.2.44` would not be banned because it only generated two failed attempts.

---

## Difference between detection and blocking

The previous password attack detection lab classified attack patterns:

```text
brute force
password spraying
successful login after failures
sensitive file access
```

This lab added a blocking-style decision:

```text
too many failed attempts from one IP
        ↓
ban IP
```

The fail2ban-style simulator does not classify the exact attack type. It simply decides whether an IP should be blocked based on the number of failed attempts.

This is useful, but it also has limitations.

---

## Limitations of simple IP-based blocking

A basic fail2ban-style rule can reduce noisy attacks, but it is not perfect.

Limitations include:

1. Distributed attacks may use many IP addresses with few attempts each.

2. Password spraying may stay below per-account thresholds.

3. Legitimate users behind the same IP may be affected if one source IP is banned.

4. Attackers may slow down attempts to avoid thresholds.

5. IP-based detection may not work well when traffic comes through proxies or shared networks.

For stronger defense, blocking should be combined with:

- MFA;
- SSH key authentication;
- disabled password login;
- disabled root login;
- log monitoring;
- alerting;
- network restrictions where possible.

---

## Example attack chain prevented by hardening

Without hardening:

```text
1. Attacker scans for SSH on port 22.
2. Attacker tries root login.
3. Password authentication is enabled.
4. Attacker performs password spraying.
5. A weak password works.
6. Attacker logs in.
7. Attacker reads /etc/shadow.
8. Attacker cracks more hashes offline with John the Ripper.
9. Attacker uses SSH tunneling for internal movement.
```

With hardening:

```text
1. Direct root login is blocked.
2. Password authentication is disabled.
3. Empty passwords are not allowed.
4. Only specific users can access SSH.
5. Authentication attempts are limited.
6. Forwarding features are disabled.
7. Repeated failed attempts can trigger IP bans.
```

Hardening does not guarantee absolute security, but it reduces the probability and impact of successful attacks.

---

## Security relevance

This lab is important because SSH is commonly exposed on Linux servers.

A weak SSH configuration can give attackers a direct path into the system.

A hardened SSH configuration reduces:

- credential-based compromise;
- privilege exposure;
- attack surface;
- lateral movement opportunities;
- brute-force effectiveness.

The fail2ban-style simulation also shows how authentication logs can be used not only for investigation, but also for automatic defensive response.

---

## Lessons learned

1. SSH should not allow direct root login in normal server environments.

2. Password authentication exposes SSH to brute force, spraying and credential stuffing.

3. SSH keys provide stronger authentication than passwords when private keys are properly protected.

4. Empty passwords should never be allowed.

5. Lower `MaxAuthTries` values reduce attacker efficiency.

6. `AllowUsers` limits which accounts can authenticate through SSH.

7. X11 forwarding and TCP forwarding should be disabled when not required.

8. Simple fail2ban-style logic can ban IPs that exceed a failed-login threshold.

9. IP-based blocking is useful but not sufficient against distributed or slow attacks.

10. SSH hardening, log monitoring and password security must work together.

11. Access to `/etc/shadow` remains critical because it can lead to offline password cracking.

12. Defensive security requires both prevention and detection.
