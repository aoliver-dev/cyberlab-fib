# TryHackMe Cryptography Notes

## Rooms completed

- Cryptography Basics
- Public Key Cryptography Basics
- Hashing Basics

## Objective

The objective of these notes is to understand the basic cryptographic concepts used in cybersecurity and connect them with practical examples.

The focus was on:

- confidentiality;
- integrity;
- authenticity;
- non-repudiation;
- encoding;
- encryption;
- hashing;
- symmetric encryption;
- asymmetric encryption;
- digital signatures;
- certificates;
- TLS;
- practical file integrity checks.

---

# Core security properties

## Confidentiality

Confidentiality means that information should only be accessible to authorized people or systems.

A practical example is HTTPS. When a user sends a password to a website over HTTPS, the content is encrypted so that a passive observer on the network cannot read it directly.

Confidentiality answers the question:

```text
Who can read this data?
```

---

## Integrity

Integrity means that data has not been modified without authorization.

For example, if a file is downloaded from the internet, its SHA-256 hash can be compared with the expected hash. If the hashes match, there is strong evidence that the file has not changed.

Integrity answers the question:

```text
Has this data been modified?
```

---

## Authenticity

Authenticity means that an entity is really who it claims to be.

For example, when visiting an HTTPS website, the browser checks the website certificate to verify that the server is associated with the expected domain.

Authenticity answers the question:

```text
Is this really who it claims to be?
```

---

## Non-repudiation

Non-repudiation means that someone cannot reasonably deny having performed an action.

A practical example is a digital signature. If a document is signed with a private key, and the signature can be verified with the corresponding public key, there is evidence that the holder of the private key signed it.

Non-repudiation answers the question:

```text
Can the sender deny having sent or signed this?
```

---

# Encoding vs encryption vs hashing

## Encoding

Encoding transforms data from one representation to another.

Examples include:

```text
Base64
Hexadecimal
ASCII
URL encoding
```

Encoding is reversible and does not require a secret key.

For example, Base64 can transform readable text into another representation, but anyone can decode it.

Therefore:

```text
Encoding is not security.
```

Encoding is mainly used for compatibility, storage or transmission formats.

---

## Encryption

Encryption transforms readable data into unreadable data using a key.

Important terms:

```text
Plaintext   -> original readable data
Ciphertext  -> encrypted data
Key         -> value used to encrypt or decrypt
Decryption  -> process of recovering plaintext from ciphertext
```

Encryption is designed to protect confidentiality.

Conceptually:

```text
Plaintext + key
      |
      v
Encryption
      |
      v
Ciphertext
```

And then:

```text
Ciphertext + key
      |
      v
Decryption
      |
      v
Plaintext
```

Unlike encoding, encryption requires a key.

---

## Hashing

Hashing transforms input data into a fixed-length output called a hash or digest.

A cryptographic hash function should have these properties:

- the same input always produces the same hash;
- a small change in input produces a very different hash;
- the output has a fixed length;
- it should be computationally infeasible to recover the input from the hash;
- it should be difficult to find two different inputs with the same hash.

Hashing is one-way.

Conceptually:

```text
Input data
    |
    v
Hash function
    |
    v
Fixed-length hash
```

Hashing is mainly used for:

- integrity checks;
- password storage;
- malware identification;
- evidence verification;
- digital signatures;
- Git object identification.

---

# Symmetric encryption

Symmetric encryption uses the same key for encryption and decryption.

Conceptually:

```text
Shared key
   |
   v
Plaintext -> Encryption -> Ciphertext
Ciphertext -> Decryption -> Plaintext
```

## Advantages

Symmetric encryption is usually fast and efficient.

It is commonly used for encrypting large amounts of data.

## Main problem

The main challenge is key distribution.

Both parties need the same secret key, but they need a secure way to share it first.

This creates the key exchange problem:

```text
How do two parties securely agree on a shared secret over an insecure network?
```

---

# Asymmetric encryption

Asymmetric encryption uses a pair of keys:

```text
Public key
Private key
```

The public key can be shared.

The private key must remain secret.

One common idea is:

```text
Data encrypted with a public key can only be decrypted with the corresponding private key.
```

This helps solve part of the key distribution problem because someone can share their public key without exposing their private key.

Asymmetric cryptography is important for:

- secure key exchange;
- digital signatures;
- certificates;
- TLS;
- SSH authentication;
- identity verification.

---

# Digital signatures

A digital signature is used to prove authenticity and integrity.

The signing process uses the private key.

The verification process uses the public key.

Conceptually:

```text
Message + private key
        |
        v
Digital signature
```

Verification:

```text
Message + signature + public key
        |
        v
Valid or invalid
```

A valid digital signature provides evidence that:

- the message was signed by the holder of the private key;
- the message has not been modified after signing.

Digital signatures are not mainly used to hide data. They are used to prove origin and integrity.

---

# Certificates and PKI

A digital certificate links an identity to a public key.

For example, a website certificate links:

```text
Domain name -> Public key
```

A Certificate Authority, or CA, signs certificates.

Browsers trust a set of Certificate Authorities. When a website presents a certificate, the browser checks whether it was issued by a trusted CA and whether it matches the domain being visited.

Certificates are essential for HTTPS because they help the browser verify the server's identity.

Without certificates, encryption alone would not be enough, because the client would not know whether it is communicating with the legitimate server or an attacker.

---

# TLS and HTTPS

TLS stands for Transport Layer Security.

TLS provides three main properties:

```text
Confidentiality
Integrity
Authenticity
```

HTTPS is HTTP protected with TLS.

Conceptually:

```text
HTTP + TLS = HTTPS
```

HTTP normally uses:

```text
TCP/80
```

HTTPS normally uses:

```text
TCP/443
```

In previous packet capture labs, plain HTTP traffic was visible in clear text. It was possible to see:

```text
GET / HTTP/1.1
HTTP/1.1 200 OK
```

With HTTPS, the HTTP content would be encrypted.

However, some metadata would still be visible, such as:

- source IP;
- destination IP;
- destination port;
- timing;
- packet sizes;
- TLS handshake metadata;
- DNS queries before the connection, if not encrypted.

---

# Hashing in cybersecurity

## Password storage

Passwords should not be stored in clear text.

Instead, systems should store password hashes.

When a user logs in, the system hashes the password attempt and compares it with the stored hash.

A simplified process:

```text
User password attempt
        |
        v
Hash function
        |
        v
Compare with stored hash
```

## Salt

Passwords should be hashed with a salt.

A salt is a random value added before hashing.

The purpose of a salt is to ensure that two users with the same password do not have the same hash.

It also makes precomputed attacks such as rainbow tables much less effective.

Conceptually:

```text
Password + salt
       |
       v
Hash function
       |
       v
Stored password hash
```

---

## File integrity

Hashes can verify file integrity.

If the expected hash of a file is known, the file can be checked later.

If the file changes, the hash changes.

This helps detect:

- accidental corruption;
- unauthorized modification;
- tampering;
- incomplete downloads.

---

## Malware identification

Hashes are commonly used to identify known malware samples.

For example, a security analyst may calculate the SHA-256 hash of a suspicious file and compare it with threat intelligence databases.

Important limitation:

```text
A changed malware sample may produce a completely different hash.
```

Therefore, hashes are useful indicators, but they should not be the only detection method.

---

## Evidence verification

During incident response or forensic work, hashes can be used to verify that evidence has not changed.

For example, an analyst can calculate a hash before and after copying an evidence file.

If both hashes match, there is evidence that the copy is identical.

---

## Git commits

Git uses hashes to identify objects and commits.

This helps provide integrity to repository history.

Each commit hash represents the content and metadata of that commit.

This is why changing history or content changes the resulting commit hash.

---

# Local crypto mini-lab

## Base64

A local test file was created:

```bash
echo "CyberLab FIB cryptography test" > exercises/crypto-basics/message.txt
```

The file was encoded with Base64:

```bash
base64 exercises/crypto-basics/message.txt
```

The output was saved:

```bash
base64 exercises/crypto-basics/message.txt > exercises/crypto-basics/message.b64
```

