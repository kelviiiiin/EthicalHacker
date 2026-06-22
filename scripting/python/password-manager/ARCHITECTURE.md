# Architecture

This file maps out the program and it's structure. It explains what file holds what, how the layers depend on each other, what the file on disk actually contains, and the step-by-step flow of every CLI command.

---

## 1. The five-file layout

```
password-manager/
├── __init__.py     package entry - re-exports the public API
├── __main__.py     lets `python -m password-manager` work
├── constants.py    every magic number and fixed string
├── crypto.py       Argon2id + AES-256-GCM primitives
├── generator.py    cryptographically secure password generation
├── vault.py        file format, atomic writes, locking, entry CRUD
└── main.py         CLI commands (Typer): init, add, get, list, ...
```

Each file has a strict reason to exist:
| File          | Talks to              | Doesn't talk to              | Job                                                                                |
| ------------- | --------------------- | ---------------------------- | ---------------------------------------------------------------------------------- |
| `constants.py` | Nothing               | Anything                     | Single source of truth for numbers, strings, and tunables                          |
| `crypto.py`   | `constants` only      | Filesystem, network, CLI     | Pure cryptography. Bytes in, bytes out. No I/O.                                    |
| `generator.py`| `constants` only      | Filesystem, network, CLI     | Random password generation. Pure function, no I/O.                                  |
| `vault.py`    | `crypto`, `constants` | The terminal, command-line   | File format, atomic writes, file locking, entry add/get/delete                     |
| `main.py`     | All of the above      | —                            | Glue layer between user keyboard and the rest of the code                          |

**Why these boundaries matter:**

- The crypto file calls *no I/O functions*. No file reads, no `print`, no `input`. This means that it is trivial to test (just call `encrypt(b"Hello", key)`) and impossible to introduce debugging errors at the wrong layer.

- The vault file does not know anything about the terminal. It raises typed exceptions(`VaultNotFoundError`, `WrongPasswordError`, etc.). The CLI catches them and outputs colored error messages. A future GUI or web frontend could be built on `vault.py` without changing any of it.

- The CLI file knows nothing about cryptography. If we swap Argon2id for something newer, `main.py` doesn't change.

---

## 2. The vault file format on disk

The vault is a JSON file which, by default, lives in `~/.password-vault/vault.json` with file permissions `0600` (owner-only).

Here's what the file *roughly* looks like:

```json
{
    "version": 1,
    "kdf": {
        "name": "argon2id",
        "salt": "X3lkR1d2hcKLwk0PXfQpPg==",
        "time_cost": 3,
        "memory_cost": 65536,
        "parallelism": 4
    },
    "cipher": {
        "name": "aes-256-gcm",
        "nonce": "X3lkR1d2hcKLwk0PXfQpPg==",
        "ciphertext": "Yk7eEVTSfA9wL...<lots more base64>...kw==""
    }
}
```

**NOTE:** The ciphertext, salt, and nonces are `base64-encoded` since there is no way to represent raw bytes in JSON. It bloats the data but lets us round-trip bytes through JSON cleanly.

Two layers of JSON live here:

**Outer layer:** plain JSON containing metadata needed to *decrypt* the inner layer.

**Inner layer (the ciphertext):** when decrypted, this is *another* JSON doc - a dictionary of stored creds:

```json
{
    "github": {
        "username": "ruby",
        "password": "blahblah",
        "url": "https://github.com",
        "notes": "",
        "created_at": "2026-05-13T14:22:10+00:00",
        "updated_at": "2026-05-13T14:22:10+00:00"
    }
}
```

**Why JSON?**

- Human-inspectable. You can `cat vault.json` and at least confirm the structure. Useful for debugging.
- Trivially portable. Literally every language has a JSON parser. You can write a reader for this format in Rust or even Go and have it working in no time.
- Forward-compatible. The `version: 1` field lets future versions know how to read today's vault.

---

## 3. Flow: `pv init`

Creates a brand-new empty vault. Step-by-step trace:

```
user types: `pv init`
   │
   ▼
┌─────────────────────────────────────────────────┐
| main.init()                                     |
|   - parse --vault flag (or env, or default path)│
|   - exists check: reject if vault.json exists   |
|   - prompt for master password (twice, confirm) |
|   - validate: non-empty, >= 8 chars, matches    |
└─────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────┐
│ UnlockedVault.create(path, master)              │
|   - generate fresh 16-byte salt (secrets)       |
|   - derive 32-byte key from master + salt       |
|     via Argon2id                                |
|   - build empty entries dict                    |
|   - call self.save()                            |
└─────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────┐
│ vault.save()                                    |
|   - serialize entries (empty {}) to JSON        |
|   - generate fresh 12-byte nonce (secrets)      |
|   - AES-256-GCM encrypt the inner JSON          |
|   - build outer JSON envelope                   |
|   - atomic write to vault.json.tmp              |
|   - fsync data                                  |
|   - os.replace onto vault.json                  |
|   - fsync parent directory                      |
└─────────────────────────────────────────────────┘
   │
   ▼
   `Vault created at ~/.password-vault/vault.json`
```

**NB:**

1. The salt is generated once, at `create()`, and never changes for the life of the vault. It is only regenerated when `change-password` is triggered, re-encrypting everything under a new key; for a given password, the salt is stable.

2. The nonce is generated *every save*, never reused.

---

## 4. Flow: `pv add`

This unlocks the vault, adds an entry, and saves it back. The Argon2id cost (~0.5s) is paid *once* on unlock, then `add` and `save` are both fast.

```

user types: `pv add github`
   │
   ▼
┌─────────────────────────────────────────────────┐
│ main.add()                                      │
│  - prompt for master password                   │
└─────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────┐
│ UnlockedVault.unlock(path, master)              │
│  - read vault.json from disk                    │
│  - parse JSON envelope                          │
│  - validate version + algorithm names           │
│  - validate Argon2 parameters (sanity floors)   │
│  - extract salt, KDF params, nonce, ciphertext  │
│  - derive_key(master, salt, params)  ← slow     │
│  - AES-256-GCM decrypt(ciphertext, nonce, key)  │
│      ↓ if auth tag fails: raise                 │
│        WrongPasswordError → CLI exits with msg  │
│  - parse inner JSON → entries dict              │
│  - return UnlockedVault(path, salt, params,     │
│                          key, entries)          │
└─────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────┐
│ main.add() body, inside `with` block            │
│  - prompt for username (visible)                │
│  - if --generate: generate_password(length)     │
│    else: getpass for password (hidden)          │
│  - prompt for url, notes (optional)             │
│  - build Entry(username, password, url, notes,  │
│                created_at=now, updated_at=now)  │
│  - vault.add_entry(name, entry, force=...)      │
│      ↓ if name exists and not force:            │
│        EntryAlreadyExistsError → CLI exits      │
│      ↓ if name is empty or has whitespace:      │
│        ValueError → CLI exits                   │
│  - vault.save()  (atomic, durable, locked)      │
└─────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────┐
│ end of `with` block → vault.__exit__()          │
│  - vault.entries = {}                           │
│  - vault.key = bytes(32)  (zero-filled)         │
│ (best-effort wipe; Python bytes are immutable,  │
│  but we drop the references at minimum)         │
└─────────────────────────────────────────────────┘
   │
   ▼
   `Added entry: github`
```

The **two failure modes after decryption** are intentional. GCM authentication failure means one of three things and we can't tell which: wrong password, tampered file, corrupted file. Exposing the difference helps an attacker. We collapse them into one honest message.

---

## 5. Flow: `pv get` and `pv list`

They follow the same pattern: unlock, read, render, close. The vault is unlocked just long enough to fetch the data and closed immediately after rendering.

