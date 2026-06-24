"""
@patcho | 2026
__init__.py

This file contains re-exports and package metadatat. It also defines
`__all__`: the explicit list of what `from password_manager import *`
is allowed to bring in

Connects to
    crypto.py - re-exports CryptoError, KdfParameters, WrongPasswordError
    vault.py
"""
__version__ = "1.0.0"
