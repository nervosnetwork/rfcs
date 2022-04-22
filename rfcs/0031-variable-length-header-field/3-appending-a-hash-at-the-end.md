### Appending a Hash at the End

Instead of adding the new field directly at the end of the header, this solution adds a 32-byte hash to the end of the header which is the hash of the new variable length field. The header is still a fixed length structure, but it is 32 bytes larger. If the client does not need the extra field, it only has 32 bytes overhead. Otherwise, it must download both the header and extra field and verify that the hash matches.

```
+-----------------------+--+
|                       |  |
|    208-bytes header   | +----+
|                       |  |   |
+-----------------------+--+   |
                               | Hash of
                               |
                               v
                         +-----+-----+
                         |           |
                         | New Field |
                         |           |
                         +-----------+

```

Pros

- It is a valid Molecule buffer.
- The header still has the fixed length.
- Nodes that do not want the new field only need to download an extra hash to verify the PoW.

Cons

- It may break the old contract which assumes that the header has only 208 bytes.
- Extra P2P messages must be added to download the new extension field.
