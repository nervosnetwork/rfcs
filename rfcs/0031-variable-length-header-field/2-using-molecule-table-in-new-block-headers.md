### Using a Molecule Table in New Block Headers

This solution uses a different molecule schema for the new block headers. If the block header size is 208 bytes, the block header is encoded using the old schema, otherwise it is encoded using the new schema. The new schema converts `RawHeader` into a molecule table and adds a variable length bytes field at the end of `RawHeader`.

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

- This may break the old contract that assumes the header consists of only 208 bytes and is just the concatenation of all members.
- Nodes that do not need the new field must still download it.
- The molecule table header imposes overhead on nodes.
- The header is now a variable length structure.

