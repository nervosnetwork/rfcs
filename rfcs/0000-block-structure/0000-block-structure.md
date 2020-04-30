---
Number: "0000"
Category: Informational
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2020-04-30
---

# CKB Block Structure

In CKB, Block is a container of transactions. It also carries the information required by consensus so the participants can verify and recognize the canonical chain.

The snippet below lists the molecule schema definitions related to block. The following will explain these structures field by field.

```
array ProposalShortId [byte; 10];

vector UncleBlockVec <UncleBlock>;
vector TransactionVec <Transaction>;
vector ProposalShortIdVec <ProposalShortId>;

table Block {
    header:                 Header,
    uncles:                 UncleBlockVec,
    transactions:           TransactionVec,
    proposals:              ProposalShortIdVec,
}

struct Header {
    raw:                    RawHeader,
    nonce:                  Uint128,
}

struct RawHeader {
    version:                Uint32,
    compact_target:         Uint32,
    timestamp:              Uint64,
    number:                 Uint64,
    epoch:                  Uint64,
    parent_hash:            Byte32,
    transactions_root:      Byte32,
    proposals_hash:         Byte32,
    uncles_hash:            Byte32,
    dao:                    Byte32,
}

table UncleBlock {
    header:                 Header,
    proposals:              ProposalShortIdVec,
}
```

## Block

A Block can be split into two parts, header and body. The field `header` is the header part. The remaining fields, `uncles`, `transactions` and `proposals` are the body part.

The header contains commitments on the body fields to ensure data integrity. CKB client can download and verify the header first, then download the much larger body part. Since PoW verification only requires header and uncles count in an epoch, this design can avoid wasting the bandwidth to download garbage data.

## Header

To ease PoW computation, the header is split into `raw` and `nonce`. The header must meet the last inequality in the following snippet:

```
pow_hash := ckb_hash(molecule_serialize(raw))
pow_message := pow_hash || to_le(nounce)
pow_output := eaglesong(pow_message)

from_be(pow_output) <= compact_to_target(raw.compact_target)
```

Functions used in the pseudocode:

* `:=`: assignment
* `||`: binary concatenation.
* `ckb_hash`: Blake2b hash with CKB specific configuration, see #todo
* `to_le`: Convert unsigned integer to bytes in little endian. The bytes count is the same with the integer width.
* `from_be`: Convert bytes encoded in big endian to an unsigned integer.
* `molecule_serialize`: Serialize a structure into binary using its schema.
* `eaglesong`: See #todo rfc
* `compact_to_target`: `raw.compact_target` encodes the difficulty target in a compact form. This function restores the target from the compact from.

The block is usually referenced by the header hash, for example, in `raw.parent_hash`.

```
header_hash := ckb_hash(molecule_serialize(header))
```

Notice that Header and RawHeader are all fixed size structure. The serialization of them are just the simple binary concatenation of the fields in order.

## RawHeader

RawHeader is the real payload of the block header.

### `version (Uint32)`

It must equal to 0 now and is reserved for future upgrades.

### `compact_target (Uint32)`

#todo target conversion.

The `compact_target` does not change in an epoch. In a new epoch, the difficulty is adjusted according to all the headers and the total uncles count in the previous epoch.

#todo see difficulty adjustment chapter in the consensus RFC

#todo genesis block

### `timestamp (Uint64)`

The time when the block is created encoded as Unix Timestamp, in milliseconds. For example

```
1588233578000 is Thu, 30 Apr 2020 07:59:38 +0000
```

#todo median block time rule
#todo future block rejection

The genesis block timestamp is hardcoded in the consensus specification.

### `number (Uint64)`

A sequential number which encodes the genesis block as 0, and the child block number is the parent block number plus 1.

```
genesis_header.number := 0
header.number := parent_header.number + 1
```

### `epoch (Uint64)`

This field encodes the epoch number and the fraction position of this block in the epoch.

#todo epoch encoding schema

### `parent_hash (Byte32)`

The header hash of the parent block. It is #todo in the genesis block.

### `transaction_root (Byte32)`

#todo

This is the commitment on the `transactions` in the block.

### `proposals_hash (Byte32)`

#todo

### `uncles_hash (Byte32)`

#todo

### `dao (Byte32)`

#todo

## Transactions

The field `block.transactions` is the ordered list of transactions in the block. The first transaction must be the cellbase. See the transaction informational RFC.

## Uncles

The field `block.uncles` is the ordered list of uncle blocks.

#todo what is uncle block?
#todo what are stored in uncle block?
#todo what feature uncles provide?

## Proposals

#todo what is proposal id?
#todo what's the usage of proposals?
