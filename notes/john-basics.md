# John the Ripper Basics

## Room completed

- TryHackMe — John the Ripper: The Basics

## Objective

The objective of this lab was to understand how password hash cracking works in an authorized and controlled environment.

The focus was on:

- password hashes;
- offline cracking;
- wordlists;
- hash formats;
- salts;
- John the Ripper;
- `john.pot`;
- Linux password hashes;
- password security;
- ethical use of cracking tools.

This lab was performed only with training material and hashes created or provided in an authorized TryHackMe environment.

---

## What is John the Ripper?

John the Ripper is a password cracking tool.

It does not decrypt hashes. Instead, it tests password candidates.

The basic process is:

```text
1. Take a target hash.
2. Take a candidate password from a wordlist.
3. Hash the candidate using the correct format.
4. Compare the generated hash with the target hash.
5. If they match, the candidate is a valid password.
```

Conceptually:

```text
candidate password
        |
        v
hash function
        |
        v
generated hash
        |
        v
compare with target hash
```

If the generated hash matches the target hash, John has found the password.

---

## Offline cracking

Offline cracking happens when an attacker or analyst already has access to password hashes and can test candidates locally.

This is different from online login attempts.

### Online attack

```text
Attacker -> login page / SSH / service
```

The system can apply controls such as:

- rate limiting;
- account lockout;
- MFA;
- logging;
- alerts;
- CAPTCHA.

### Offline attack

```text
Attacker -> stolen hash file -> local cracking machine
```

The attacker can test many candidates without interacting with the original system.

This is why stolen password hash databases are dangerous.

---

## Wordlists

A wordlist is a file containing candidate passwords.

Example:

```text
password
123456
admin
letmein
qwerty
cyberlab
cyberlab123
student
studentpass
cryptography
networking
barcelona
```

John uses the wordlist by taking each word and testing it against the target hash.

Wordlists are effective because many users choose predictable passwords based on:

- common words;
- names;
- years;
- keyboard patterns;
- teams;
- cities;
- simple substitutions;
- words plus numbers.

---

## Custom rules

Custom rules allow John to generate variations of words.

For example, from:

```text
password
```

rules may generate:

```text
Password
password1
password123
Password!
P@ssword
Password2024
```

This is useful because users often modify passwords in predictable ways.

The key idea is:

```text
Custom rules exploit password complexity predictability.
```

They help expand a small wordlist into many realistic password candidates.

---

## Password hashes

A password hash is a one-way representation of a password.

Systems should not store passwords in clear text.

Instead, they should store password hashes.

During login, the system hashes the password attempt and compares it with the stored hash.

Simplified process:

```text
User enters password
        |
        v
System hashes password attempt
        |
        v
Compare with stored hash
```

If the hashes match, the password is accepted.

---

## Deterministic hashes

A hash function is deterministic.

This means:

```text
same input + same algorithm + same parameters = same hash
```

This property allows password verification.

However, it also allows cracking by comparison if an attacker obtains the hash.

---

## Salt

A salt is an additional value combined with the password before hashing.

The purpose of a salt is to ensure that equal passwords do not produce equal stored hashes.

Without salt:

```text
user1: password123 -> same hash
user2: password123 -> same hash
```

With salt:

```text
user1: password123 + saltA -> hash A
user2: password123 + saltB -> hash B
```

A salt makes rainbow tables and universal precomputed hash lists much less useful.

However, a salt does not make a weak password strong. If the attacker has the hash and salt, weak passwords can still be tested.

---

## Hash formats

John needs to know or detect the hash format because different password hashes are calculated differently.

Examples:

```text
raw MD5
md5crypt
sha512crypt
bcrypt
```

The same password produces different hashes depending on the algorithm and format.

For example:

```text
MD5("studentpass") != sha512crypt("studentpass", salt)
```

The `--format` option can be used to tell John explicitly which format to use.

Example:

```bash
john --format=raw-md5 --wordlist=wordlist.txt hash.txt
```

In my local environment, the installed John version did not support `raw-md5` with that format name, so the lab was adapted to use more realistic password hash formats such as `md5crypt` and `sha512crypt`.

---

## Local lab setup

A small wordlist was created:

```bash
mkdir -p exercises/john-basics/hashes
mkdir -p exercises/john-basics/results

cat > exercises/john-basics/wordlist.txt <<'EOF'
password
123456
admin
letmein
qwerty
cyberlab
cyberlab123
student
studentpass
cryptography
networking
barcelona
EOF
```

---

## md5crypt hash

An `md5crypt` hash was created using OpenSSL:

```bash
printf "student:" > exercises/john-basics/hashes/md5crypt.txt
openssl passwd -1 -salt cyberlab "cyberlab123" >> exercises/john-basics/hashes/md5crypt.txt
```

The resulting format looked like:

```text
student:$1$cyberlab$...
```

This was cracked with:

```bash
john \
  --wordlist=exercises/john-basics/wordlist.txt \
  exercises/john-basics/hashes/md5crypt.txt
```

The result was shown with:

```bash
john --show exercises/john-basics/hashes/md5crypt.txt
```

Recovered password:

```text
cyberlab123
```

---

## SHA-512 crypt hash

A SHA-512 crypt hash was created:

```bash
printf "student:" > exercises/john-basics/hashes/sha512crypt.txt
openssl passwd -6 -salt cyberlab "studentpass" >> exercises/john-basics/hashes/sha512crypt.txt
```

The resulting format looked like:

```text
student:$6$cyberlab$...
```

Where:

```text
$6$       -> SHA-512 crypt
cyberlab  -> salt
```

It was cracked with:

```bash
john \
  --wordlist=exercises/john-basics/wordlist.txt \
  exercises/john-basics/hashes/sha512crypt.txt
```

The result was shown with:

```bash
john --show exercises/john-basics/hashes/sha512crypt.txt
```

Recovered password:

```text
studentpass
```

---

## john.pot

John stores cracked hashes in a local pot file.

This is commonly called:

```text
john.pot
```

If John says:

```text
No password hashes left to crack
```

it does not necessarily mean that cracking failed.

It can mean that John already cracked the hash earlier and stored the result.

To view already cracked passwords:

```bash
john --show hash_file.txt
```

In the TryHackMe AttackBox, John indicated that the cracked hash was stored in:

```text
/home/user/src/john/run/john.pot
```

The correct way to display the result was:

```bash
john --show etc_hashes.txt
```

---

## Converting files for John

Some protected files need to be converted into a John-compatible hash format before cracking.

Examples:

```text
zip2john
rar2john
ssh2john
```

### ZIP files

To inspect a ZIP file without extracting it:

```bash
unzip -l file.zip
```

To convert a password-protected ZIP file for John:

```bash
zip2john file.zip > zip_hash.txt
```

Then crack it:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt zip_hash.txt
```

---

### RAR files

To inspect a RAR file without extracting it:

```bash
unrar l file.rar
```

or:

```bash
7z l file.rar
```

To convert a password-protected RAR file for John:

```bash
rar2john file.rar > rar_hash.txt
```

Then crack it:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt rar_hash.txt
```

---

### SSH private keys

Password-protected SSH private keys can also be converted for John.

In my environment, the direct command:

```bash
ssh2john id_rsa > id_rsa_hash.txt
```

did not work because `ssh2john` was not in the PATH.

The solution was to locate the script:

```bash
find / -name "ssh2john*" 2>/dev/null
```

Then execute it with Python and its full path.

Example:

```bash
python3 /usr/share/john/ssh2john.py id_rsa > id_rsa_hash.txt
```

or:

```bash
python3 /home/user/src/john/run/ssh2john.py id_rsa > id_rsa_hash.txt
```

Then crack it with:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt id_rsa_hash.txt
```

And show the result with:

```bash
john --show id_rsa_hash.txt
```

---

## Why weak passwords fail

Weak passwords are vulnerable because they are predictable.

Examples:

```text
studentpass
cyberlab123
password123
admin2024
Barcelona2024
```

These passwords are weak because they often follow human patterns:

```text
word + number
name + year
capital letter + word
word + symbol
keyboard sequence
```

A tool like John can exploit this predictability with wordlists and rules.

---

## Why strong passwords help

Strong passwords increase the search space.

A long random password or strong passphrase is harder to guess.

Examples of stronger passwords:

```text
vP9!xL2@qR8#tZ6
river-copper-mango-planet-74!
```

The goal is not to make cracking mathematically impossible with infinite time.

The goal is to make cracking computationally infeasible with real-world resources.

---

## Defensive measures

To reduce password cracking risk, systems should use:

- strong password policies;
- long passphrases;
- unique salts;
- slow password hashing algorithms;
- bcrypt, scrypt, Argon2 or similar algorithms;
- MFA;
- account lockout for online attacks;
- rate limiting;
- monitoring of authentication logs;
- strict access control over password hash files.

Files such as:

```text
/etc/shadow
```

must be protected because they contain password hashes.

If an attacker steals them, they may attempt offline cracking.

---

## Connection with previous labs

## Hashing

This block connects directly with hashing.

A hash is one-way, so John does not decrypt it.

Instead, John tries candidate passwords, hashes them and compares the result.

---

## Linux incident triage

In the Linux incident triage lab, access to `/etc/shadow` was a suspicious privileged action.

This block explains why that matters.

If an attacker reads `/etc/shadow`, they may be able to extract password hashes and attempt offline cracking.

---

## Web security

Web applications should never store passwords in clear text.

They should store salted password hashes using algorithms designed for password storage.

If a web database is leaked, weak password storage can turn a data breach into an account compromise incident.

---

## Ethical and legal considerations

Password cracking tools must only be used in authorized environments.

Authorized examples:

```text
own lab
CTF
TryHackMe
internal company assessment with permission
```

Unauthorized examples:

```text
third-party hashes
stolen databases
real user credentials without permission
```

The same tool can be used for legitimate auditing or illegal activity. Authorization is what makes the difference.

---

## Lessons learned

1. John the Ripper tests password candidates against hashes.

2. Hashes are not decrypted; they are cracked by guessing and comparison.

3. Offline cracking is dangerous because attackers can test many candidates without interacting with the original system.

4. Wordlists are powerful because many users choose predictable passwords.

5. Custom rules exploit predictable password variations.

6. Salts prevent identical passwords from producing identical stored hashes.

7. Salts reduce the usefulness of rainbow tables but do not make weak passwords strong.

8. Raw fast hashes such as MD5 are not suitable for password storage.

9. Slower password hashing algorithms make mass cracking more expensive.

10. `john --show` displays already cracked passwords.

11. `No password hashes left to crack` often means the result is already stored in `john.pot`.

12. Files such as ZIP, RAR and SSH private keys often need conversion before John can process them.

13. Protecting `/etc/shadow` is critical because it contains password hashes.

14. MFA reduces risk even if a password is cracked.

15. Password cracking tools must only be used with authorization.