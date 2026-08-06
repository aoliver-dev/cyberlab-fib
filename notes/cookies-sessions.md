# Cookies, Sessions and Authentication Lab

## Objective

The objective of this lab was to understand how web applications maintain authenticated sessions using cookies.

The lab focused on:

- login flows;
- session cookies;
- `Set-Cookie` headers;
- `Cookie` request headers;
- cookie jars with `curl`;
- authenticated and unauthenticated access;
- fake session cookies;
- cookie security flags;
- detection of insecure cookie attributes.

This lab builds on the previous HTTP fundamentals lab.

---

## Lab structure

The lab used the following files:

```text
exercises/web-cookies-sessions/
├── logs/
│   └── server.log
├── requests/
│   ├── dashboard-fake-cookie.txt
│   ├── dashboard-with-cookie.txt
│   ├── dashboard-without-cookie.txt
│   ├── insecure-cookie.txt
│   ├── login-success.txt
│   └── secure-cookie.txt
└── results/
    ├── cookies.txt
    ├── insecure-cookie-flags.txt
    ├── secure-cookie-flags.txt
    └── status-summary.txt

scripts/
├── session-lab-server.py
└── check-cookie-flags.sh
```

The lab was performed with a local Python HTTP server listening on:

```text
http://127.0.0.1:8081
```

---

## Session lab server

The server was created as:

```text
scripts/session-lab-server.py
```

It implemented several endpoints:

```text
GET  /                  -> home page
GET  /dashboard          -> authenticated dashboard
POST /login              -> login endpoint
GET  /logout             -> clears the session cookie
GET  /insecure-cookie    -> sets a cookie without security flags
GET  /secure-cookie      -> sets a cookie with HttpOnly and SameSite
```

The server used a fixed lab session value:

```text
authenticated-lab-session
```

This value was only used for local training purposes.

---

## Accessing the dashboard without a cookie

The dashboard was requested without any session cookie:

```bash
curl -i http://127.0.0.1:8081/dashboard \
  > exercises/web-cookies-sessions/requests/dashboard-without-cookie.txt
```

The response was:

```text
HTTP/1.0 401 Unauthorized
```

This means the server refused access because no valid authenticated session was provided.

Security interpretation:

```text
Access to authenticated resources should require a valid server-side session.
```

---

## Login and session creation

A successful login was sent with:

```bash
curl -i -c exercises/web-cookies-sessions/results/cookies.txt \
  -X POST http://127.0.0.1:8081/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=CyberLab123!" \
  > exercises/web-cookies-sessions/requests/login-success.txt
```

The server returned:

```text
HTTP/1.0 200 OK
Set-Cookie: session=authenticated-lab-session; HttpOnly; SameSite=Lax
```

The important part is:

```text
Set-Cookie
```

This header tells the client to store a cookie.

The `curl -c` option saved the cookie to a cookie jar:

```text
exercises/web-cookies-sessions/results/cookies.txt
```

---

## Accessing the dashboard with a valid cookie

The saved cookie was reused with:

```bash
curl -i -b exercises/web-cookies-sessions/results/cookies.txt \
  http://127.0.0.1:8081/dashboard \
  > exercises/web-cookies-sessions/requests/dashboard-with-cookie.txt
```

The response was:

```text
HTTP/1.0 200 OK
Welcome to the authenticated dashboard.
```

This shows the normal session flow:

```text
1. User logs in successfully.
2. Server sends a Set-Cookie header.
3. Client stores the cookie.
4. Client sends the cookie in future requests.
5. Server validates the session cookie.
6. Server grants access to protected resources.
```

---

## Fake cookie test

A fake session cookie was sent manually:

```bash
curl -i \
  -H "Cookie: session=fake-session" \
  http://127.0.0.1:8081/dashboard \
  > exercises/web-cookies-sessions/requests/dashboard-fake-cookie.txt
```

The response was:

```text
HTTP/1.0 401 Unauthorized
```

This proves that the server should not trust arbitrary cookie values.

Security interpretation:

```text
A cookie is only useful if the server validates that the session value is legitimate.
```

If a server accepted predictable or fake session values, it could suffer from session forgery.

---

## Status summary

The status summary was:

```text
Cookies and sessions status summary
===================================

dashboard-fake-cookie.txt: HTTP/1.0 401 Unauthorized
dashboard-with-cookie.txt: HTTP/1.0 200 OK
dashboard-without-cookie.txt: HTTP/1.0 401 Unauthorized
insecure-cookie.txt: HTTP/1.0 200 OK
login-success.txt: HTTP/1.0 200 OK
secure-cookie.txt: HTTP/1.0 200 OK
```

Interpretation:

```text
dashboard without cookie -> denied
dashboard with valid cookie -> allowed
dashboard with fake cookie -> denied
```

This confirms that authenticated access depends on a valid session cookie.

