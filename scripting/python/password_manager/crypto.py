"""
@patcho | 2026
crypto.py

All the cryptography for the password manager lives in this one file

This file houses the Key Derivation and Authenticated Encryption which,
together, protect the user's vault

------------------------------------------------------------------------
What this file exposes
------------------------------------------------------------------------
    derive_key(...)     - Argon2id: master password + salt -> 32-byte key
    generate_salt()     - fresh random salt for a new vault
    generate_nonce()    - fresh random nonce for every encryption
    encrypt(plaintext, key)     - AES-256-GCM scramble
    decrypt(ciphertext, ...)    - AES-256-GCM unscramble (raises on tampering)
    WrongPasswordError      - exception raised when decryption fails

Connects to
    vault.py - calls these functions to encrypt and decrypt vault data
    constants.py - pulls KDF and cipher params from here
"""

# Standard library for cryptographically-secure random bytes generation
import secrets
from dataclasses import dataclass # decorator

# Third-party (argon2-cffi): the password-hashing function we use as our KDF
# `Type` selects the argon2id variant; `hash_secret_raw` returns raw key bytes
# (no PHC string)
from argon2.low_level import Type, hash_secret_raw