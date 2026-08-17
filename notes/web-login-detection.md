# Web Login Brute Force Detection Lab

## Objective

The objective of this lab was to detect suspicious authentication activity against a web login endpoint by analyzing structured HTTP login logs.

The lab focused on:

- failed web login attempts;
- successful web login attempts;
- HTTP status codes;
- brute-force detection;
- password spraying detection;
- successful logins after failures;
- structured log parsing with Bash;
- defensive web authentication monitoring.

This lab connects previous work on HTTP, cookies, sessions, password attacks and log analysis.

---

## Lab structure

The lab used the following files:

```text
exercises/web-login-detection/
├── logs/
│   └── web-login.log
└── results/
    ├── login-attack-analysis.txt
    └── traffic-summary.txt

scripts/
├── web-login-lab-server.py
├── generate-web-login-traffic.sh
└── detect-web-login-attacks.sh
```

---

## Web login server

A local Python HTTP server was created:

```text
scripts/web-login-lab-server.py
```

The server listened on:

```text
http://127.0.0.1:8082
```

It implemented a `/login` endpoint.

The endpoint accepted login requests with:

```text
username
password
```

The server returned:

```text
200 OK
```

for successful logins, and:

```text
401 Unauthorized
```

for failed logins.

Passwords were intentionally not written to logs.

---

## Logging format

The server generated structured login logs in:

```text
exercises/web-login-detection/logs/web-login.log
```

Each log entry contained fields such as:

```text
timestamp
ip
method
path
username
result
status
user_agent
```

Example format:

```text
ip=203.0.113.10 method=POST path=/login username=admin result=failed status=401
```

This structure makes the logs easier to analyze with Bash tools.

---

## Simulated traffic

Traffic was generated with:

```text
scripts/generate-web-login-traffic.sh
```

The simulated traffic included:

- brute force against one user;
- password spraying against multiple users;
- successful login after previous failures;
- normal successful login from an internal IP.

The generated summary was:

```text
ip=203.0.113.10 username=admin status=401 label=brute-force
ip=203.0.113.10 username=admin status=401 label=brute-force
ip=203.0.113.10 username=admin status=401 label=brute-force
ip=203.0.113.10 username=admin status=401 label=brute-force
ip=203.0.113.10 username=admin status=401 label=brute-force
ip=198.51.100.77 username=alice status=401 label=password-spraying
ip=198.51.100.77 username=bob status=401 label=password-spraying
ip=198.51.100.77 username=charlie status=401 label=password-spraying
ip=198.51.100.77 username=diana status=401 label=password-spraying
ip=198.51.100.77 username=eric status=401 label=password-spraying
ip=192.0.2.44 username=admin status=401 label=success-after-failures
ip=192.0.2.44 username=admin status=401 label=success-after-failures
ip=192.0.2.44 username=admin status=200 label=success-after-failures
ip=10.0.0.5 username=alice status=200 label=normal-success
```

---

## Detection script

The detection script was created as:

```text
scripts/detect-web-login-attacks.sh
```

It performs the following checks:

1. Basic login statistics.
2. Failed logins grouped by source IP.
3. Failed logins grouped by username.
4. Web login brute-force detection.
5. Web password spraying detection.
6. Successful logins after previous failures.

The script was executed with:

```bash
./scripts/detect-web-login-attacks.sh exercises/web-login-detection/logs/web-login.log
```

The output was saved in:

```text
exercises/web-login-detection/results/login-attack-analysis.txt
```

---

## Basic statistics

The detector produced:

```text
Total login attempts: 14
Failed login attempts: 12
Successful login attempts: 2
```

This shows that most login attempts in the lab were failed attempts.

In real environments, a sudden increase in failed login attempts may indicate credential attacks.

---

## Failed logins by source IP

The detector grouped failed logins by source IP:

```text
5 203.0.113.10
5 198.51.100.77
2 192.0.2.44
```

This helps identify which IP addresses generated failed authentication activity.

However, failed counts by IP are not enough to classify the attack type. The same number of failures can represent different patterns.

---

## Failed logins by user

The detector grouped failed logins by username:

```text
7 admin
1 eric
1 diana
1 charlie
1 bob
1 alice
```