Then it was decoded:

```bash
base64 -d exercises/crypto-basics/message.b64
```

The original text could be recovered.

Conclusion:

```text
Base64 is reversible, so it is encoding and not encryption.
```

Base64 does not provide confidentiality because no secret key is required to decode it.

---

## SHA-256 integrity check

Hashes were calculated for the file:

```bash
md5sum exercises/crypto-basics/message.txt
sha1sum exercises/crypto-basics/message.txt
sha256sum exercises/crypto-basics/message.txt
```

A SHA-256 checksum file was created:

```bash
sha256sum exercises/crypto-basics/message.txt > exercises/crypto-basics/message.sha256
```

The file was verified:

```bash
sha256sum -c exercises/crypto-basics/message.sha256
```

Before modification, the result was:

```text
OK
```

Then the file was modified:

```bash
echo "tampered" >> exercises/crypto-basics/message.txt
```

The integrity check was repeated:

```bash
sha256sum -c exercises/crypto-basics/message.sha256
```

After modification, the verification failed.

Conclusion:

```text
A hash can detect whether a file has changed.
```

This demonstrates the use of hashing for integrity verification.

---

# Security relevance

Cryptography is essential in cybersecurity because it protects data, identities and evidence.

## Data in transit

Protocols such as HTTPS, SSH and VPNs use cryptography to protect data while it travels across networks.

Without encryption, an attacker with access to the network may be able to read sensitive content.

## Password protection

Cryptographic hashing helps protect stored passwords.

Even if a password database is leaked, properly hashed and salted passwords are harder to recover than clear-text passwords.

## File integrity

Hashes allow analysts and users to verify whether files have changed.

This is useful for software downloads, malware analysis, backups and forensic evidence.

## Server authentication

Certificates and PKI help clients verify that they are communicating with the intended server.

This is a key part of HTTPS.

## Incident response

During incident response, cryptography helps with:

- verifying evidence integrity;
- identifying malware by hash;
- checking whether files changed;
- understanding encrypted versus clear-text traffic;
- validating suspicious certificates;
- analyzing secure and insecure protocols.

---

# Connection with previous labs

## HTTP and HTTPS

In the tcpdump and Wireshark labs, HTTP traffic was visible in clear text.

This showed why HTTPS is necessary.

Plain HTTP exposed:

```text
GET / HTTP/1.1
HTTP/1.1 200 OK
```

HTTPS would protect the HTTP content using TLS.

## SSH

SSH uses cryptography to provide secure remote administration.

This connects with previous Linux incident triage work, where SSH authentication logs were important evidence.

## VPN

VPNs use cryptography to create protected tunnels over untrusted networks.

They are important for secure remote access and network segmentation.

## Hashing and Git

The use of hashes also connects with Git, where commits and objects are identified by hashes.

This reinforces the idea that hashes are useful for integrity and identification.

---

# Questions or weak points

The following areas still need more practice:

1. Understanding the TLS handshake in more detail.

2. Understanding certificate chains and how browsers validate them.

3. Distinguishing clearly between encryption, hashing and digital signatures in complex examples.

4. Understanding how salted password hashes are attacked and defended in practice.

5. Understanding the difference between symmetric encryption used for data and asymmetric cryptography used for key exchange or identity.

---

# Lessons learned

1. Encoding is not encryption because it is reversible and does not require a secret key.

2. Base64 should never be considered a security mechanism.

3. Encryption protects confidentiality by transforming plaintext into ciphertext using a key.

4. Hashing is one-way and is mainly used for integrity and identification.

5. Symmetric encryption is fast but requires both parties to share the same secret key.

6. Asymmetric cryptography uses public and private keys.

7. Digital signatures prove authenticity and integrity, not confidentiality.

8. Certificates bind public keys to identities such as domain names.

9. HTTPS protects HTTP with TLS.

10. Hashes can detect whether a file has been modified.

11. Passwords should be stored as salted hashes, not in clear text.

12. Cryptography is used constantly in cybersecurity, including HTTPS, SSH, VPNs, password storage, malware identification and forensic evidence verification.