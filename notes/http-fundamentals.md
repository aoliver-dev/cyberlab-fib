# HTTP Fundamentals Lab

## Objective

The objective of this lab was to understand the fundamentals of HTTP by building a small local web server and interacting with it using `curl`.

The lab focused on:

- HTTP requests;
- HTTP responses;
- HTTP methods;
- status codes;
- headers;
- cookies;
- login flows;
- server-side logging;
- basic web security interpretation.

This lab is the first block of the Web Security Foundations week.

---

## Lab structure

The lab used the following files:

```text
exercises/web-http-fundamentals/
├── logs/
│   └── server.log
├── requests/
│   ├── custom-headers.txt
│   ├── forbidden-admin.txt
│   ├── get-home.txt
│   ├── login-failed.txt
│   ├── login-success.txt
│   ├── not-found.txt
│   └── set-cookie.txt
└── results/
    └── status-summary.txt

scripts/
└── simple-http-lab-server.py
```

---

## Local HTTP server

A small Python HTTP server was created:

```text
scripts/simple-http-lab-server.py
```

The server listened locally on:

```text
http://127.0.0.1:8080
```

The server implemented several endpoints:

```text
GET  /            -> home page
GET  /admin       -> forbidden area
GET  /headers     -> returns request headers as JSON
GET  /set-cookie  -> sets a session cookie
POST /login       -> login endpoint
```

The server also wrote request logs to:

```text
exercises/web-http-fundamentals/logs/server.log
```

---

## HTTP request and response model

HTTP follows a client-server model.

Conceptually:

```text
client -> HTTP request  -> server
client <- HTTP response <- server
```

An HTTP request usually contains:

```text
method
path
headers
optional body
```

An HTTP response usually contains:

```text
status code
headers
optional body
```

In this lab, `curl` was used to generate HTTP requests and inspect the full HTTP responses.

---

## GET request

The home page was requested with:

```bash
curl -i http://127.0.0.1:8080/ \
  > exercises/web-http-fundamentals/requests/get-home.txt
```

The response returned:

```text
HTTP/1.0 200 OK
```

This means the request was successful.

The response included:

```text
Content-Type: text/html
X-Lab-Server: CyberLab FIB
```

The body contained a simple HTML page.

---

## 404 Not Found

A non-existing resource was requested:

```bash
curl -i http://127.0.0.1:8080/missing \
  > exercises/web-http-fundamentals/requests/not-found.txt
```

The response returned:

```text
HTTP/1.0 404 Not Found
```

This means the requested path does not exist on the server.

Security relevance:

```text
404 responses help identify which resources do not exist.
Attackers often generate many 404 responses while discovering hidden paths.
```

---

## 403 Forbidden

The `/admin` endpoint was requested:

```bash
curl -i http://127.0.0.1:8080/admin \
  > exercises/web-http-fundamentals/requests/forbidden-admin.txt
```

The response returned:

```text
HTTP/1.0 403 Forbidden
```

This means the server understood the request but refused access.

Important distinction:

```text
401 Unauthorized -> authentication required or invalid credentials
403 Forbidden    -> access denied
404 Not Found    -> resource does not exist
```

---

## Custom headers

A request with custom headers was sent:

```bash
curl -i \
  -H "User-Agent: CyberLabClient/1.0" \
  -H "X-Test: hello" \
  http://127.0.0.1:8080/headers \
  > exercises/web-http-fundamentals/requests/custom-headers.txt
```

The server returned the received headers as JSON.

This demonstrated that clients can control many HTTP request headers.

Security relevance:

```text
Headers can influence server behavior.
They are also useful for authentication, content negotiation, tracking and security controls.
```

Examples of important HTTP headers include:

```text
User-Agent
Content-Type
Cookie
Authorization
Host
Referer
Origin
```

---

## Cookies

The `/set-cookie` endpoint was requested:

```bash
curl -i http://127.0.0.1:8080/set-cookie \
  > exercises/web-http-fundamentals/requests/set-cookie.txt
```

The server returned a cookie:

```text
Set-Cookie: session=lab-session-123; HttpOnly; SameSite=Lax
```

A cookie is data sent by the server and stored by the client.

Cookies are often used to maintain sessions after login.

Security-relevant cookie attributes:

```text
HttpOnly
→ JavaScript should not be able to read the cookie.

SameSite=Lax
→ helps reduce some cross-site request risks.

Secure
→ cookie is only sent over HTTPS.
```

This lab used `HttpOnly` and `SameSite=Lax`. In a real HTTPS application, sensitive session cookies should also use `Secure`.

---

## Failed login

A failed login request was sent:

```bash
curl -i -X POST http://127.0.0.1:8080/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=wrong" \
  > exercises/web-http-fundamentals/requests/login-failed.txt
```

The response returned:

```text
HTTP/1.0 401 Unauthorized
```

This means the credentials were invalid.

Security relevance:

```text
Repeated 401 responses may indicate brute force, password spraying or credential stuffing.
```

---

## Successful login

A successful login request was sent:

```bash
curl -i -X POST http://127.0.0.1:8080/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=CyberLab123!" \
  > exercises/web-http-fundamentals/requests/login-success.txt
```

The response returned:

```text
HTTP/1.0 200 OK
```

The server also returned a session cookie:

```text
Set-Cookie: session=authenticated-lab-session; HttpOnly; SameSite=Lax
```

This demonstrates a basic login flow:

```text
client sends credentials
        ↓
server validates credentials
        ↓
server returns success response
        ↓
server sets session cookie
        ↓
client uses cookie in future requests
```

---

## Status summary

A status summary was generated:

```text
HTTP status summary
===================

custom-headers.txt: HTTP/1.0 200 OK
forbidden-admin.txt: HTTP/1.0 403 Forbidden
get-home.txt: HTTP/1.0 200 OK
login-failed.txt: HTTP/1.0 401 Unauthorized
login-success.txt: HTTP/1.0 200 OK
not-found.txt: HTTP/1.0 404 Not Found
set-cookie.txt: HTTP/1.0 200 OK
```

This confirmed that each endpoint behaved as expected.

---

## Server logs

The server logged incoming requests in:

```text
exercises/web-http-fundamentals/logs/server.log
```

Example log events:

```text
GET / from 127.0.0.1
GET /admin from 127.0.0.1
POST /login from 127.0.0.1
```

Security relevance:

```text
Web server logs are essential for detecting scanning, brute force, suspicious paths, authentication failures and unusual client behavior.
```

This connects with previous Linux log analysis work.

---

## Security relevance

HTTP is the foundation of web security.

Before studying vulnerabilities such as SQL injection, XSS, CSRF or authentication flaws, it is necessary to understand:

- how requests are structured;
- how responses are structured;
- how status codes work;
- how headers affect behavior;
- how cookies maintain sessions;
- how login flows create authenticated state.

This lab also shows why tools such as `curl`, Burp Suite and browser developer tools are useful for web security testing.

---

## Lessons learned

1. HTTP requests contain methods, paths, headers and sometimes a body.

2. HTTP responses contain status codes, headers and sometimes a body.

3. `curl -i` is useful because it shows both headers and body.

4. `200 OK` means the request succeeded.

5. `401 Unauthorized` means authentication failed or is required.

6. `403 Forbidden` means access is refused.

7. `404 Not Found` means the requested resource does not exist.

8. Cookies are commonly used to maintain authenticated sessions.

9. `Set-Cookie` is sent by the server to create or update a client cookie.

10. `HttpOnly` helps protect cookies from client-side JavaScript access.

11. `SameSite` helps reduce some cross-site request risks.

12. Server logs are important evidence for web security monitoring.

13. Understanding HTTP is required before studying more advanced web vulnerabilities.
