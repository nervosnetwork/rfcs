### Appending the Field at the End

The block header size is at least 208 bytes. The first 208 bytes are encoded the same way as the current header. The remaining bytes are the variable length field.

```
+-----------------------+-----------+
|                       |           |
|    208-bytes header   | New Field |
|                       |           |
+-----------------------+-----------+
```


Pros

- Applications that are not interested in the new field can just read the first 208 bytes.

Cons

- It is not a valid Molecule buffer.
- It may break the old contract which assumes that the header has only 208 bytes.
- Nodes that do not need the new field still have to download it.
- The header is a variable length structure now.