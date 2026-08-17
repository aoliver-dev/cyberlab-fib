# Access Control and IDOR Lab

## Objective

The objective of this lab was to understand access control vulnerabilities in web applications, especially IDOR.

The lab focused on:

- authentication;
- authorization;
- horizontal privilege escalation;
- vertical privilege escalation;
- IDOR;
- vulnerable access control;
- secure access control;
- HTTP status codes;
- access control logging;
- defensive detection of suspicious access events.

This lab builds on previous work on HTTP, cookies, sessions and login detection.

---

## Lab structure

The lab used the following files:

```text
exercises/web-access-control/
├── logs/
│   └── access-control.log
├── requests/
│   ├── admin-login.txt
│   ├── admin-panel.txt
│   ├── alice-admin-panel.txt
│   ├── alice-bob-profile-secure.txt
│   ├── alice-bob-profile-vulnerable.txt
│   ├── alice-login.txt
│   ├── alice-own-profile-secure.txt
│   └── alice-own-profile-vulnerable.txt
└── results/
    ├── access-control-analysis.txt
    ├── admin-cookies.txt
    ├── alice-cookies.txt
    └── status-summary.txt

scripts/
├── access-control-lab-server.py
└── analyze-access-control.sh
```

---

## Authentication vs authorization

Authentication answers:

```text
Who are you?
```

Authorization answers:

```text
What are you allowed to access?
```

A user can be authenticated but still not authorized to access a specific resource.

Example:

```text
Alice is authenticated.
Alice can access her own profile.
Alice should not access Bob's profile.
Alice should not access the admin panel.
```

This distinction is central to access control security.

---

## Application model

The lab application had three users:

```text
user_id=1 -> admin
user_id=2 -> alice
user_id=3 -> bob
```

The application implemented:

```text
POST /login
GET  /profile?id=<id>
GET  /secure-profile?id=<id>
GET  /admin-panel
```

The `/profile` endpoint was intentionally vulnerable.

The `/secure-profile` endpoint implemented proper authorization checks.

---

## Vulnerable profile endpoint

The vulnerable endpoint was:

```text
/profile?id=<id>
```

The endpoint checked whether the requester had a valid session, but it did not check whether the requested profile belonged to that user.

This means it checked authentication but not authorization.

Conceptually:

```text
User is logged in?
        ↓
yes
        ↓
return requested profile
```

The missing check was:

```text
Does this user own the requested profile?
```

---

## Alice accessing her own profile

Alice logged in successfully:

```text
alice-login.txt: HTTP/1.0 200 OK
```

Then Alice accessed her own profile through the vulnerable endpoint:

```text
alice-own-profile-vulnerable.txt: HTTP/1.0 200 OK
```

This is expected because Alice should be allowed to access her own profile.

---

## IDOR: Alice accessing Bob's profile

Alice then changed the profile ID from:

```text
id=2
```

to:

```text
id=3
```

The vulnerable endpoint returned:

```text
alice-bob-profile-vulnerable.txt: HTTP/1.0 200 OK
```

This is the vulnerability.

Alice was authenticated as user `2`, but she accessed the data of user `3`.

This is an IDOR.

IDOR means Insecure Direct Object Reference.

The application exposed an internal object identifier:

```text
/profile?id=3
```

and failed to verify whether the authenticated user was allowed to access that object.

---

## Horizontal privilege escalation

This is an example of horizontal privilege escalation.

Horizontal privilege escalation happens when a user accesses data or functionality belonging to another user at the same privilege level.

Example:

```text
Alice -> accesses Bob's profile
```

Alice and Bob are both normal users, but Alice should not be able to access Bob's data.

---

## Secure profile endpoint

The secure endpoint was:

```text
/secure-profile?id=<id>
```

This endpoint checked both authentication and authorization.

Simplified logic:

```text
Is the user logged in?
        ↓
yes
        ↓
Is the user admin?
        ↓
yes -> allow

If not admin:
Does requester_id equal target_id?
        ↓
yes -> allow
no  -> deny
```

Alice accessing her own secure profile returned:

```text
alice-own-profile-secure.txt: HTTP/1.0 200 OK
```

Alice trying to access Bob's secure profile returned:

```text
alice-bob-profile-secure.txt: HTTP/1.0 403 Forbidden
```

This is the correct behavior.

---

## Vertical privilege escalation

The lab also included an admin panel:

```text
/admin-panel
```

Alice tried to access the admin panel:

```text
alice-admin-panel.txt: HTTP/1.0 403 Forbidden
```

Admin accessed the admin panel successfully:

```text
admin-panel.txt: HTTP/1.0 200 OK
```

This demonstrates vertical access control.

Vertical privilege escalation happens when a lower-privileged user accesses higher-privileged functionality.

Example:

```text
Normal user -> accesses admin panel
```

In the secure implementation, Alice was correctly denied.

---

## Status summary

The final status summary was:

```text
Access control status summary
=============================

admin-login.txt: HTTP/1.0 200 OK
admin-panel.txt: HTTP/1.0 200 OK
alice-admin-panel.txt: HTTP/1.0 403 Forbidden
alice-bob-profile-secure.txt: HTTP/1.0 403 Forbidden
alice-bob-profile-vulnerable.txt: HTTP/1.0 200 OK
alice-login.txt: HTTP/1.0 200 OK
alice-own-profile-secure.txt: HTTP/1.0 200 OK
alice-own-profile-vulnerable.txt: HTTP/1.0 200 OK
```

Key finding:

```text
alice-bob-profile-vulnerable.txt: HTTP/1.0 200 OK
```

This should not be allowed and represents the IDOR vulnerability.

---

## Access control logs

The application generated logs in:

```text
exercises/web-access-control/logs/access-control.log
```

The analyzer detected:

```text
[ALERT] Possible IDOR: requester=2 accessed target=3 through vulnerable endpoint.
```

Interpretation:

```text
requester=2 -> Alice
target=3    -> Bob
endpoint    -> vulnerable profile endpoint
result      -> allowed
```

This is suspicious because a normal user accessed another user's object.

---

## Forbidden access events

The analyzer also detected forbidden events:

```text
PROFILE_SECURE requester=2 target=3 result=forbidden
ADMIN_PANEL requester=2 result=forbidden
```

Interpretation:

```text
Alice tried to access Bob's secure profile.
The secure endpoint blocked the request.

Alice tried to access the admin panel.
The application blocked the request.
```

Forbidden events are useful for defenders because they may indicate probing or attempted privilege escalation.

---

## Admin panel events

The admin panel events were:

```text
ADMIN_PANEL requester=2 result=forbidden
ADMIN_PANEL requester=1 result=allowed
```

Interpretation:

```text
requester=2 -> Alice -> denied
requester=1 -> Admin -> allowed
```

This confirms that the admin panel correctly enforced role-based access control.

---

## Security relevance

Access control vulnerabilities are among the most serious web application risks.

A user should never be able to access another user's data simply by changing an identifier in the URL.

Risky patterns include:

```text
/profile?id=2
/invoice?id=1001
/order?id=500
/download?file=report.pdf
/api/users/3
```

If the server does not verify ownership or permissions, attackers can access unauthorized resources.

Client-side hiding is not enough.

Access control must be enforced on the server side.

---

## Defensive measures

To prevent IDOR and broken access control:

1. Enforce authorization checks on every sensitive request.

2. Verify that the authenticated user owns or is allowed to access the requested object.

3. Do not rely only on hidden buttons or frontend restrictions.

4. Use server-side role and permission checks.

5. Log denied access attempts.

6. Monitor repeated access to different object IDs.

7. Use indirect references where appropriate, but do not rely on obscurity alone.

8. Test horizontal and vertical privilege escalation cases.

9. Return `403 Forbidden` when the user is authenticated but not authorized.

10. Keep access control logic centralized where possible.

---

## HTTP status codes

This lab used several important HTTP status codes:

```text
200 OK
```

The request succeeded.

```text
401 Unauthorized
```

Authentication is required or missing.

```text
403 Forbidden
```

The user is authenticated or known, but does not have permission.

```text
404 Not Found
```

The requested resource does not exist.

In access control testing, the difference between `401` and `403` is important.

---

## Connection with previous labs

## HTTP fundamentals

The vulnerability was tested by changing the URL query parameter:

```text
/profile?id=2
/profile?id=3
```

This directly uses HTTP request manipulation.

## Cookies and sessions

Alice's authenticated session was stored in a cookie.

The cookie proved who Alice was, but the vulnerable endpoint failed to check what Alice was allowed to access.

## Web login detection

The user first logged in, then performed authorized and unauthorized actions.

This shows that authentication monitoring is not enough. Applications must also monitor authorization failures and suspicious object access.

---

## Lessons learned

1. Authentication and authorization are different concepts.

2. Being logged in does not mean a user can access every resource.

3. IDOR happens when an application exposes object identifiers and fails to enforce authorization.

4. Changing `id=2` to `id=3` can reveal broken access control.

5. Horizontal privilege escalation means accessing another user's data at the same privilege level.

6. Vertical privilege escalation means accessing higher-privileged functionality.

7. Access control must be enforced on the server side.

8. A secure endpoint should return `403 Forbidden` when an authenticated user lacks permission.

9. Logs can reveal suspicious access control behavior.

10. Repeated forbidden events may indicate probing or attempted privilege escalation.

11. Admin-only functionality must check the user's role server-side.

12. Broken access control is one of the most important web security risks.
