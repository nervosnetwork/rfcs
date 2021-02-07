---
Number: "0031"
Category: Consensus (Hard Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-02-07
---

# Add a variable length field in the block

## Abstract

This document proposes adding an optional variable length field to the block.

## Motivation

Currently, the block header is a fixed length structure. Each header consists of 208 bytes.

Many extensions require adding new fields into the block. For example, PoA for testnet requires 65 bytes for each signature, and flyclient also needs to add a 64 bytes hash.

There's no enough reserved bits in the header for these extensions. There's a workaround to store these data in the cellbase transaction, but this solution has a big overhead for clients which want to quickly verify the data using PoW only. If the data are stored in the cellbase transaction, the client has to download the cellbase transaction and the merkle tree proof of the cellbase transaction, which can be larger than the block header itself.

This document proposes a solution to add a variable length field in the block. How the new field is interpreted is beyond the scope of this document and must be defined and deployed via a future soft fork. Although the field is added to the block body, nodes can synchronize the block header and this field together in the future version.

## Specification

The block header is encoded as a molecule struct, which consists of fixed length fields. The header binary is just the concatenation of all the fields in sequence.

There are many different ways to add the variable length field to the block header. This RFC proposes to replace the `uncles_hash` in the header with the new field `extra_hash`, which is also a 32-bytes hash. The block will have a new field `extension`.

There are two important time points to deploy this RFC, activation epoch A and extension application epoch B.

In blocks before epoch A, the `extension` must be absent. The value of `extra_hash` is the same as the original `uncles_hash` in these blocks, so this RFC will not change the serialized headers of existing blocks. The field `extra_hash` is all zeros when `uncles` is empty, or `ckbhash` on all the uncle header hashes concatenated together.

```
uncles_hash = 0 when uncles is empty, otherwise

uncles_hash = ckbhash(U1 || U2 || ... || Un)
    where Ui is the header_hash of the i-th uncle in uncles
```

See Appendix for the default hash function `ckbhash`. The annotation `||` means bytes concatenation.

In blocks generated since epoch A, `extension` can be absent, or any binary with 1 to 96 bytes. The upper limit 96 prevents abusing this field because there's no consensus rule to verify the content of `extension`. The 96 bytes limit allows storing the 64-bytes flyclient hash and extra 32-bytes as a hash on further extension bytes.

The `extra_hash` is defined as:

* When `extension` is empty, `extra_hash` is the same as the `uncles_hash`.
* Otherwise `extra_hash = ckbhash(uncles_hash || ckbhash(extension))`

Since epoch B, consensus will define the schema of `extension` and verify the content. This is a soft fork if the `extension` is at most 96 bytes, because nodes deployed since epoch A do not verify the content of `extension`.  

### P2P Protocols Changes

The field `uncles_hash` in the block header is renamed to `extra_hash`.

```
struct RawHeader {
    version:                Uint32,
    compact_target:         Uint32,
    timestamp:              Uint64,
    number:                 Uint64,
    epoch:                  Uint64,
    parent_hash:            Byte32,
    transactions_root:      Byte32,
    proposals_hash:         Byte32,
    extra_hash:             Byte32,
    dao:                    Byte32,
}
```

The new field `extension` will be added to the block body and following data structures:

```
table Block {
    header:       Header,
    uncles:       UncleBlockVec,
    transactions: TransactionVec,
    proposals:    ProposalShortIdVec,
    extension:    Bytes,
}

table CompactBlock {
    header:                 Header,
    short_ids:              ProposalShortIdVec,
    prefilled_transactions: IndexTransactionVec,
    uncles:                 Byte32Vec,
    proposals:              ProposalShortIdVec,
    extension:              Bytes,
}
```

For blocks before the activation epoch A, `extension` must be absent. After activation, the node must verify that `extension` is absent or a binary with 1 to 96 bytes, and `uncles` and `extension` match the `extra_hash` in the header.

Pay attention that the `extension` field will occupy the block size.

### RPC Changes

* The `uncles_hash` is renamed to `extra_hash`.
* The new field `extension` is added to the block body RPC response. For blocks generated in ckb2019, it is always empty.

## Comparison With Alternative Solutions

1. [Appending the Field At the End](./1-appending-the-field-at-the-end.md)
2. [Using Molecule Table in New Block Headers](./2-using-molecule-table-in-new-block-headers.md)
3. [Appending a Hash At the End](./3-appending-a-hash-at-the-end.md)

## Appendix

### ckbhash

CKB uses [blake2b](https://blake2.net/blake2.pdf) as the default hash algorithm with following configurations:

- output digest size: 32
- personalization: ckb-default-hash

Python 3 Example and test vectors:

```python
import hashlib
import unittest

def ckbhash():
    return hashlib.blake2b(digest_size=32, person=b'ckb-default-hash')

class TestCKBBlake2b(unittest.TestCase):

    def test_empty_message(self):
        hasher = ckbhash()
        hasher.update(b'')
        self.assertEqual('44f4c69744d5f8c55d642062949dcae49bc4e7ef43d388c5a12f42b5633d163e', hasher.hexdigest())

if __name__ == '__main__':
    unittest.main()
```
