# QRVault

This is a cold storage password manager. Print out your most sensitive credentials as an encrypted QR code to make them unhackable and safe from prying eyes.

## QR code protocol
The QR code itself stores an URI that looks like this:
```
qrv://[title]/[salt]/[iv]/[encrypted content]?h=[hint]&v=1
```
Here is a breakdown of each component:
- `title`: Your choosen title that is also visible on the printed paper.
- `salt`: Random value used to better hash your master password.
- `iv`: Random value used to better encrypt the content.
- `encrypted content`: This includes all your information like: password, username, email, TOTP, etc.
- `h`: Is your optionally set **hint**.
- `v`: Protocol version that this QR code was created with. Used for potential future changes.

### What is in the encrypted content
Once the encrypted content has been unsealed, you'll see binary data. That's [MessagePack](https://msgpack.org/)! It's similar to JSON, but in binary format. This enables us to store properly serialised data safely and efficiently in binary. If you break it down to a readable format, you'll get:
```json5
{
    "u": "Your Username",
    "p": "Secret password",
    "w": "https://example.com/login",
    "t": "TOTP secret",
    "n": "Your notes"
}
```
This would like this in Hex:
```
85 a1 75 ad 59 6f 75 72 20 55 73 65 72 6e 61 6d 65 a1 70 af 53 65 63 72 65 74 20 70 61 73 73 77 6f 72 64 a1 77 b9 68 74 74 70 73 3a 2f 2f 65 78 61 6d 70 6c 65 2e 63 6f 6d 2f 6c 6f 67 69 6e a1 74 ab 54 4f 54 50 20 73 65 63 72 65 74 a1 6e aa 59 6f 75 72 20 6e 6f 74 65 73
```