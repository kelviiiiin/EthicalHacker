"""
@patcho | 2026
generator.py

Cryptographically secure random password generation

We use `secrets` and not `random` since, if we were to use random.choice to pick
characters, then an attacker who saw one password could deduce the internal state
of the random generator and predict every other password it produced. The `secrets`
module pulls bytes from the operating system's cryptographic source, which is
unpredictable by design

------------------------------------------------------------------------------------
What this module exposes
------------------------------------------------------------------------------------
    generate_password(length, ...) — return a random password string
    PasswordTooShortError          — raised when length is below the floor

Connects to
    main.py — the `pv gen` command and the `pv add` command call this
    constants.py — pulls character pools and default lengths from here
"""

import secrets
from password_manager.constants import (
    DEFAULT_GENERATED_PASSWORD_LENGTH,
    DIGITS,
    LOWERCASE_LETTERS,
    UPPERCASE_LETTERS,
    MINIMUM_GENERATED_PASSWORD_LENGTH,
    SAFE_SYMBOLS,
)

class PasswordTooShortError(ValueError):
    """
    Raised when the length of the password is below the safe minimum
    """

def generate_password(
        length: int,
        *,
        use_uppercase: bool = True,
        use_lowercase: bool = True,
        use_digits: bool = True,
        use_symbols: bool = True        
) -> str:
    """
    Return a random password of the given length

    Parameters
    ----------
    length
        How many characters in the result. Must be at least
        MINIMUM_GENERATED_PASSWORD_LENGTH. Must also be at least as large as the
        number of enabled pools
    use_lowercase, use_uppercase, use_digits, use_symbols
        Which character pools to draw from. At least one must be True

    Returns
    -------
    str
        A random password of exactly `length` characters
    
    Raises
    ------
    PasswordTooShortError
        If `length` is below the floor or below the number of pools
    ValueError
        If every pool flag is False
    """
    if length < MINIMUM_GENERATED_PASSWORD_LENGTH:
        raise PasswordTooShortError(
            f"Password length must be >="
            f"{MINIMUM_GENERATED_PASSWORD_LENGTH}, got {length}"
        )
    
    # The lookup table of enabled pools so we can pick one char from each
    enabled_pools = {
        "lower": LOWERCASE_LETTERS if use_lowercase else "",
        "upper": UPPERCASE_LETTERS if use_uppercase else "",
        "digit": DIGITS if use_digits else "",
        "symbol": SAFE_SYMBOLS if use_symbols else "",
    }
    enabled_pools = {k: v for k,v in enabled_pools.items() if v}

    if not enabled_pools:
        raise ValueError("At least one character pool must be enabled")
    
    if length < len(enabled_pools):
        raise PasswordTooShortError(
            f"length={length} is too small to include one character "
            f"from each of {len(enabled_pools)} enabled pools"
        )
    
    alphabet = "".join(enabled_pools.values())

    # Take one character from each enabled pool
    required = [secrets.choice(pool) for pool in enabled_pools.values()]

    # Fill the rest from the combined alphabet
    fill_count = length - len(required)
    fill = [secrets.choice(alphabet) for _ in range(fill_count)]

    # Combine and shuffle
    chars = required + fill
    _secure_shuffle(chars)

    return "".join(chars)

def _secure_shuffle(items: list[str]) -> None:
    """
    Shuffle a list in place using a cryptographically secure source

    random.shuffle uses the predictable Mersenne Twister. We implement Fisher-Yates on
    top of secrets.randbelow so the order is unpredictable

    Mutates `items` in place — returns None
    """
    # Fisher-Yates implementation
    for i in range(len(items) - 1, 0, -1):
        j = secrets.randbelow(i + 1)
        items[i], items[j] = items[j], items[i]