---

## Cookie security flags

Cookies can include security attributes that reduce session-related risk.

Important attributes include:

```text
HttpOnly
SameSite
Secure
```

### HttpOnly

`HttpOnly` prevents client-side JavaScript from reading the cookie.

This reduces the impact of some XSS attacks because injected JavaScript cannot directly steal the session cookie.

### SameSite

`SameSite` controls whether cookies are sent in cross-site requests.

It helps reduce some CSRF-style risks.

Common values include:

```text
SameSite=Lax
SameSite=Strict
SameSite=None
```

### Secure

`Secure` means the cookie should only be sent over HTTPS.

Sensitive session cookies should use `Secure` in production environments.

This lab used local HTTP, so the improved cookie had `HttpOnly` and `SameSite`, but not `Secure`.

---

## Insecure cookie

The insecure cookie response contained:

```text
Set-Cookie: session=insecure-lab-session
```

The checker output was:

```text
[RISK] HttpOnly flag missing.
[RISK] SameSite attribute missing.
[WARNING] Secure flag missing. Sensitive cookies should use Secure over HTTPS.
```

Security interpretation:

```text
The cookie lacks important security attributes.
```

Potential risks:

- JavaScript may be able to access the cookie if XSS exists.
- The cookie may be sent in more cross-site contexts.
- The cookie may be sent over plaintext HTTP if used outside HTTPS.

---

## Improved cookie

The improved cookie response contained:

```text
Set-Cookie: session=better-lab-session; HttpOnly; SameSite=Lax
```

The checker output was:

```text
[OK] HttpOnly flag present.
[OK] SameSite attribute present.
[WARNING] Secure flag missing. Sensitive cookies should use Secure over HTTPS.
```

Security interpretation:

```text
The cookie is better protected, but a production HTTPS session cookie should also include Secure.
```

A stronger production cookie would look conceptually like:

```text
Set-Cookie: session=<random-value>; HttpOnly; SameSite=Lax; Secure
```

---

## Cookie flag checker

A Bash script was created:

```text
scripts/check-cookie-flags.sh
```

The script checks whether a response file contains a `Set-Cookie` header and whether the cookie includes:

- `HttpOnly`;
- `SameSite`;
- `Secure`.

The checker was executed against both cookie responses:

```bash
./scripts/check-cookie-flags.sh exercises/web-cookies-sessions/requests/insecure-cookie.txt
./scripts/check-cookie-flags.sh exercises/web-cookies-sessions/requests/secure-cookie.txt
```

---

## Bug found and fixed

During the lab, the first version of the checker produced a false positive.

It detected the `Secure` flag as present in this cookie:

```text
Set-Cookie: session=insecure-lab-session
```

This was incorrect.

The script matched the word `secure` inside the value:

```text
insecure-lab-session
```

The checker was fixed by splitting the cookie header into attributes and matching full attribute names instead of searching for partial substrings.

Correct logic:

```text
Bad check:
grep -i "Secure"

Better check:
split cookie by semicolon
trim spaces
match attribute name exactly
```

This reduced false positives and made the checker more accurate.

---

## Security relevance

Cookies are central to web authentication.

After login, most web applications do not send the username and password on every request. Instead, they issue a session cookie.

If a session cookie is stolen or forged, an attacker may be able to impersonate the user.

Common session-related risks include:

- missing cookie flags;
- predictable session tokens;
- session fixation;
- stolen cookies through XSS;
- cookies sent over plaintext HTTP;
- weak logout handling;
- insufficient server-side session validation.

This lab focused on the basic foundations needed to understand those vulnerabilities.

---

## Connection with previous labs

## HTTP fundamentals

This lab builds directly on HTTP fundamentals.

The key headers were:

```text
Set-Cookie
Cookie
Content-Type
```

The key status codes were:

```text
200 OK
401 Unauthorized
```

## Password security

The login endpoint connects with password security.

A successful password login creates a session. After that, the session cookie becomes the main proof of authentication for future requests.

## Defensive monitoring

The server logs showed which requests included cookies and which did not.

This connects with log analysis because authentication and session events are important during incident response.

---

## Lessons learned

1. A session cookie allows a web application to remember that a user is authenticated.

2. `Set-Cookie` is sent by the server to create or update a cookie.

3. `Cookie` is sent by the client in future requests.

4. A protected endpoint should deny access without a valid session.

5. A fake cookie should not grant access.

6. `curl -c` saves cookies to a cookie jar.

7. `curl -b` sends cookies from a cookie jar.

8. `HttpOnly` reduces the risk of JavaScript stealing cookies.

9. `SameSite` helps reduce some cross-site request risks.

10. `Secure` ensures that cookies are only sent over HTTPS.

11. Cookie security checks must avoid false positives from partial string matches.

12. Session management is a core topic in web security.
