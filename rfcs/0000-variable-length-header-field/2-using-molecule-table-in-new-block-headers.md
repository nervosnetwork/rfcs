### Using Molecule Table in New Block Headers

This solution uses a different molecule schema for the new block headers. If the block header size is 208 bytes, it's encoded using the old schema, otherwise it uses the new one. The new schema converts `RawHeader` into a molecule table and adds a variable length bytes field at the end of `RawHeader`.

```
old one:
        208 bytes
+-----+-----------------+
|     |                 |
|Nonce| RawHeader Stuct |
|     |                 |
+-----+-----------------+

new one:

+-----+-------------------------------+
|     |                               |
|Nonce| RawHeader Table               |
|     |                               |
+-----+-------------------------------+
```

Pros

- It is a valid Molecule buffer.

Cons

- It may break the old contract which assumes that the header has only 208 bytes and is just the concatenation of all members.
- Nodes that do not need the new field still has to download it.
- The molecule table header overhead.
- Header is a variable length structure now.