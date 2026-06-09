# Hash Identifier

> Reinforce your cryptography knowledge while sharpening your Python skills.

A fast, offline CLI tool that analyses a hash string and tells you exactly what it likely is — ranked by confidence, with reasoning.

---

## Features

**What it identifies**

- ~30 hash formats by prefix
- Common hex hashes by digest length (MD5, SHA-1, SHA-256, SHA-512, etc.)
- Pattern-based recognition for MySQL5, NetNTLMv1/v2, and DES crypt
- Non-hash encodings — JWT tokens and Base64 strings are flagged clearly

**What it outputs**

- Ranked candidate list with confidence levels and reasoning for each match
- Fast, one-shot results in milliseconds — no startup overhead

**What it will never do**

- Crack or compute hashes
- Invoke Hashcat, John the Ripper, or any external tool
- Make network requests
- Touch the file system

---

## Prerequisites

- Python **3.13+**

No third-party dependencies required.

---

## Installation

Make the script executable:

```bash
chmod +x hash_identifier
```

---

## Usage

```bash
./hash_identifier '[hash]'
```

**Example**

```bash
./hash_identifier '5f4dcc3b5aa765d61d8327deb882cf99'
```

> **Tip:** Always wrap the hash in single quotes to prevent your shell from interpreting special characters.

---

## Supported Hash Formats

| Category | Examples |
|---|---|
| Standard hex digests | MD5, SHA-1, SHA-224, SHA-256, SHA-384, SHA-512 |
| Password hashes | bcrypt, MySQL4, MySQL5, NTLM, DES crypt |
| Challenge/response | NetNTLMv1, NetNTLMv2 |
| Encodings (flagged) | JWT, Base64 |

---

## License

MIT
