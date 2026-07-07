"""
@patcho | 2026
main.py

CLI entry point — wires the user's keyboard to the vault.

Take the arguments the user types, prompt for the master password without echoing it,
call the right method on UnlockedVault, and print results in a friendly format. The
actual work happens in vault.py and crypto.py

--------------------------------------------------------------------------------------
Why Typer
--------------------------------------------------------------------------------------
Typer turns a regular Python function into a CLI command, just by reading its type
hints and docstrings. It also generates --help text, validates types automatically, and
plays well with rich for colorful output

--------------------------------------------------------------------------------------
Commands Exposed
--------------------------------------------------------------------------------------
    init             — create a new empty vault
    add <name>       — add an entry (prompts for fields)
    get <name>       — show an entry's details
    list             — list every entry name
    delete <name>    — remove an entry
    change-password  — rotate the master password (re-encrypts vault)
    gen              — generate a random password (no vault touched)

Connects to
    vault.py — instantiates UnlockedVault for read/write operations
    generator.py — used by `gen` and offered inside `add`
    constants.py — pulls prompt strings and default vault path
"""

import getpass # reads passwords from terminal without echoing characters typed
from pathlib import Path # object-oriented filesystem paths
# Standard Library: lets us attach extra metadata (typer Option/Argument specs) to a
# parameter's type hint without changing its type
from typing import Annotated

# Third-party (Typer): the CLI framework. Turns a regular function into a subcommand
# with parsed args, help text, and auto-completion (argparse alternative)
import typer
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from password_manager.constants import (
    DEFAULT_GENERATED_PASSWORD_LENGTH,
    DEFAULT_VAULT_PATH,
    MINIMUM_MASTER_PASSWORD_LENGTH,
    MSG_ENTRY_ADDED,
    MSG_ENTRY_ALREADY_EXISTS,
    MSG_ENTRY_DELETED,
    MSG_ENTRY_NOT_FOUND,
    MSG_MASTER_PASSWORD_CHANGED,
    MSG_MASTER_PASSWORD_EMPTY,
    MSG_MASTER_PASSWORD_TOO_SHORT,
    MSG_PASSWORDS_DO_NOT_MATCH,
    MSG_VAULT_CREATED,
    MSG_VAULT_ALREADY_EXISTS,
    MSG_VAULT_EMPTY,
    MSG_VAULT_NOT_FOUND,
    MSG_WRONG_MASTER_PASSWORD,
    PROMPT_ENTRY_NOTES,
    PROMPT_ENTRY_PASSWORD,
    PROMPT_ENTRY_URL,
    PROMPT_ENTRY_USERNAME,
    PROMPT_MASTER_PASSWORD,
    PROMPT_MASTER_PASSWORD_CONFIRM,
    PROMPT_MASTER_PASSWORD_NEW,
)
# Local: the one crypto-layer error we want to translate into a friendly "wrong master
# password" message for the user
from password_manager.crypto import WrongPasswordError
from password_manager.generator import (
    PasswordTooShortError,
    generate_password,
)
# Local: every vault-layer name we need — the Entry record, the UnlockedVault class, and
# every domain-specific error we catch
from password_manager.vault import (
    Entry,
    EntryAlreadyExistsError,
    EntryNotFoundError,
    UnlockedVault,
    VaultAlreadyExistsError,
    VaultError,
    VaultNotFoundError,
    VaultFormatError,
)

# =====================================================================================
# Typer app + consoles — module-level singleton
# =====================================================================================
# Typer.app is the registry entry every @app.command() decorator attaches to.
# rich.Console handles colorful output. We keep two consoles, one for each output stream
# — std out & std err
# 
# Splitting them lets users redirect cleanly. `pv gen 32 | pbcopy` pipes only the
# password into the clipboard, even if pv prints an error. `pv get foo 2>/dev/null`
# swallows error chatter without also swallowing the panel of creds
app = typer.Typer(
    name = "pv",
    help = "Encrypted password manager (Argon2id + AES-256-GCM)",
    no_args_is_help = True,
    add_completion = False,
)
console = Console()
error_console = Console(stderr = True)

# =====================================================================================
# Shared option type — every command takes --vault
# =====================================================================================
# We define the type alias once so every command takes the same flag

VaultPath = Annotated[
    Path,
    typer.Option(
        "--vault",
        "-v",
        help = "Path to the vault file",
        envvar = "PV_VAULT",
    ),
]

# =====================================================================================
# Helpers — keep the comamnd bodies focused on flow, not plumbing
# =====================================================================================

def _prompt_master_password(prompt: str = PROMPT_MASTER_PASSWORD) -> str:
    """
    Read a master password from the terminal without echoing it

    Wraps getpass so we can swap implementations later (e.g. read from stdin in 
    non-interactive scripts) without touching every command. getpass falls back to a
    noisy "echo enabled" warning if the terminal does not support hidden input
    """
    return getpass.getpass(prompt)

