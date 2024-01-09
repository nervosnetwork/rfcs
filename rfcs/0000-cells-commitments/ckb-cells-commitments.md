---
Number: "0000"
Category: Standards Track
Status: Proposal
Author: Quake Wang <quake.wang@gmail.com>
Created: 2023-08-14
---

# CKB Cells Commitments

## Abstract

This RFC describes a cell commitment format for CKB that can be used to verify the cell status in decentralized way.

## Motivation

In cross-chain or on-chain contract verification scenarios we often need to verify the state of a cell, e.g. to prove at which height a cell was created and at which height it was consumed. Currently, CKB has no way to provide such a commitment, and the only way to address this issue is through pegged blocks with a challenge mechanism or a centralized trust mechanism.

This RFC proposes a cell commitment format to solve this issue in a decentralized, trustless and lightweight way.

## Specification

### Updatable Merkle Mountain Range

We use an updatable Merkle Mountain Range ([MMR]) to store the cell status. The cell status is defined as a tuple of `(out_point, created_by, consumed_by)`, where `out_point` is the cell out point, `created_by` is the block number when the cell was created, and `consumed_by` is the block number when the cell was consumed. The `created_by` and `consumed_by` are both `u64` numbers and the `consumed_by` is set to `u64::MAX` if a cell is live.

Each MMR leaf node is the hash digest of a cell status, the hash digest is calculated as `H(out_point || created_by || consumed_by)`, where `H` is the blake2b[\[2\]] hash function, `||` is the concatenation operator, `out_point` is serialized as molecule binary format, and `created_by` and `consumed_by` are serialized as little-endian `u64` numbers.

The MMR is updatable, which means we can update the leaf node of a cell status when the cell is consumed.

Let’s look at how the updatable MMR works in detail. Consider the following MMR with three cells in genesis block, which we’ll call state #0:

```
   root
   / \
  0   \
 / \   \
a   b   c
```

If we generate another cell in block#1 we get state #1:

```
     root
     / \
    /   \
   /     \
  0       1
 / \     / \
a   b   c   d
```

Note that the inner node `0` is not updated because the cell `a` and `b` are not consumed yet.

If we generate two cells and consume cell `b` in block#2 we get state #2:

```
         root
        /   \
       /     \
      3       \
     / \       \
    /   \       \
   /     \       \
  0'      1       2
 / \     / \     / \
a  b'   c   d   e   f
```

Note that the inner node `0` is updated because the cell `b` is consumed and the hash digest of cell `b` is changed to `b'`.


### Commitment

The MMR root hash will be used as the commitment of all cells status, it will be stored in in the extension field of each block. A RPC method will be provided to generate the merkle proof of specified cells status, cross-chain or on-chain contract verification can use the proof to verify the cell status against the commitment.

The RPC method will accept a list of cell out points and block hash as input, and return the proof of the cell status in the specified block.

```json
    {
        "id": 1,
        "jsonrpc": "2.0",
        "method": "get_cells_status_proof",
        "params": [
            [
                {
                    "tx_hash": "0x...",
                    "index": "0x0"
                },
                {
                    "tx_hash": "0x...",
                    "index": "0x1"
                }
            ],
            "0x..."
        ]
    }
```

The returing proof includes the following fields:

- `cells_count`: the total number of generated cells from genesis block to the specified block, including consumed cells.
- `cells_status`: an array of cell status, includes the following fields:
    - `position`: the position of the leaf node in the MMR.
    - `out_point`: the cell out point.
    - `created_by`: the block number when the cell was created.
    - `consumed_by`: the block number when the cell was consumed, optional, none if the cell is live.
- `proof`: the merkle proof of the MMR, it is an array of hash digests, we can use this proof and `cells_status` field to verify the MMR root.

### Versioned Storage

We need to store the MMR in a versioned manner, so that we can rollback the MMR when a chain reorg happens or provide a snapshot of the MMR at any specified block (e.g. for RPC). We can use the block number as the version number of the MMR, and store the `position || version` as key of MMR node in a key-value storage that supports prefix seek, then we can use the following algorithm to find the node of specified position and build the MMR at any specified block:

```rust
        let start_key = [&position.to_le_bytes(), &block_number.to_be_bytes()].concat();
        let node = store
            .iter(&start_key, Direction::Reverse)
            .take_while(|(key, _)| key.starts_with(&start_key[0..8]))
            .next()
            .map(|(_key, value)| value);

```

Note that the `version` (block_number) is stored as big-endian bytes instead of little-endian, so that we can use the `Reverse` prefix seek direction to find the latest version of the MMR node.

### Delayed Commitments

From a decentralized point of view, the speed of block validation is crucial, especially for small and solo miners, so we need to make sure that the cell commitment verification will not effect the block validation speed too much. However, the MMR update and verification is a cpu intensive task, the complexity of MMR update is `O(log(n))`, where `n` is the number of total cells. If the implementation of updating commitment in current tip block does not achieve the desired speed, then we need to consider delaying the update.

Concretely each block B<sub>i</sub> commits to the cells status as of block B<sub>i−n</sub>, in other words what the cells commitments would have been n blocks ago. Since that commitment only depends on the contents of the blockchain up until block B<sub>i−n</sub>, the contents of any block after are irrelevant to the calculation, thus the commitment can be calculated in parallel with the block validation.

## Deployment

The cells commitments will be deployed via [RFC-0043 CKB softfork activation].

The parameters[\[1\]] to activate this feature are:
| Parameters | For CKB Testnet | For CKB Mainnet |
|-------|---------------|---------------|
| `name` | CellCommitment | CellCommitment |
| `bit` | 2 | 2 |
| `start_epoch` | TBD | TBD |
| `timeout_epoch` | TBD | TBD |
| `period` | 42 | TBD |
| `threshold` | 75% | TBD |
| `min_activation_epoch` | TBD | TBD |

After the feature is activated, the cell commitment will be stored in the extension field of each block as a 32-bytes hash digest, the position of the commitment in the extension field is 32 ~ 64.

## References
- [Merkle Mountain Ranges][MMR]
- [RFC-0043 CKB softfork activation]

[MMR]: https://github.com/opentimestamps/opentimestamps-server/blob/master/doc/merkle-mountain-range.md
[RFC-0043 CKB softfork activation]: ../0043-ckb-softfork-activation/0043-ckb-softfork-activation.md
[\[1\]]: ../0043-ckb-softfork-activation/0043-ckb-softfork-activation.md#parameters
[\[2\]]: ../0022-transaction-structure/0022-transaction-structure.md#crypto-primitives