```
pv get github
   │
   ├─► prompt master password
   │
   ├─► UnlockedVault.unlock(...)    (slow once, Argon2id)
   │
   ├─►  entry = vault.get_entry("github")
   |            if not found:
   |            EntryNotFoundError -> CLI exits 1
   │
   ├─► console.print(rich.Panel(...))
   |
   └─► end of `with` -> wipe keys + entries
```

```
pv list
   │
   ├─► prompt master password
   │
   ├─► UnlockedVault.unlock(...)
   │
   ├─► names = vault.names()    (sorted alphabetically)
   │
   ├─► if not names: print "vault is empty" message
   │
   ├─► build a rich.Table with one row per entry
   |        columns: name, username, updated_at (passwords are NOT shown on `list`)
   │
   ├─► console.print(table)
   │
   └─► end of `with` -> wipe key + entries
```

---

## 6. Flow: `pv change-password`

This command rotates the master password by:

- Unlocking the vault with the *old password*.
- Generating a *fresh salt* and deriving a *new key* from the *new password*.
- Saving the vault - `save()` will encrypt the existing entries under the new key, with a fresh nonce.

```
pv change-password
   │
   ├─► prompt: "Current master password: "
   │
   ├─► UnlockedVault.unlock(path, current_password)
   |        if wrong: WrongPasswordError -> exit 1
   │
   ├─► prompt: "New master password: "  (twice, confirm)
   |        validate: non-empty, >= 8 chars, matches
   │
   ├─► vault.change_master_password(new_password)
   |        - new_salt = secrets.token_bytes(16)
   |        - new_key = derive_key(new, new_salt, defaults)
   |        - self.salt = new_salt
   |        - self.kdf_parameters = defaults()
   |        - self.key = new_key
   |        (only mutates the in-memory state - disk is untouched)
   │
   ├─► vault.save()
   |        - serializes the SAME entries dict (preserved)
   |        - generates a NEW nonce
   |        - encrypts under the NEW key
   |        - atomic write replaces the old file
   |
   └─► "Master password changed. Vault re-encrypted at <path>"
```

The vault file stores the KDF params next to the ciphertext, enabling this operation. If the params lived only in the code, then "change my password" would have no way to also "upgrade my Argon2id parameters". Putting them in the file makes the upgrade path possible. The `kdf_parameters` argument on `change_master_password` is the hook of it.

**Crash safely:** if the process dies between the in-memory state and the atomic save, the *file on disk* still has the old salt and old ciphertext - fully readable with the old password. The new key only wins after `os.replace` lands; a botched rotation will never lock you out.

---

## 7. Flow: `pv gen`

This command does not touch the vault at all. It doesn't prompt for the master password. Just generates a strong random password and prints it.

```
pv gen 32
   │
   ▼
generate_password(length=32,
                use_lowercase=True,
                use_uppercase=True,
                use_digits=True,
                use_symbols=True)
   │
   ├─► length >= MIN (8)?
   ├─► at least one pool enabled?
   ├─► length >= number of enabled pools?
   │
   ├─► required = [secrets.choice(pool) for pool in pools]
   |        one char guaranteed from each enabled pool
   |
   ├─► fill = [secrets.choice(combined) for _ in range(length - len(required))]
   │
   ├─► chars = required + fill
   │
   ├─► _secure_shuffle(chars)
   |        Fisher-Yates with secrets.randbelow
   |        (NOT random.shuffle which is predictable)
   │
   └─► return "".join(chars)
```  

The output goes to stdout via plain `print()` instead of `console.print` for piping purposes, i.e:

```bash
pv gen 32 | pbcopy
PASSWORD=$(pv gen 32)
```

---

## 8. Atomic + durable + concurrent-safe writes

The `save()` method does more than apparent. The naive approach would be to use the following one liner:

```python
path.write_bytes(envelope_bytes)
```

This has *three problems*:

1. **Crash mid-write -> corrupt file.** If the process dies after writing 5054 bytes of a 6000-byte file, the file is half-written. Next time the user tries to unlock, JSON parsing fails and they think the vault is destroyed.