def _prompt_master_password_with_confirmation() -> str:
    """
    Prompt for a new master password twice, validate it, and return it

    Used by `init` and `change-password` to set or rotate the master password. Three
    checks happen before the password is returned

        1. Check if the pass is non-empty
        2. At least MINIMUM_MASTER_PASSWORD_LENGTH characters
        3. Confirmation match
    
    Exists with code 1 on any of the above. The caller, therefore, does not need to
    handle these cases
    """
    first = _prompt_master_password(PROMPT_MASTER_PASSWORD_NEW)
    
    if not first:
        error_console.print(f"[red]{MSG_MASTER_PASSWORD_EMPTY}[/red]")
        raise typer.Exit(Code = 1)
    
    if len(first) < MINIMUM_MASTER_PASSWORD_LENGTH:
        error_console.print(
            f"[red]"
            f"{MSG_MASTER_PASSWORD_TOO_SHORT.format(minimum =
                                                    MINIMUM_MASTER_PASSWORD_LENGTH)}"
            f"[/red]"
        )
        raise typer.Exit(code = 1)
    
    second = _prompt_master_password(PROMPT_MASTER_PASSWORD_CONFIRM)
    if first != second:
        error_console.print(f"[red]{MSG_PASSWORDS_DO_NOT_MATCH}[/red]")
        raise typer.Exit(code = 1)
    
    return first

def _unlock_or_exit(path: Path, master_password: str) -> UnlockedVault:
    """
    Open a vault, exiting cleanly on every kind of failure

    Each error gets the right message and the right exit code. Errors go through
    error_console (stderr); informational and success messages go through console
    (stdout). That split is what makes the CLI pipe-friendly
    """
    try:
        return UnlockedVault.unlock(path, master_password)
    except VaultNotFoundError:
        error_console.print(
            f"[red]{MSG_VAULT_NOT_FOUND.format(path=path)}[/red]"
        )
        raise typer.Exit(code = 1) from None
    except WrongPasswordError:
        error_console.print(
            f"[red]{MSG_WRONG_MASTER_PASSWORD}[/red]"
        )
        raise typer.Exit(code = 1) from None
    except VaultFormatError as exc:
        error_console.print(
            f"[red]Vault file is invalid: {exc}[/red]"
        )
        raise typer.Exit(code = 1) from None
    except VaultError as exc:
        error_console.print(
            f"[red]Vault error: {exc}[/red]"
        )
        raise typer.Exit(code = 1) from None
    
def _render_entry(name: str, entry: Entry) -> Panel:
    """
    Format an entry as a rich Panel for terminal display

    The password is shown verbatim — this is a CLI too, the user already trusts the
    screen
    """
    body_lines = [
        f"[bold]username[/bold]     {entry.username}",
        f"[bold]password[/bold]     {entry.password}",
    ]
    if entry.url:
        body_lines.append(f"[bold]url[/bold]    {entry.url}")
    if entry.notes:
        body_lines.append(f"[bold]notes[/bold]    {entry.notes}")
    body_lines.append(f"[dim]created    {entry.created_at}[/dim]")
    body_lines.append(f"[dim]updated    {entry.updated_at}[/dim]")
    return Panel(
        "\n".join(body_lines),
        title = name,
        border_style = "cyan",
    )

# =====================================================================================
# Commands
# =====================================================================================
# Each @app.command decorates a function as a CLI command. The function name becomes
# the command name

@app.command()
def init(vault: VaultPath = DEFAULT_VAULT_PATH) -> None:
    """
    Create a new empty vault at --vault (or PV_VAULT or default path)
    """
    if vault.exists():
        error_console.print(
            f"[red]{MSG_VAULT_ALREADY_EXISTS.format(path = vault)}[/red]"
        )
        raise typer.Exit(code = 1)
    
    master = _prompt_master_password_with_confirmation()
    try:
        # The create() call writes the empty vault and returns an UnlockedVault. We have
        # nothing else to do with it, so we use `with` purely to drop the AES key right
        # away
        with UnlockedVault.create(vault, master):
            pass

    except VaultAlreadyExistsError:
        error_console.print(
            f"[red]{MSG_VAULT_ALREADY_EXISTS.format(path=vault)}[/red]"
        )
        raise typer.Exit(code = 1) from None
    
    console.print(f"[green]{MSG_VAULT_CREATED.format(path=vault)}[green]")

@app.command(name = "list")
def list_entries(vault: VaultPath = DEFAULT_VAULT_PATH) -> None:
    """
    Print every entry name in the vault, one per line
    """
    master = _prompt_master_password()
    # `with` ensures the AES key and plaintext entries are dropped as soon as the table
    # has been printed. We render inside the block because we still need to read the
    # entries
    with _unlock_or_exit(vault, master) as unlocked:
        names = unlocked.names()
        if not names:
            console.print(f"[yellow]{MSG_VAULT_EMPTY}[/yellow]")
            return
        
        table = Table(title = f"Entries in {vault}", show_lines = False)
        table.add_column("name", style = "cyan", no_wrap = True)
        table.add_column("username", style = "white")
        table.add_column("updated", style = "dim")
        for name in names:
            entry = unlocked.entries[name]
            table.add_row(name, entry.username, entry.updated_at)
        console.print(table)

