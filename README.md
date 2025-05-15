# QRVault

This is a cold storage password manager. Print out your most sensitive credentials as an encrypted QR code to make them unhackable and safe from prying eyes.

## QR code protocol
The QR code itself stores an URI that looks like this:
```
qrv://[title]/[salt]/[iv]/[encrypted content]?h=[hint]&v=1
```
Here is a breakdown of each component:
- `title`: Your choosen title that is also visible on the printed paper.
- `salt`: Random value used to securely hash your master password.
- `iv`: Random value used to securely encrypt the content.
- `encrypted content`: This includes all your information like: password, username, email, TOTP, etc. formatted with Base64
- `h`: Is your optionally set **hint**.
- `v`: Protocol version that this QR code was created with. Used for potential future changes.

### Content
Once the encrypted content has been unsealed, you'll see binary data. That's [MessagePack](https://msgpack.org/)! It's similar to JSON, but in binary format. This enables us to store properly serialised data safely and efficiently in binary. This is what we store on the QR-Code represented in JSON:
```json5
{
    "u": "Your Username",
    "p": "Secret password",
    "w": "https://example.com/login",
    "t": "TOTP secret",
    "n": "Your notes"
}
```
This JSON file is **142 bytes** in size. A staggering figure! We can compress this down using said MessagePack into a binary format:
```
00000000  85 a1 75 ad 59 6f 75 72  20 55 73 65 72 6e 61 6d  |..u.Your Usernam|
00000010  65 a1 70 af 53 65 63 72  65 74 20 70 61 73 73 77  |e.p.Secret passw|
00000020  6f 72 64 a1 77 b9 68 74  74 70 73 3a 2f 2f 65 78  |ord.w.https://ex|
00000030  61 6d 70 6c 65 2e 63 6f  6d 2f 6c 6f 67 69 6e a1  |ample.com/login.|
00000040  74 ab 54 4f 54 50 20 73  65 63 72 65 74 a1 6e aa  |t.TOTP secret.n.|
00000050  59 6f 75 72 20 6e 6f 74  65 73                    |Your notes|
```
These are only **90 bytes** which saved us 36,6% in size! This is the content we will encrypt in [the next chapter](#content-cryptography).

### Content cryptography
There are two main steps involved:
1. **Hashing** of the user's entered master password with **Argon2id** to generate a 32-byte value.
2. **Encrypt** the content using this 32-byte value with **AES-256 CTR**.

> [!NOTE]
> AES in CTR mode **does not** provide integrity or authenticity checks, only **confidentiality**. However, it adds no overhead to the QR-Code compared to other modes, except for the IV. We do not consider manipulated QR-Code as a serious threat and therefore don't use [AEAD](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Authenticated_encryption_with_additional_data_(AEAD)_modes) modes.

Let's visualize this using an example. This is basically exactly what QRVault does.

| Input | Value |
| ----- | ----- |
| User Password | `my_1nsecurePassw0rd` |
| Content | [See MessagePack](#what-is-in-the-encrypted-content) |
| Salt (generated) | `CBvacpfRWolfrypv` |
| IV (generated) | `BlFKqLrQIMih0InU` |

These are our input values. The **user password** is either entered manually or retrieved from the phones secure element. **Salt** and **IV** are generated on QR-Code generation and later stored on it.

#### Hash
Argon2 is a key derivation function. It's basically a hashing algorithm which is designed to be painfully slow, both on CPU and GPU. Because of this, we can dramatically increase our protection against brute-force attacks. It comes in two modes: `Argon2i`, which protects against side-channel attacks, and `Argon2d`, which protects against GPU attacks. `Argon2id` is a mode which combines both which is [generally a good idea](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id) and why we use it.

To control our resistance, we can configure Argon2id with several parameters. For example, you can specify how many threads and memory to use, how long the output hash must be, and how many iterations to run. Each of these values can increase the overall hardware resources if increased. If these are set correctly, we can stretch the **hashing time to 1-2 seconds** for each attempt!

> [!WARNING]
> This is not a production hash. Firstly, our format will likely change during development. Secondly, this example uses weak Argon2 settings.

These parameters used for Argon2id are version dependent (as defined by the `v=1` parameter inside the URI above). For this demo we use:
- Parallelism Factor: 1 (basically how many threads must be used)
- Memory Cost: 16 Bytes
- Iterations: 2
- Hash Length: 32

Running `Argon2id(User Password, Salt, [...options])` (pseudo-code) produces the following hash:
```python
# Hex
eba916c609d282ec7c9d558e9510a938c2bca956e315cc2ee77b0b92105472e7

# Encoded
$argon2id$v=19$m=16,t=2,p=1$Q0J2YWNwZlJXb2xmcnlwdg$66kWxgnSgux8nVWOlRCpOMK8qVbjFcwu53sLkhBUcuc
```
This hash **will never be stored** on the QR-Code, as this is our en-/decryption key.

#### Encryption
Now we have everything it needs to use AES-256 in [CTR mode](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Counter_(CTR)). AES is the golden standard in modern cryptography which is why we chose it.

What is required for AES-256 CTR and what we have:
- 16 byte initialization vector (IV) which we randomly generated (in hex):
```python
42 6c 46 4b 71 4c 72 51 49 4d 69 68 30 49 6e 55
```
- 32 byte secret value which is our calculated hash (in hex):
```python
eb a9 16 c6 09 d2 82 ec 7c 9d 55 8e 95 10 a9 38
c2 bc a9 56 e3 15 cc 2e e7 7b 0b 92 10 54 72 e7
```
- Our content we want to protect: [See MessagePack](#what-is-in-the-encrypted-content)

Feeding this into AES-256 CTR gives us this 90-byte ciphertext:
```hex
00000000  ae 3d 30 81 24 47 16 77  a8 47 e7 da fc c1 ae d4  |.=0.$G.w.G......|
00000010  cb d3 51 90 23 da da 89  98 94 e1 6a 30 46 fa e1  |..Q.#......j0F..|
00000020  bf f0 f0 da 8c b3 3c 24  fa 0c b6 42 3d 5c d5 30  |......<$...B=\.0|
00000030  3f 7f b2 57 be 2e 2d 51  1a d9 e2 7e 0c 31 34 3c  |?..W..-Q...~.14<|
00000040  64 63 84 31 21 76 74 57  3b 3d 8c f4 c8 68 d1 98  |dc.1!vtW;=...h..|
00000050  ba 86 36 8b 53 d1 ab 72  c3 60                    |..6.S..r.`|
```

This only needs to be converted into Base64 to make it storable on the QR-Code:
```
rj0wgSRHFneoR+fa/MGu1MvTUZAj2tqJmJThajBG+uG/8PDajLM8JPoMtkI9XNUwP3+yV74uLVEa2eJ+DDE0PGRjhDEhdnRXOz2M9Mho0Zi6hjaLU9GrcsNg
````
This however contains some characters that need to be **escaped** for an URI. The **final** content looks like this:
```
rj0wgSRHFneoR%2Bfa%2FMGu1MvTUZAj2tqJmJThajBG%2BuG%2F8PDajLM8JPoMtkI9XNUwP3%2ByV74uLVEa2eJ%2BDDE0PGRjhDEhdnRXOz2M9Mho0Zi6hjaLU9GrcsNg
```

#### Final URI
Based on this data, we can manually assemble our URI which is exactly what will be the QR-Code:
```url
qrv://Example%20encryption/CBvacpfRWolfrypv/BlFKqLrQIMih0InU/rj0wgSRHFneoR%2Bfa%2FMGu1MvTUZAj2tqJmJThajBG%2BuG%2F8PDajLM8JPoMtkI9XNUwP3%2ByV74uLVEa2eJ%2BDDE0PGRjhDEhdnRXOz2M9Mho0Zi6hjaLU9GrcsNg?h=The%20password%20is%20insecure&v=1
```

#### Decryption
Decryption is much simpler. This step won't visualize the same steps above as this would be redundant. These are our steps:
1. Take the user password and salt to generate the same hash.
2. Feed this hash and IV into AES-256 CTR in decryption mode.

After calling the AES-256 CTR decryption mode with all these parameters, we should get back the same MessagePack content as shown [here](#what-is-in-the-encrypted-content).