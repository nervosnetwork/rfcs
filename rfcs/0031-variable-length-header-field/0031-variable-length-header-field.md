---
Number: "0031"
Category: Standards Track
Status: Proposal
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-02-07
---

# Add a Variable Length Field in Block

## Abstract

This document proposes adding an optional variable length field to the block data structure.

## Motivation

In the consensus version before activating this RFC, the block header is a fixed length structure. Each header consists of 208 bytes.

Many extensions require adding new fields to the block data structure, for example, flyclient requires a 64-byte hash in the header. However, there are not enough reserved bits for this. There are workarounds such as storing these data in the cellbase transaction, but this has a heavy overhead for clients that want to verify the chain using only PoW. Because they have to download the cellbase transaction and the merkle tree proof of the cellbase transaction, which can be larger than the block header itself.

This document proposes a solution to add a variable length field in the block data structure. The interpretation of the new field is beyond the scope of this document and will need to be defined and deployed in a future soft fork. Although the field is added to the block body, nodes can synchronize the block header and this field together in the future version.

## Specification

The block header is encoded as a molecule struct, which consists of fixed length fields. The header binary is just the concatenation of all the fields in sequence.

There are many ways to add the variable length field to the block header. This RFC proposes to replace the `uncles_hash` field in the header with the new `extra_hash` field, which is also a 32-byte hash. The block data structure will have a new `extension` field.

There are two important time points to deploy this RFC, activation epoch A and extension application epoch B.

In blocks before epoch A, the `extension` field must be absent. The value of `extra_hash` is the same as the original `uncles_hash` in these blocks, so this RFC will not change the serialized headers of existing blocks. If the `uncles` field is empty, the `extra_hash` field is zero; otherwise, the `ckbhash` function is applied to the concatenation of all uncle header hashes.

```
uncles_hash = 0 when uncles is empty, otherwise

uncles_hash = ckbhash(U1 || U2 || ... || Un)
    where Ui is the header_hash of the i-th uncle in uncles
```

See Appendix for the default hash function `ckbhash`. The annotation `||` means bytes concatenation.

In blocks generated since epoch A, `extension` can be absent, or any binary with 1 to 96 bytes. The upper limit of 96 prevents abuse of this field because there is no consensus rule to verify the content of `extension`. The 96 bytes limit allows storing the 64-byte flyclient hash and an extra 32-byte hash on further extension bytes.

The `extra_hash` is defined as:

* When `extension` is empty, `extra_hash` is the same as the `uncles_hash`.
* Otherwise, `extra_hash = ckbhash(uncles_hash || ckbhash(extension))`

Since epoch B, the consensus will define the schema and verify the content of `extension`. This is a soft fork if the `extension` field is at most 96 bytes, because nodes deployed since epoch A do not verify the content of `extension`.  

### P2P Protocols Changes

The `uncles_hash` field in the block header is renamed to `extra_hash`.

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

The new `extension` field will be added to the block body and the following data structures:

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

In blocks before the activation epoch A, `extension` must be absent. After the activation, the node must verify that `extension` is absent or a binary with 1 to 96 bytes, and `uncles` and `extension` match the `extra_hash` value in the header.