The `admin` account had the highest number of failed attempts.

This happened because:

```text
203.0.113.10 generated 5 failed attempts against admin
192.0.2.44 generated 2 failed attempts against admin
```

This shows that usernames can be targeted by more than one source IP.

---

## Web login brute-force detection

Brute force means repeated login attempts against the same user.

The detector found:

```text
[ALERT] Possible login brute force from 203.0.113.10 against user 'admin' with 5 failed attempts.
```

Interpretation:

```text
Source IP: 203.0.113.10
Target user: admin
Failed attempts: 5
Pattern: same IP, same user, repeated failures
Attack type: possible brute force
```

A good brute-force detector should consider:

```text
source IP + username + failed attempt count
```

Counting only by IP can create false classifications.

---

## Web password spraying detection

Password spraying means trying a common password against many different users.

The detector found:

```text
[ALERT] Possible password spraying from 198.51.100.77 against 5 different users.
```

Interpretation:

```text
Source IP: 198.51.100.77
Target users: alice, bob, charlie, diana, eric
Pattern: same IP, many different users
Attack type: possible password spraying
```

Password spraying can be harder to detect than classic brute force because each individual account may receive only one or two attempts.

---

## Successful login after failures

The detector found:

```text
[WARNING] Successful login for user 'admin' from 192.0.2.44 after 2 failed attempt(s).
```

Interpretation:

```text
Source IP: 192.0.2.44
Target user: admin
Previous failures: 2
Final result: successful login
Risk: possible credential compromise
```

A successful login after previous failed attempts is suspicious because it may indicate that the attacker eventually guessed the correct password.

---

## Normal successful login

The traffic also included a normal successful login:

```text
ip=10.0.0.5 username=alice status=200 label=normal-success
```

This event was not flagged because there were no previous failures from that IP.

This is important because detection logic should avoid flagging normal user activity as suspicious.

---

## Security relevance

Web login endpoints are common targets for attackers.

Typical attacks include:

- brute force;
- password spraying;
- credential stuffing;
- use of leaked passwords;
- attempts against privileged accounts;
- successful login after multiple failures.

HTTP status codes are useful indicators:

```text
401 Unauthorized
→ failed login

200 OK
→ successful login
```

By analyzing sequences of failed and successful logins, defenders can identify suspicious behavior.

---

## Defensive measures

To reduce the risk of web login attacks, applications should use:

- rate limiting;
- account lockout or temporary throttling;
- MFA;
- strong password policies;
- breached password checks;
- login alerting;
- anomaly detection;
- IP reputation checks;
- monitoring of failed and successful login patterns;
- protection against credential stuffing.

A strong detection strategy should look at:

```text
source IP
username
number of failures
number of users targeted
successful login after failures
time window
user agent
geolocation
known device history
```

This lab used a simplified local model but the logic is similar to real-world authentication monitoring.

---

## Connection with previous labs

## HTTP fundamentals

This lab used HTTP POST requests to submit login credentials.

It also used HTTP response status codes:

```text
200 OK
401 Unauthorized
```

## Cookies and sessions

A successful login often creates a session cookie.

This lab focused on detecting suspicious activity before or during authentication.

The previous cookies lab focused on how authenticated state is maintained after login.

## Password attacks

This lab connects directly with brute force and password spraying concepts.

The same attack logic previously studied in SSH logs was applied to web login logs.

## Defensive log analysis

This lab reinforces the idea that logs can reveal attack patterns when parsed correctly.

Simple Bash tools can already extract useful defensive signals from structured logs.

---

## Lessons learned

1. A web login endpoint can be monitored through structured authentication logs.

2. Failed login attempts usually appear as `401 Unauthorized`.

3. Successful login attempts usually appear as `200 OK`.

4. Brute force can be detected by repeated failures from the same IP against the same user.

5. Password spraying can be detected by one IP targeting many different users.

6. A successful login after previous failures is suspicious.

7. Logs should not store passwords.

8. Structured logs make detection easier.

9. Detection logic should avoid confusing brute force with password spraying.

10. Normal successful logins should not be flagged without suspicious context.

11. Authentication monitoring is essential for web security.

12. Web login detection connects HTTP, password security and incident response.
