"""
@patcho | 2026
__init__.py

This file contains re-exports and package metadata. It also defines
`__all__`: the explicit list of what `from password_manager import *`
is allowed to bring in

Connects to
    crypto.py — re-exports CryptoError, KdfParameters, WrongPasswordError
    vault.py — re-exports UnlockedVault, Entry, and every vault error
"""

# Local: re-export the crypto-layer pieces callers actually need
from password_manager.crypto import (
    CryptoError,
    KdfParameters,
    WrongPasswordError,
)
# Local: re-export the vault-layer pieces
from password_manager.vault import (
    Entry,
    EntryAlreadyExistsError,
    EntryNotFoundError,
    VaultAlreadyExistsError,
    VaultError,
    VaultFormatError,
    VaultNotFoundError,
)

__version__ = "1.0.0"

__all__ = [
    "CryptoError",
    "Entry",
    "EntryAlreadyExistError",
    "EntryNotFoundError",
    "KdfParameters",
    "UnlockedVault",
    "VaultAlreadyExistsError",
    "VaultError",
    "VaultFormatError",
    "VaultNotFoundError",
    "WrongPasswordError",
]