The `extension` field will occupy the block size. For more information, see [Block and Compact Block Structure](../0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md#block-and-compact-block-structure) in RFC20.

The uncle blocks packaged in `uncles` will not include the `extension` field.

### RPC Changes

* The `uncles_hash` is renamed to `extra_hash`.
* The new `extension` field is added to the block body RPC response. For blocks generated in CKB2019, it is always empty.

## Comparison With Alternative Solutions

1. [Appending the Field at the End](./1-appending-the-field-at-the-end.md)
2. [Using a Molecule Table in New Block Headers](./2-using-molecule-table-in-new-block-headers.md)
3. [Appending a Hash at the End](./3-appending-a-hash-at-the-end.md)

## Test Vectors

### Block Hash

<details><summary>Block Template</summary>

```json
{
  "version": "0x0",
  "compact_target": "0x20010000",
  "current_time": "0x17af3f66555",
  "number": "0x3",
  "epoch": "0x3e80003000000",
  "parent_hash": "0xebf229020f333100942279dc33303ae0dfcbe720d8d11818687e6654c157294c",
  "cycles_limit": "0x2540be400",
  "bytes_limit": "0x91c08",
  "uncles_count_limit": "0x2",
  "uncles": [],
  "transactions": [
    {
      "hash": "0x9110ca9266f89938f09ae6f93cc914b2c856cc842440d56fda6d16ee62543f5c",
      "required": false,
      "cycles": "0x19f2d1",
      "depends": null,
      "data": {
        "version": "0x0",
        "cell_deps": [
          {
            "out_point": {
              "tx_hash": "0xace5ea83c478bb866edf122ff862085789158f5cbff155b7bb5f13058555b708",
              "index": "0x0"
            },
            "dep_type": "dep_group"
          }
        ],
        "header_deps": [],
        "inputs": [
          {
            "since": "0x0",
            "previous_output": {
              "tx_hash": "0xa563884b3686078ec7e7677a5f86449b15cf2693f3c1241766c6996f206cc541",
              "index": "0x7"
            }
          }
        ],
        "outputs": [
          {
            "capacity": "0x2540be400",
            "lock": {
              "code_hash": "0x709f3fda12f561cfacf92273c57a98fede188a3f1a59b1f888d113f9cce08649",
              "hash_type": "data",
              "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
            },
            "type": null
          },
          {
            "capacity": "0x2540be400",
            "lock": {
              "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
              "hash_type": "type",
              "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
            },
            "type": null
          },
          {
            "capacity": "0x2540be400",
            "lock": {
              "code_hash": "0x709f3fda12f561cfacf92273c57a98fede188a3f1a59b1f888d113f9cce08649",
              "hash_type": "data1",
              "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
            },
            "type": null
          }
        ],
        "outputs_data": [
          "0x",
          "0x",
          "0x"
        ],
        "witnesses": [
          "0x550000001000000055000000550000004100000070b823564f7d1f814cc135ddd56fd8e8931b3a7040eaf1fb828adae29736a3cb0bc7f65021135b293d10a22da61fcc64f7cb660bf2c3276ad63630dad0b6099001"
        ]
      }
    }
  ],
  "proposals": [],
  "cellbase": {
    "hash": "0x185d1c46fe3c4a0a1a5ae47203df2aeebbb97ac353abcf2c6a3fc2548ecd4eda",
    "cycles": null,
    "data": {
      "version": "0x0",
      "cell_deps": [],
      "header_deps": [],
      "inputs": [
        {
          "since": "0x3",
          "previous_output": {
            "tx_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "index": "0xffffffff"
          }
        }
      ],
      "outputs": [],
      "outputs_data": [],
      "witnesses": [
        "0x590000000c00000055000000490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce80114000000c8328aabcd9b9e8e64fbc566c4385c3bdeb219d700000000"
      ]
    }
  },
  "work_id": "0x2",
  "dao": "0x105cabf31c1fa12eacfa6990f2862300bdaf44b932000000008d5fff03fbfe06",
  "extension": "0x626c6f636b202333"
}
```

</details>

<details><summary>Block</summary>

```json
{
  "header": {
    "version": "0x0",
    "compact_target": "0x20010000",
    "timestamp": "0x17af3f66555",
    "number": "0x3",
    "epoch": "0x3e80003000000",
    "parent_hash": "0xebf229020f333100942279dc33303ae0dfcbe720d8d11818687e6654c157294c",
    "transactions_root": "0x0bbf9d8946932c9c33a46c8d13b9ecfcf850ccc1728fc9c9c5d14710ad9428ad",
    "proposals_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "extra_hash": "0xfbbfbaaa0afac7730f4a6102b376986f1f288f3eccb18e0d16d58422aab28aad",
    "dao": "0x105cabf31c1fa12eacfa6990f2862300bdaf44b932000000008d5fff03fbfe06",
    "nonce": "0x6e43a02f3ed8bb00dea7f78c12fe94f5"
  },
  "uncles": [],
  "transactions": [
    {
      "version": "0x0",
      "cell_deps": [],
      "header_deps": [],
      "inputs": [
        {
          "since": "0x3",
          "previous_output": {
            "tx_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "index": "0xffffffff"
          }
        }
      ],
      "outputs": [],
      "outputs_data": [],
      "witnesses": [
        "0x590000000c00000055000000490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce80114000000c8328aabcd9b9e8e64fbc566c4385c3bdeb219d700000000"
      ]
    },
    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0xace5ea83c478bb866edf122ff862085789158f5cbff155b7bb5f13058555b708",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        }
      ],
      "header_deps": [],
      "inputs": [
        {
          "since": "0x0",
          "previous_output": {
            "tx_hash": "0xa563884b3686078ec7e7677a5f86449b15cf2693f3c1241766c6996f206cc541",
            "index": "0x7"
          }
        }
      ],
      "outputs": [
        {
          "capacity": "0x2540be400",
          "lock": {
            "code_hash": "0x709f3fda12f561cfacf92273c57a98fede188a3f1a59b1f888d113f9cce08649",
            "hash_type": "data",
            "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
          },
          "type": null
        },
        {
          "capacity": "0x2540be400",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "hash_type": "type",
            "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
          },
          "type": null
        },
        {
          "capacity": "0x2540be400",
          "lock": {
            "code_hash": "0x709f3fda12f561cfacf92273c57a98fede188a3f1a59b1f888d113f9cce08649",
            "hash_type": "data1",
            "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
          },
          "type": null
        }
      ],
      "outputs_data": [
        "0x",
        "0x",
        "0x"
      ],
      "witnesses": [
        "0x550000001000000055000000550000004100000070b823564f7d1f814cc135ddd56fd8e8931b3a7040eaf1fb828adae29736a3cb0bc7f65021135b293d10a22da61fcc64f7cb660bf2c3276ad63630dad0b6099001"
      ]
    }
  ],
  "proposals": [],
  "extension": "0x626c6f636b202333"
}
```

</details>

The hashes:

```
Block Hash:
0xb93dad02d24e9d30c49023d08f84dd8ec34118c1bfec9ed432b75619964686c3

Transaction Hashes:
0x185d1c46fe3c4a0a1a5ae47203df2aeebbb97ac353abcf2c6a3fc2548ecd4eda
0x9110ca9266f89938f09ae6f93cc914b2c856cc842440d56fda6d16ee62543f5c
```

## Appendix

### ckbhash

CKB uses [blake2b](https://blake2.net/blake2.pdf) as the default hash algorithm with the following configurations:

- output digest size: 32
- personalization: ckb-default-hash

A Python 3 example and test vectors:

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
