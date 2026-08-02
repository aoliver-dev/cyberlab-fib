# TLS Certificates and OpenSSL Lab

## Objective

The objective of this lab was to understand the basic components of TLS certificates using OpenSSL.

The lab focused on:

- private keys;
- public certificates;
- self-signed certificates;
- certificate identity;
- issuer and subject fields;
- certificate validity dates;
- certificate serial numbers;
- SHA-256 fingerprints;
- file integrity hashes;
- certificate verification;
- the relationship between TLS, identity and trust.

This lab connects previous cryptography concepts with practical HTTPS/TLS infrastructure.

---

## Lab structure

The lab used the following structure:

```text
exercises/tls-certificates/
├── certs/
│   └── cyberlab.crt
└── results/
    ├── certificate-inspection.txt
    ├── certificate-verification.txt
    ├── certificate-sha256.txt
    └── script-inspection.txt

scripts/
└── inspect-certificate.sh
```

A private key was also generated locally:

```text
exercises/tls-certificates/certs/cyberlab.key
```

However, the private key was intentionally excluded from Git because private keys should not be committed to repositories.

---

## Private key

The private key file was:

```text
cyberlab.key
```

A private key must be protected because it represents control over the cryptographic identity of the certificate.

If an attacker obtains a server private key, they may be able to impersonate that server or compromise encrypted communications depending on the scenario and protocol configuration.

The key was protected locally with restrictive permissions:

```bash
chmod 600 exercises/tls-certificates/certs/cyberlab.key
```

Conceptually:

```text
certificate -> public information
private key -> secret information
```

The certificate can be shared. The private key must not be shared.

---

## Certificate generation

A self-signed certificate was generated with OpenSSL:

```bash
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout exercises/tls-certificates/certs/cyberlab.key \
  -out exercises/tls-certificates/certs/cyberlab.crt \
  -days 7 \
  -subj "/C=ES/ST=Catalonia/L=Barcelona/O=CyberLab FIB/CN=cyberlab.local"
```

This generated:

```text
cyberlab.key -> private key
cyberlab.crt -> public certificate
```

The certificate was valid for seven days.

---

## Certificate inspection

The certificate was inspected with:

```bash
openssl x509 \
  -in exercises/tls-certificates/certs/cyberlab.crt \
  -noout \
  -subject \
  -issuer \
  -dates \
  -serial \
  -fingerprint \
  -sha256
```

The output was:

```text
subject=C = ES, ST = Catalonia, L = Barcelona, O = CyberLab FIB, CN = cyberlab.local
issuer=C = ES, ST = Catalonia, L = Barcelona, O = CyberLab FIB, CN = cyberlab.local
notBefore=Aug  2 18:50:33 2026 GMT
notAfter=Aug  9 18:50:33 2026 GMT
serial=43BC0E66B83A52AFAD3F1DC85B196894C662BEC8
sha256 Fingerprint=19:1B:27:2B:30:FF:56:0B:FF:85:83:B7:65:C4:7C:C2:96:43:DE:95:A1:A6:24:8B:10:8C:22:85:D3:84:2F:45
```

---

## Subject

The subject identifies the entity represented by the certificate.

In this lab, the subject was:

```text
C = ES
ST = Catalonia
L = Barcelona
O = CyberLab FIB
CN = cyberlab.local
```

The most relevant field for this lab is:

```text
CN = cyberlab.local
```

`CN` means Common Name.

In real HTTPS, the browser checks whether the certificate identity matches the domain being visited. Modern certificates usually rely on Subject Alternative Name rather than only CN, but the concept is the same: the certificate must match the identity of the server.

---

## Issuer

The issuer identifies who issued the certificate.

In this lab:

```text
subject = issuer
```

This means the certificate is self-signed.

The same identity created and issued the certificate:

```text
CyberLab FIB issued a certificate for CyberLab FIB
```

In real public HTTPS, the issuer is normally a trusted Certificate Authority.

Examples of real-world certificate authority logic:

```text
Browser trusts CA
        ↓
CA signs certificate
        ↓
Browser trusts website certificate
```

A self-signed certificate does not automatically have public trust. A client must be explicitly configured to trust it.

---

## Validity period

The certificate validity period was:

```text
notBefore=Aug  2 18:50:33 2026 GMT
notAfter=Aug  9 18:50:33 2026 GMT
```

This means the certificate is valid only between those dates.

Certificates have expiration dates to reduce long-term risk and force periodic renewal.

An expired certificate should not be trusted for normal HTTPS use.

---

## Serial number

The certificate serial number was:

```text
43BC0E66B83A52AFAD3F1DC85B196894C662BEC8
```

The serial number uniquely identifies the certificate within the issuing authority context.

Serial numbers are useful for certificate management, revocation and tracking.

---

## SHA-256 fingerprint

The certificate SHA-256 fingerprint was:

```text
19:1B:27:2B:30:FF:56:0B:FF:85:83:B7:65:C4:7C:C2:96:43:DE:95:A1:A6:24:8B:10:8C:22:85:D3:84:2F:45
```

A fingerprint is a hash of the certificate data.

It is useful for identifying a certificate precisely.

If the certificate changes, the fingerprint changes.

This can help detect certificate replacement or verify that two systems are seeing the same certificate.

---

## File SHA-256

The SHA-256 hash of the certificate file was:

```text
57007b0a2103c3e1093cfaacbb3b1006a5374c0e2e280fc87e9fafe0b6db3123  exercises/tls-certificates/certs/cyberlab.crt
```

