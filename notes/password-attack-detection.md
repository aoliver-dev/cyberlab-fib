# Password Attack Detection Lab

## Objective

The objective of this lab was to detect common password-related attacks by analyzing simulated Linux SSH authentication logs.

This lab connects offensive password cracking concepts from John the Ripper with defensive detection techniques used in Linux incident response.

The lab focused on:

- SSH brute-force detection;
- password spraying detection;
- successful logins after failed attempts;
- suspicious access to `/etc/shadow`;
- Bash-based log parsing;
- defensive interpretation of authentication events.

---

## Lab structure

The lab used the following files:

```text
exercises/password-attack-detection/
├── logs/
│   └── auth.log
└── results/
    └── analysis.txt

scripts/
└── detect-password-attacks.sh
```

The simulated authentication log was stored in:

```text
exercises/password-attack-detection/logs/auth.log
```

The analysis output was saved in:

```text
exercises/password-attack-detection/results/analysis.txt
```

---

## Simulated scenario

The simulated `auth.log` contained several authentication-related events:

- repeated failed SSH login attempts against the `admin` user;
- failed login attempts against multiple different users from the same source IP;
- successful logins after previous failed attempts;
- a privileged command accessing `/etc/shadow`;
- a normal public-key login from an internal IP address.

This allowed the script to identify different authentication attack patterns.

---

## Detection script

The detection script was created as:

```text
scripts/detect-password-attacks.sh
```

The script performs the following checks:

1. Basic authentication log statistics.
2. Failed SSH logins grouped by source IP.
3. Failed SSH logins grouped by target username.
4. Brute-force detection.
5. Password spraying detection.
6. Successful logins after failed attempts.
7. Sensitive file access detection.

The script is executed with:

```bash
./scripts/detect-password-attacks.sh exercises/password-attack-detection/logs/auth.log
```

The result can be saved with:

```bash
./scripts/detect-password-attacks.sh exercises/password-attack-detection/logs/auth.log \
  > exercises/password-attack-detection/results/analysis.txt
```

---

## Basic statistics

The script produced the following basic statistics:

```text
Total lines: 16
Failed SSH logins: 12
Successful SSH logins: 3
```

This gives a quick overview of the authentication activity in the log file.

A high number of failed SSH logins may indicate brute force, password spraying or other credential-based attacks.

---

## Failed logins by source IP

The script grouped failed SSH logins by source IP:

```text
5 203.0.113.10
5 198.51.100.77
2 192.0.2.44
```

This helps identify which IP addresses are generating authentication failures.

However, failed login counts by IP are not enough to classify the attack type correctly.

For example:

```text
Many failures from one IP against one user
→ possible brute force

Failures from one IP against many users
→ possible password spraying
```

---

## Failed logins by user

The script also grouped failed SSH logins by username:

```text
5 admin
2 root
1 eric
1 diana
1 charlie
1 bob
1 alice
```

This helps identify which accounts are being targeted.

In this lab, the `admin` account received five failed login attempts, which is consistent with a brute-force pattern.

---

## Brute-force detection

A brute-force attack consists of many repeated password attempts against the same account.

The script detected:

```text
[ALERT] Possible brute force from 203.0.113.10 against user 'admin' with 5 failed attempts.
```

Interpretation:

```text
Source IP: 203.0.113.10
Target user: admin
Pattern: repeated failed attempts against the same account
Attack type: possible brute force
```

A proper brute-force detector should consider the combination of:

```text
source IP + target user + number of failed attempts
```

This is more accurate than only counting failed attempts by source IP.

---

## Password spraying detection

Password spraying is an attack where the same source tries one or a small number of common passwords against many different users.

Instead of attacking one user many times, the attacker spreads attempts across several accounts.

The script detected:

```text
[ALERT] Possible password spraying from 198.51.100.77 against 5 different users.
```

Interpretation:

```text
Source IP: 198.51.100.77
Target users: alice, bob, charlie, diana, eric
Pattern: one source IP targeting many different users
Attack type: possible password spraying
```

