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
# The exception raised on an invalid auth tag
from cryptography.exceptions import InvalidTag
# The authenticated symmentric encryption
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# Local: pull every magic number from the constants module
from password_manager.constants import (
    ARGON2_MEMORY_KIB,
    ARGON2_PARALLELISM,
    ARGON2_TIME_COST,
    KEY_LENGTH_BYTES,
    NONCE_LENGTH_BYTES,
    SALT_LENGTH_BYTES,
)

# =================================================================================
# Custom exceptions
# =================================================================================
# Defining our own exception classes lets callers handle them precisely, without
# catching unrelated errors

class CryptoError(Exception):
    """
    Base class for every cryptography error we raise

    Catching this catches every error from this module
    """

class WrongPasswordError(CryptoError):
    """
    Raised when decryption fails

    GCM authentication failure means one of three things and we
    cannot tell which without more context

        1. The user typed in the wrong master password
        2. The vault file was tampered with
        3. The vault file is corrupted

    From the user's perspective, all three look the same. So we
    raise a single error and let the CLI show a single, honest
    message
    """

# =================================================================================
# KDF parameters - bundled so we can pass them around as one value
# =================================================================================

@dataclass(frozen=True, slots=True)
class KdfParameters:
    """
    The Argon2id tuning knobs used to derive the key

    Fields
    ------
    time_cost
        Number of passes Argon2 makes. Higher = slower = harder to crack
    memory_cost
        Memory in KiB. Higher = harder to crack with GPUs
    parallelism
        Number of threads Argon2 may use. should match available cores
    """
    time_cost: int
    memory_cost: int
    parallelism: int

    @classmethod
    def defaults(cls) -> "KdfParameters":
        """
        Return the current recommended Argon2id parameters

        The values live in constants.py and are informed by the OWASP
        Password Storage Cheat Sheet.
        """
        return cls(
            time_cost = ARGON2_TIME_COST,
            memory_cost = ARGON2_MEMORY_KIB,
            parallelism = ARGON2_PARALLELISM,
        )
    
# =================================================================================
# Random byte generation - salts and nonces
# =================================================================================

def generate_salt() -> bytes:
    """
    Return SALT_LENGTH_BYTES of fresh, unpredictable random bytes

    Returns
    -------
    bytes
        A new random bytes string of length SALT_LENGTH_BYTES
    """
    # secret.token_bytes(n) returns n random bytes from the OS-level cryptographic
    # random pool. Same we would use to generate session tokens or API keys
    return secrets.token_bytes(SALT_LENGTH_BYTES)

def generate_nonce() -> bytes:
    """
    Return NONCE_LENGTH_BYTES of fresh, unpredictable random bytes

    GCM allows nonces up to 2^32 messages safely with random 12-byte nonces, which is
    far more vault saves than any human will ever perform

    Returns
    -------
    bytes
        A new random byte string of length NONCE_LENGTH_BYTES (12 bytes)
    """
    return secrets.token_bytes(NONCE_LENGTH_BYTES)

# =================================================================================
# Key derivation
# =================================================================================

def derive_key(
        master_password: str,
        salt: bytes,
        parameters: KdfParameters | None = None,
) -> bytes:
    """
    Turn a master password and salt into a 32-byte encryption key

    The output is suitable as input to AES-256-GCM. This is slow on purpose. It is
    the costt an attacker must pay for every guess

    Parameters
    ----------
    master_password
        What the user types at the prompt, as a normal Python string
    salt
        The vault's salt
    parameters
        Argon2id tuning. Defaults to the project's recommended values (see 
        KdfParameters.defaults). The vault file stores whatever was used so old
        vaults keep working when defaults change

    Returns
    -------
    bytes
        A 32-byte (256 bit) key

    Notes
    -----
    Encryption algorithms work with raw bytes, not strings. We encode the password
    to UTF-8 bytes here
    """
    # Refuse an empty password outright
    if not master_password:
        return ValueError("master_password must not be empty")
    
    # Default to recommended parameters if the caller did not specify
    if parameters is None:
        parameters = KdfParameters.defaults()

    # Standard string to bytes conversion
    password_bytes = master_password.encode("utf-8")

    # hash_secret_raw is the low-level Argon2 function
    return hash_secret_raw(
        secret = password_bytes,
        salt = salt,
        time_cost = parameters.time_cost,
        memory_cost = parameters.memory_cost,
        parallelism = parameters.parallelism,
        hash_len = KEY_LENGTH_BYTES,
        # Type.ID = Argon2id, the recommended variant
        type = Type.ID,
    )

# =================================================================================
# Symmetric encryption - AES-256-GCM
# =================================================================================
# We use the high-level AESGCM class from the cryptography library. It bundles
# the cipher, the authentication tag, and constant-time tag verification into a
# single API

def encrypt(plaintext: bytes, key: bytes) -> tuple[bytes, bytes]:
    """
    Encrypt plaintext bytes with AES-256-GCM and return (nonce, ciphertext)

    The "ciphertext" returned actually contains both the encrypted data and a 16-byte
    authentication tag appended to the end. The AESGCM library handles this
    concatenation automatically. The tag is what makes the encryption tamper-evident

    Parameters
    ----------
    plaintext
        Raw bytes to encrypt. Anything - JSON-encoded vault entries, plain text,
        an image. The cipher does not care

    key
        The 32-byte key from derive_key. Wrong size raises ValueError

    Returns
    -------
    tuple[bytes, bytes]
        (nonce, cipher_text_with_tag). Both must be stored to allow later decryption
    """
    # Construct a cipher object bound to our key. AESGCM validates the key size: must
    # be 16, 24, or 32 bytes (AES-128, 192, or 256)
    cipher = AESGCM(key)

    # Fresh nonce for every encryption
    nonce = generate_nonce()

    # encrypt() returns ciphertext concatenated with the auth tag
    ciphertext = cipher.encrypt(
        nonce = nonce,
        data = plaintext,
        associated_data = None,
    )

    return nonce, ciphertext

def decrypt(ciphertext: bytes, nonce: bytes, key: bytes) -> bytes:
    """
    Decrypt ciphertext produced by encrypt() and verify it was not tampered with

    Parameters
    ----------
    ciphertext
        The output from encrypt() - encrypt data + 16-byte auth tag
    nonce
        The same nonce used during encryptio
    key
        The 32-byte key derived from the master password

    Returns
    -------
    bytes
        The original plaintext bytes

    Raises
    ------
    WrongPasswordError
        If decryption fails for any reason
    """
    cipher = AESGCM(key)

    # InvalidTag is the crytography library's signal that the auth tag did not
    # match. We catch it and re-raise as our own error so callers do not need
    # to know about cryptography
    try:
        return cipher.decrypt(
            nonce = nonce,
            data = ciphertext,
            associated_data = None,
        )
    except InvalidTag as exc:
        raise WrongPasswordError(
            "Decryption failed: wrong master password or corrupted vault"
        ) from exc