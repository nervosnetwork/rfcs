### Reusing `uncles_hash` in the Header

- Rename `uncles_hash` to `extra_hash`.
- If the new field is absent in a block, `extra_hash` is the same with `uncles_hash`. No it is compatible with existing blocks.
- If the new field is present, `extra_hash` will be the hash of the concatenation of `uncles_root` and the hash of new extension field.
- Full nodes will use a new P2P request `GetExtra` to get uncles and the extra field.
- Nodes that only need the uncles can use the modified P2P request `GetUncles`, and the response contains the uncles and the hash of the extra field. The node still can verify the uncles are indeed in the block.
- Nodes that only need the new field can use the new P2P request `GetHeaderExtension`, which will return the new field and the the current `uncles_hash`.
- Nodes that only need to know the number of uncles can use the new P2P request `GetUncleHashes`, which will return uncle hashes and the new field hash.

![](https://lucid.app/publicSegments/view/4f84c15c-231d-4ac5-9f45-92ead00b291b/image.png)

<!-- Created in Lucid: https://lucid.app/documents/view/f9b1661e-8075-402b-832c-745712c4be23 -->

Pros

- It is a valid Molecule buffer.
- The header still has the fixed length.
- Nodes that do not want the new field only need to download an extra hash when getting uncles.

Cons

- It may break the old contract which uses the `uncles_hash`. However, contract cannot read uncles via syscall, it seems unlikely any existing contracts will use this field.
- Extra P2P messages must be added.