2. **Power loss -> 0-byte file.** Even if the process completes, the bytes live in the kernel's page cache. The OS will write them to disk *eventually*, but a power loss between write and disk-write means the file appears to exist but contains nothing.

3. **Two `pv` instances racing.** User runs `pv add github` in one terminal and `pv add email` in another simultaneously. Both unlock the vault(slow process), both add their entry, both save. Whichever saves *second* loses the other's entry(classic race condition).

### How each one is fixed

```
        ┌──────────────────────────────────────────────┐
        │ 1. acquire advisory flock on vault.json.lock │
        │    (POSIX systems — Windows skips this)      │
        └──────────────────┬───────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────────┐
        │ 2. os.open(vault.json.tmp, ..., mode=0600)   │
        |    file created world-unreadable from the    |
        |    very first syscall (no chmod race)        |
        └──────────────────┬───────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────────┐
        │ 3. os.write(fd, envelope_bytes)              |
        └──────────────────┬───────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────────┐
        │ 4. os.fsync(fd)                              |
        |    forces the kernel page cache -> disk.     |
        └──────────────────┬───────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────────┐
        │ 5. os.close(fd)                              |
        └──────────────────┬───────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────────┐
        │ 6. os.replace(vault.json.tmp, vault.json)    |
        |               atomic rename                  |
        └──────────────────┬───────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────────┐
        │ 7. fsync the parent directory (POSIX)        |
        |    so the rename itself survives power loss. |
        |    without this, an OS crash right after the |
        |    rename can revert the directory entry     |
        └──────────────────┬───────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────────┐
        │ 8. release advisory flock                    |
        └──────────────────────────────────────────────┘
```

Each step plugs one hole:

| Step | Plugs                                          |
| ---- | ---------------------------------------------- |
| 1, 8 | Two  `pv` processes racing                     |
| 2    | Brief window where tmp file is world-readable  |
| 4    | "Power loss right after write" loses data      |
| 6    | "Crash mid-write" corrupts the live file       |
| 7    | "Power loss right after rename" reverts        |

---

## 9. Lifecycle of an `UnlockedVault`

This object holds:

- The path to the vault file on disk
- The 16-byte salt
- The Argon2 parameters that were used
- The 32-byte AES key (sensitive)
- The decrypted entries (They contain plaintext passwords!)

Holding the key in memory means subsequent operations (add, get, delete, save) don't have to re-drive it. But it also means we want a clear "I'm done with this" signal. We can achieve this using Python's `with` statement(a context manager):

```python
with UnlockedVault.unlock(path, master) as vault:
    vault.add_entry("github", entry)
    vault.save()
# at this point, vault.__exit__ has been called
# vault.entries is now {}
# vault.key is now b"\x00" * 32
```

**Note:** True wipe-on-free in Python requires `bytearray` plus `ctypes` tricks.

```
       ┌────────────────────────────────────────────┐
       │  UnlockedVault.unlock(path, master)        │
       │  ─ slow: Argon2id derives 32-byte key      │
       │  ─ AES-GCM decrypts ciphertext             │
       │  ─ returns instance: { path, salt, params, │
       │                       key, entries }       │
       └────────────────────────────────────────────┘
                              │
                              ▼
       ┌────────────────────────────────────────────┐
       │  __enter__ → returns self                  │
       └────────────────────────────────────────────┘
                              │
                              ▼
       ┌────────────────────────────────────────────┐
       │  body of `with` block                      │
       │  ─ get_entry, add_entry, delete_entry      │
       │  ─ save() (fast: key already in memory,    │
       │            just AES-GCM + atomic write)    │
       └────────────────────────────────────────────┘
                              │
                              ▼
       ┌────────────────────────────────────────────┐
       │  __exit__ → close()                        │
       │  ─ self.entries = {}                       │
       │  ─ self.key = b"\x00" * 32                 │
       │  (best-effort wipe; Python bytes are       │
       │   immutable, GC may still hold copies)     │
       └────────────────────────────────────────────┘
```
