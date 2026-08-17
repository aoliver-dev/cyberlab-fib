# SQL Injection Basics Lab

## Objective

The objective of this lab was to understand the basics of SQL injection by comparing vulnerable SQL string concatenation with secure parameterized queries.

The lab focused on:

- SQL injection;
- vulnerable query construction;
- parameterized queries;
- authentication bypass;
- data exposure through injected conditions;
- HTTP status codes;
- secure vs insecure database access;
- Bash-based result analysis.

This lab completes the Web Security Foundations week.

---

## Lab structure

The lab used the following files:

```text
exercises/web-sql-injection/
├── logs/
│   └── sql-injection.log
├── requests/
│   ├── login-bypass-secure.txt
│   ├── login-bypass-vulnerable.txt
│   ├── user-injection-secure.txt
│   ├── user-injection-vulnerable.txt
│   └── user-normal-vulnerable.txt
└── results/
    ├── sqli-analysis.txt
    └── status-summary.txt

scripts/
├── sql-injection-lab-server.py
└── analyze-sqli-results.sh
```

The SQLite database was generated locally when the server started and was not committed to Git.

---

## What is SQL injection?

SQL injection happens when user-controlled input is inserted directly into a SQL query as executable SQL code.

The vulnerable pattern is:

```text
user input + SQL string concatenation
```

Example:

```python
sql = "SELECT * FROM users WHERE id = " + user_input
```

If the user input is:

```text
2 OR 1=1
```

the final SQL query may become:

```sql
SELECT * FROM users WHERE id = 2 OR 1=1
```

The condition:

```sql
OR 1=1
```

is always true, so the query can return more data than intended.

---

## Application model

The lab application used a local SQLite database with three users:

```text
user_id=1 username=admin role=admin
user_id=2 username=alice role=user
user_id=3 username=bob role=user
```

The server implemented vulnerable and secure endpoints:

```text
GET  /user-vulnerable?id=<id>
GET  /user-secure?id=<id>
POST /login-vulnerable
POST /login-secure
```

The vulnerable endpoints used string concatenation.

The secure endpoints used parameterized queries.

---

## Normal user lookup

A normal request was sent to the vulnerable user lookup endpoint:

```bash
curl -i "http://127.0.0.1:8084/user-vulnerable?id=2"
```

The response was:

```text
HTTP/1.0 200 OK
```

The endpoint returned Alice's user record:

```text
user_id=2 username=alice role=user email=alice@cyberlab.local
```

This is expected behavior for a normal lookup.

---

## SQL injection in vulnerable user lookup

The following injected request was sent:

```bash
curl -i "http://127.0.0.1:8084/user-vulnerable?id=2%20OR%201=1"
```

The decoded payload was:

```text
2 OR 1=1
```

The vulnerable SQL query became conceptually:

```sql
SELECT id, username, role, email
FROM users
WHERE id = 2 OR 1=1
```

Because `1=1` is always true, the endpoint returned all users.

The response status was:

```text
user-injection-vulnerable.txt: HTTP/1.0 200 OK
```

The analyzer detected:

```text
[ALERT] Vulnerable endpoint returned 3 users for injected id parameter.
```

This demonstrates data exposure through SQL injection.

---

## Same injection against secure user lookup

The same payload was sent to the secure endpoint:

```bash
curl -i "http://127.0.0.1:8084/user-secure?id=2%20OR%201=1"
```

The response was:

```text
user-injection-secure.txt: HTTP/1.0 404 Not Found
```

The analyzer reported:

```text
[OK] Secure endpoint did not return users for injected id parameter.
```

The secure endpoint used a parameterized query:

```python
sql = "SELECT id, username, role, email FROM users WHERE id = ?"
cur.execute(sql, (user_id,))
```

This means the input:

```text
2 OR 1=1
```

was treated as a literal value, not as executable SQL.

---

## Login bypass in vulnerable endpoint

A SQL injection payload was sent to the vulnerable login endpoint:

```bash
curl -i -X POST http://127.0.0.1:8084/login-vulnerable \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=' OR '1'='1"
```

The vulnerable endpoint built the SQL query using string concatenation:

```python
sql = (
    "SELECT id, username, role, email FROM users "
    f"WHERE username = '{username}' AND password = '{password}'"
)
```

With the injected password, the query became conceptually similar to:

```sql
SELECT id, username, role, email
FROM users
WHERE username = 'admin' AND password = '' OR '1'='1'
```

Because:

```sql
'1'='1'
```

is always true, the login was bypassed.

The response was:

```text
login-bypass-vulnerable.txt: HTTP/1.0 200 OK
```

The analyzer detected:

```text
[ALERT] Vulnerable login accepted SQL injection payload.
```

---

## Same login bypass against secure endpoint

The same payload was sent to the secure login endpoint:

```bash
curl -i -X POST http://127.0.0.1:8084/login-secure \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=' OR '1'='1"
```

The response was:

```text
login-bypass-secure.txt: HTTP/1.0 401 Unauthorized
```

The analyzer reported:

```text
[OK] Secure login rejected SQL injection payload.
```

The secure login used a parameterized query:

```python
sql = (
    "SELECT id, username, role, email FROM users "
    "WHERE username = ? AND password = ?"
)

row = cur.execute(sql, (username, password)).fetchone()
```

This prevents the input from changing the structure of the SQL query.

---

## Status summary

The final status summary was:

```text
SQL injection status summary
============================

login-bypass-secure.txt: HTTP/1.0 401 Unauthorized
login-bypass-vulnerable.txt: HTTP/1.0 200 OK
user-injection-secure.txt: HTTP/1.0 404 Not Found
user-injection-vulnerable.txt: HTTP/1.0 200 OK
user-normal-vulnerable.txt: HTTP/1.0 200 OK
```

Key interpretation:

```text
vulnerable endpoints -> injection worked
secure endpoints     -> injection failed
```

---

## Result analyzer

A Bash analyzer was created:

```text
scripts/analyze-sqli-results.sh
```

It checked whether:

- the vulnerable user lookup returned multiple users;
- the secure user lookup returned no users for the injected input;
- the vulnerable login accepted the injection payload;
- the secure login rejected the injection payload.

The final output was:

```text
========================================
SQL INJECTION RESULT ANALYSIS
========================================
Directory: exercises/web-sql-injection/requests

========================================
USER LOOKUP INJECTION
========================================
[ALERT] Vulnerable endpoint returned 3 users for injected id parameter.
[OK] Secure endpoint did not return users for injected id parameter.

========================================
LOGIN BYPASS TEST
========================================
[ALERT] Vulnerable login accepted SQL injection payload.
[OK] Secure login rejected SQL injection payload.
```

---

## Secure coding principle

The core lesson is:

```text
Never build SQL queries by concatenating raw user input.
```

Unsafe pattern:

```python
sql = f"SELECT * FROM users WHERE username = '{username}'"
```

Safer pattern:

```python
sql = "SELECT * FROM users WHERE username = ?"
cur.execute(sql, (username,))
```

Parameterized queries separate:

```text
SQL code
```

from:

```text
user-controlled data
```

This prevents user input from changing the intended query logic.

---

## Security relevance

SQL injection can lead to serious impact, including:

- authentication bypass;
- unauthorized data access;
- data exfiltration;
- modification of database records;
- deletion of data;
- privilege escalation;
- compromise of application logic.

In this lab, SQL injection caused two impacts:

```text
1. User enumeration / data exposure
2. Login bypass
```

These are common introductory examples, but the underlying risk is significant.

---

## Defensive measures

To prevent SQL injection:

1. Use parameterized queries.

2. Avoid string concatenation with user input.

3. Validate input type and format.

4. Apply least privilege to database accounts.

5. Avoid verbose SQL errors in production responses.

6. Log suspicious input patterns.

7. Use secure ORM/query builder patterns correctly.

8. Test endpoints with unexpected input.

9. Use code review for database access logic.

10. Keep database and framework dependencies updated.

The most important measure is parameterized queries.

Input validation helps, but it should not replace parameterization.

---

## HTTP status codes used

This lab used:

```text
200 OK
```

The request succeeded.

```text
401 Unauthorized
```

The login failed.

```text
404 Not Found
```

No matching user was found by the secure lookup.

```text
500 Internal Server Error
```

Would indicate a SQL error if malformed input caused a database exception.

---

## Connection with previous labs

## HTTP fundamentals

The lab used HTTP GET and POST requests.

The injection payload was sent through:

```text
query parameter: id
POST body: username/password
```

## Cookies and sessions

A successful login would normally lead to session creation.

This lab focused on the authentication step before a session is issued.

## Access control

SQL injection can bypass authentication and then lead to unauthorized access.

Access control must still be enforced even after login.

## Password security

The vulnerable login showed that even strong passwords do not help if the application query logic can be bypassed.

## Defensive log analysis

The server log recorded whether endpoints used:

```text
query_type=string_concatenation
query_type=parameterized
```

This helped distinguish vulnerable and secure database access patterns.

---

## Lessons learned

1. SQL injection happens when user input is interpreted as SQL code.

2. String concatenation with user input is dangerous.

3. `OR 1=1` can turn a condition into an always-true expression.

4. A vulnerable lookup can return more rows than intended.

5. A vulnerable login can be bypassed with an injected condition.

6. Parameterized queries treat input as data, not executable SQL.

7. The same payload that works against a vulnerable endpoint fails against a parameterized endpoint.

8. Strong passwords do not protect against SQL injection login bypass.

9. Input validation is useful but does not replace parameterized queries.

10. SQL errors and unusual responses can reveal injection weaknesses.

11. SQL injection can affect confidentiality, integrity and authentication.

12. Secure database access is a core requirement in web application security.
