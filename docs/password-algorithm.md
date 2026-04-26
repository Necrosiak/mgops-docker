# MGO1 Password Algorithm

## Overview

MGO1 uses a custom password hashing scheme. Understanding it is critical for
account management (registration, login, password change).

## Algorithm

```
hash = MD5(username + FIXED_SALT + password_plaintext)
```

- **Encoding:** all strings encoded as **latin-1** (ISO-8859-1), NOT UTF-8
- **Salt:** fixed 16-byte sequence (hardcoded in the PS2 client — never changes)
- **Output:** 32-char hex MD5 digest (lowercase)

## Fixed Salt (bytes)

```
\x84\xbd\xb8\xcf\xad\x46\xdd\x6e\x42\x4a\xe4\xd8\xd2\x6a\x12\xf3
```

As a hex string: `84bdb8cfad46dd6e424ae4d8d26a12f3`

## PS2 Login Flow

```
PS2 → Server : 0x3001  (request salt)
Server → PS2 : 0x3002  (send fixed salt)
PS2 → Server : 0x3003  (send MD5 hash)
```

The PS2 computes the hash locally and sends only the hash — the plaintext
password never travels over the network.

## Python Reference Implementation

```python
import hashlib

FIXED_SALT = b'\x84\xbd\xb8\xcf\xad\x46\xdd\x6e\x42\x4a\xe4\xd8\xd2\x6a\x12\xf3'

def compute_hash(username: str, password: str) -> str:
    data = username.encode('latin-1') + FIXED_SALT + password.encode('latin-1')
    return hashlib.md5(data).hexdigest()

# Example usage:
# compute_hash("testuser", "mypassword")
```

## Java Reference Implementation

```java
import java.security.MessageDigest;
import java.nio.charset.Charset;

public class Mgo1Password {
    private static final byte[] FIXED_SALT = {
        (byte)0x84, (byte)0xbd, (byte)0xb8, (byte)0xcf,
        (byte)0xad, (byte)0x46, (byte)0xdd, (byte)0x6e,
        (byte)0x42, (byte)0x4a, (byte)0xe4, (byte)0xd8,
        (byte)0xd2, (byte)0x6a, (byte)0x12, (byte)0xf3
    };

    public static String hash(String username, String password) throws Exception {
        Charset latin1 = Charset.forName("ISO-8859-1");
        byte[] u = username.getBytes(latin1);
        byte[] p = password.getBytes(latin1);
        byte[] data = new byte[u.length + FIXED_SALT.length + p.length];
        System.arraycopy(u, 0, data, 0, u.length);
        System.arraycopy(FIXED_SALT, 0, data, u.length, FIXED_SALT.length);
        System.arraycopy(p, 0, data, u.length + FIXED_SALT.length, p.length);
        MessageDigest md = MessageDigest.getInstance("MD5");
        byte[] digest = md.digest(data);
        StringBuilder sb = new StringBuilder();
        for (byte b : digest) sb.append(String.format("%02x", b & 0xff));
        return sb.toString();
    }
}
```

## Important Notes

- The salt is **not a secret** — it is embedded in every PS2 disc and RPCS3
  emulator image. It cannot be changed without modifying the client.
- The PHP gateway handlers receive the **already-hashed** password from the PS2
  and store it directly — no re-hashing on the server side.
- Account names are **case-sensitive** in the hash computation.