This hash verifies the integrity of the certificate file as stored on disk.

The file SHA-256 and the certificate fingerprint are related concepts but not identical in practical use:

```text
certificate fingerprint -> identifies the certificate
file sha256sum          -> verifies the file contents on disk
```

Both change if the certificate file changes.

---

## Certificate verification

The certificate was verified with:

```bash
openssl verify \
  -CAfile exercises/tls-certificates/certs/cyberlab.crt \
  exercises/tls-certificates/certs/cyberlab.crt
```

The output was:

```text
exercises/tls-certificates/certs/cyberlab.crt: OK
```

This works because the certificate was provided as its own trusted CA file.

Important distinction:

```text
OpenSSL verification with -CAfile cyberlab.crt
→ trusts this specific self-signed certificate for the test

Public browser trust
→ requires a chain to a trusted CA
```

Therefore, `OK` in this lab does not mean the certificate would automatically be trusted by browsers on the Internet.

It means the certificate verifies successfully when explicitly trusted.

---

## Certificate inspection script

A helper script was created:

```text
scripts/inspect-certificate.sh
```

The script prints:

- certificate identity;
- issuer;
- validity dates;
- serial number;
- SHA-256 fingerprint;
- SHA-256 hash of the certificate file.

It was executed with:

```bash
./scripts/inspect-certificate.sh exercises/tls-certificates/certs/cyberlab.crt
```

The output was saved in:

```text
exercises/tls-certificates/results/script-inspection.txt
```

---

## Script output

The script produced:

```text
========================================
CERTIFICATE INSPECTION
========================================
File: exercises/tls-certificates/certs/cyberlab.crt

========================================
IDENTITY
========================================
subject=C = ES, ST = Catalonia, L = Barcelona, O = CyberLab FIB, CN = cyberlab.local
issuer=C = ES, ST = Catalonia, L = Barcelona, O = CyberLab FIB, CN = cyberlab.local

========================================
VALIDITY
========================================
notBefore=Aug  2 18:50:33 2026 GMT
notAfter=Aug  9 18:50:33 2026 GMT

========================================
SERIAL NUMBER
========================================
serial=43BC0E66B83A52AFAD3F1DC85B196894C662BEC8

========================================
SHA-256 FINGERPRINT
========================================
sha256 Fingerprint=19:1B:27:2B:30:FF:56:0B:FF:85:83:B7:65:C4:7C:C2:96:43:DE:95:A1:A6:24:8B:10:8C:22:85:D3:84:2F:45

========================================
FILE SHA-256
========================================
57007b0a2103c3e1093cfaacbb3b1006a5374c0e2e280fc87e9fafe0b6db3123  exercises/tls-certificates/certs/cyberlab.crt
```

---

## TLS and HTTPS relevance

TLS provides security properties for protocols such as HTTPS.

HTTPS is HTTP over TLS.

TLS helps provide:

```text
confidentiality
integrity
server authentication
```

Certificates are central to server authentication.

When visiting a website over HTTPS, the browser checks:

```text
1. Is the certificate valid?
2. Is it expired?
3. Does it match the domain?
4. Was it issued by a trusted CA?
5. Is the certificate chain valid?
```

If these checks fail, the browser may display a certificate warning.

---

## Self-signed certificates

A self-signed certificate is signed by its own private key instead of a public trusted CA.

Self-signed certificates are useful for:

- labs;
- local development;
- internal testing;
- learning TLS concepts.

However, they are not automatically trusted by browsers or operating systems.

For production public HTTPS, certificates should normally be issued by a trusted CA.

---

## Security relevance

This lab is relevant for cybersecurity because certificates are used in many areas:

- HTTPS websites;
- APIs;
- VPNs;
- internal services;
- mutual TLS;
- code signing;
- secure email;
- infrastructure authentication.

During incident response, certificate information can help detect:

- unexpected certificate changes;
- expired certificates;
- self-signed certificates where they should not exist;
- suspicious issuers;
- possible man-in-the-middle attempts;
- misconfigured TLS services.

---

## Connection with previous labs

## Cryptography basics

This lab connects with asymmetric cryptography.

The certificate contains public information and is associated with a private key.

The private key must remain secret.

---

## Hashing basics

The certificate fingerprint and the file SHA-256 hash connect with hashing.

Both help identify or verify data.

If the certificate changes, the fingerprint and hash change.

---

## Network fundamentals

TLS is used over network protocols such as HTTPS.

Network captures may show TLS handshakes, certificates and encrypted application data.

The encrypted HTTP content is not readable without the necessary keys.

---

## Password and SSH security

SSH also uses cryptographic keys.

The previous SSH hardening lab used public key authentication to reduce password-based attacks.

This TLS lab reinforces the same principle:

```text
private keys must be protected
public keys and certificates can be shared
```

---

## Lessons learned

1. A private key must be protected and should not be committed to Git.

2. A certificate contains public identity and trust information.

3. A self-signed certificate has the same subject and issuer.

4. A self-signed certificate is not automatically trusted by browsers.

5. Certificate validity dates define when the certificate should be accepted.

6. A certificate fingerprint uniquely identifies a certificate.

7. A file hash verifies the integrity of a file on disk.

8. Certificate verification depends on which CA or certificate is trusted.

9. TLS uses certificates to support server authentication.

10. HTTPS protects confidentiality and integrity of web traffic.

11. Certificate inspection is useful for troubleshooting and incident response.

12. OpenSSL is a key tool for inspecting certificates and cryptographic material.