@app.command()
def get(
    name: Annotated[str,
                    typer.Argument(help = "Entry name to retrieve")],
    vault: VaultPath = DEFAULT_VAULT_PATH,
) -> None:
    """
    Show every field of one entry by name
    """
    master = _prompt_master_password()
    with _unlock_or_exit(vault, master) as unlocked:
        try:
            entry = unlocked.get_entry(name)
        except EntryNotFoundError:
            error_console.print(
                f"[red]{MSG_ENTRY_NOT_FOUND.format(name=name)}[/red]"
            )
            raise typer.Exit(code = 1) from None
        console.print(_render_entry(name, entry))

@app.command()
def add(
    name: Annotated[str,
                    typer.Argument(help = "Entry name (must be unique)")],
    vault: VaultPath = DEFAULT_VAULT_PATH,
    force: Annotated[
        bool,
        typer.Option("--force",
                     "-f",
                     help = "Overwrite if exists"),
    ] = False,
    generate: Annotated[
        bool,
        typer.Option(
            "--generate",
            "-g",
            help = "Generate a random password instead of prompting",
        ),
    ] = False,
    length: Annotated[
        int,
        typer.Option(
            "--length",
            "-n",
            help = "Length when --generate is used",
        ),
    ] = DEFAULT_GENERATED_PASSWORD_LENGTH,
) -> None:
    """
    Add (or overwrite with --force) an entry in the vault
    """
    master = _prompt_master_password()
    with _unlock_or_exit(vault, master) as unlocked:
        username = input(PROMPT_ENTRY_USERNAME.format(entry = name))

        if generate:
            try:
                password = generate_password(length)
            except PasswordTooShortError as exc:
                error_console.print(f"[red]{exc}[/red]")
                raise typer.Exit(code = 1) from None
            console.print(f"[green]Generated password:[/green]")
        else:
            password = _prompt_master_password(
                f"Password for {name} (hidden): "
            )

        url = input(PROMPT_ENTRY_URL).strip()
        notes = input(PROMPT_ENTRY_NOTES).strip()

        entry = Entry(
            username = username,
            password = password,
            url = url,
            notes = notes,
        )

        try:
            unlocked.add_entry(name, entry, force = force)
        except EntryAlreadyExistsError:
            error_console.print(
                f"[red]{MSG_ENTRY_ALREADY_EXISTS.format(name=name)}[/red]"
            )
            raise typer.Exit(code = 1) from None
        except ValueError as exc:
            # Empty / whitespace entry name caught by add_entry's validation
            error_console.print(f"[red]{exc}[/red]")
            raise typer.Exit(code = 1) from None
        
        unlocked.save()
    console.print(f"[green]{MSG_ENTRY_ADDED.format(name=name)}[/green]")

@app.command()
def delete(
    name: Annotated[str,
                    typer.Argument(help = "Entry name to delete")],
    vault: VaultPath = DEFAULT_VAULT_PATH,
) -> None:
    """
    Remove an entry name
    """
    master = _prompt_master_password()
    with _unlock_or_exit(vault, master) as unlocked:
        try:
            unlocked.delete_entry(name)
        except EntryNotFoundError:
            error_console.print(
                f"[red]{MSG_ENTRY_NOT_FOUND.format(name=name)}[/red]"
            )
            raise typer.Exit(code = 1) from None
        
        unlocked.save()
    console.print(f"[green]{MSG_ENTRY_DELETED.format(name=name)}[/green]")

@app.command()
def gen(
    length: Annotated[
        int,
        typer.Argument(help = "Password length"),
    ] = DEFAULT_GENERATED_PASSWORD_LENGTH,
    no_symbols: Annotated[
        bool,
        typer.Option("--no-symbols",
                     help = "Letters and digits only"),
    ] = False,
    no_digits: Annotated[
        bool,
        typer.Option("--no-digits",
                     help = "Letters and symbols only"),
    ] = False,
    no_uppercase: Annotated[
        bool,
        typer.Option("--no-uppercase",
                     help = "No uppercase letters"),
    ] = False,
) -> None:
    """
    Print a fresh random password and exit (no vault required)
    """
    try:
        password = generate_password(
            length,
            use_lowercase = True,
            use_uppercase = not no_uppercase,
            use_digits = not no_digits,
            use_symbols = not no_symbols,
        )
    except (PasswordTooShortError, ValueError) as exc:
        error_console.print(f"[red]{exc}[/red]")
        raise typer.Exit(code = 1) from None
    
    # Plain print() so the output is pipe-friendly
    print(password)

@app.command(name = "change-password")
def change_password(vault: VaultPath = DEFAULT_VAULT_PATH) -> None:
    """
    Change the master password (re-encrypts the vault end-to-end)

    We unlock with the OLD password, derive a fresh salt + key from the NEW password,
    and save — which re-encrypts every entry under the new key
    """
    current = _prompt_master_password("Current master password: ")
    with _unlock_or_exit(vault, current) as unlocked:
        new_password = _prompt_master_password_with_confirmation()
        unlocked.change_master_password(new_password)
        unlocked.save()
    console.print(
        f"[green]"
        f"{MSG_MASTER_PASSWORD_CHANGED.format(path=vault)}"
        f"[/green]"
    )