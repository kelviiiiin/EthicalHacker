## Hash Identifier
- Re-enforce cryptography whilst also working on your python :)

### What the tool will do
- Identify ~30 hash formats by prefix
- Identify common hex hashes by length
- Recognize MySQL5, NetNTLM, DES crypt by shape
- Tell you "that's a JWT" or "that's base64, not a hash"
- Print ranked candidates with confidence and reasoning
- Run as a one-shot CLI in milliseconds

### What it will not do
- Crack any hash
- Compute hashes for you
- Call hashcat or john for you
- Tell you the password
- Make network requests
- Touch the file system

#### Architecture
┌─────────────────────────────────────────────────────────────┐
│  CLI layer  (main, _build_argument_parser, _render_table)   │
│  - reads command-line arguments                             │
│  - prints the colored table to your terminal                │
│  - returns an exit code                                     │
└──────────────────────────┬──────────────────────────────────┘
                           │ calls
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Pure-function layer  (identify)                            │
│  - the actual decision-making                               │
│  - takes a string, returns a list of HashCandidate          │
│  - touches NO files, NO network, NO global state            │
└──────────────────────────┬──────────────────────────────────┘
                           │ uses
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  Data layer  (PREFIX_RULES, HEX_LENGTH_RULES, charsets)     │
│  - lookup tables describing what we know about hashes       │
│  - read-only, defined at module load time                   │
└─────────────────────────────────────────────────────────────┘
