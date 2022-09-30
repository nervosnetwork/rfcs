### Appending the Field At the End

The block header size is at least 208 bytes. The first 208 bytes are encoded the same as the current header. The remaining bytes are the variable length field.

```
+-----------------------+-----------+
|                       |           |
|    208-bytes header   | New Field |
|                       |           |
+-----------------------+-----------+
```


Pros

- Apps that are not interested in the new field can just read the first 208 bytes.

Cons

- It's not a valid Molecule buffer.
- It may break the old contract which assumes that the header has only 208 bytes.
- Nodes that do not need the new field still has to download it.
- Header is a variable length structure now.