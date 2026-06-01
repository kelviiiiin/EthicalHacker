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