Password spraying can be harder to detect than classic brute force because each individual account may only receive a small number of failed attempts.

---

## Successful logins after failures

The script detected successful logins from IPs that had previously generated failed attempts:

```text
[WARNING] Successful login for user 'bob' from 198.51.100.77 after 5 failed attempt(s).
[WARNING] Successful login for user 'root' from 192.0.2.44 after 2 failed attempt(s).
```

These events are suspicious because a successful login after several failures may indicate that an attacker eventually guessed or obtained a valid password.

The login as `root` is especially sensitive because `root` is a privileged account.

---

## Sensitive file access

The script detected access to `/etc/shadow`:

```text
[CRITICAL] Access to /etc/shadow detected:
Aug  2 10:25:01 server sudo: bob : TTY=pts/1 ; PWD=/home/bob ; USER=root ; COMMAND=/bin/cat /etc/shadow
```

This is a critical event because `/etc/shadow` stores Linux password hashes.

If an attacker can read `/etc/shadow`, they may attempt offline password cracking using tools such as John the Ripper.

Possible attack chain:

```text
compromised account
        ↓
privilege escalation or sudo access
        ↓
read /etc/shadow
        ↓
extract password hashes
        ↓
offline cracking with John the Ripper
```

---

## Final findings

The analysis identified the following findings:

```text
Possible brute force:
- 203.0.113.10 against admin

Possible password spraying:
- 198.51.100.77 against multiple users

Suspicious successful logins:
- bob from 198.51.100.77 after previous failed attempts
- root from 192.0.2.44 after previous failed attempts

Critical sensitive file access:
- bob executed cat /etc/shadow through sudo
```

---

## Security relevance

Authentication logs are a key source of evidence during incident response.

Important detection signals include:

- repeated failed logins from the same source IP;
- repeated failed logins against the same user;
- one source IP targeting many different users;
- successful login after failed attempts;
- successful login to privileged accounts;
- access to sensitive files such as `/etc/shadow`.

This lab shows how simple command-line tools can be used to extract useful security signals from logs.

---

## Defensive measures

To reduce the risk of password-based attacks, a Linux system should use:

- strong password policies;
- long and unique passwords;
- multi-factor authentication where possible;
- SSH key-based authentication;
- disabled direct root SSH login;
- rate limiting;
- account lockout policies;
- tools such as `fail2ban`;
- monitoring of authentication logs;
- alerts for successful logins after repeated failures;
- strict permissions on `/etc/shadow`.

---

## Connection with John the Ripper

This lab connects directly with John the Ripper.

John the Ripper showed how an attacker can crack password hashes offline after obtaining them.

This detection lab showed how defenders can detect the earlier stages of password-related attacks, such as:

```text
brute force
password spraying
successful login after failures
sensitive file access
```

The most important connection is `/etc/shadow`.

If an attacker accesses `/etc/shadow`, they may be able to steal password hashes and crack them offline.

---

## Connection with Linux incident response

This lab also connects with Linux incident triage.

During an incident, authentication logs can help answer questions such as:

```text
Which IPs attempted to log in?
Which users were targeted?
Was there a successful login after failed attempts?
Was a privileged account used?
Was /etc/shadow accessed?
```

These questions are essential for understanding the scope and severity of a Linux compromise.

---

## Lessons learned

1. Failed login counts by IP are useful, but they are not enough by themselves.

2. Brute force should be detected by looking for repeated failures against the same user.

3. Password spraying should be detected by looking for one source targeting many different users.

4. A successful login after failed attempts is suspicious and should be investigated.

5. A successful login as `root` is especially sensitive.

6. Access to `/etc/shadow` is critical because it can lead to offline password cracking.

7. John the Ripper is relevant defensively because defenders need to understand what attackers can do with stolen hashes.

8. Bash tools such as `grep`, `sed`, `awk`, `sort`, `uniq` and `wc` are useful for basic security log analysis.

9. Log analysis connects Linux administration, incident response and password security.

10. Authentication monitoring is an essential part of defensive security.
