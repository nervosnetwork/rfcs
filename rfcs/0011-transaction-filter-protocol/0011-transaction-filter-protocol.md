---
Number: "0011"
Category: Standards Track
Status: Proposal
Author: Quake Wang
Organization: Nervos Foundation
Created: 2018-12-11
---

# Transaction Filter Protocol

## Abstract

Transaction filter protocol allows peers to reduce the amount of transaction data they send. Peer which wants to retrieve transactions of interest, has the option of setting filters on each connection. A filter is defined as a [Bloom filter](http://en.wikipedia.org/wiki/Bloom_filter) on data derived from transactions.

## Motivation

The purpose of transaction filter protocol is to allow low-capacity peers (smartphones, browser extensions, embedded devices, etc) to maintain a high-security assurance about the up to date state of some particular transactions of the chain or verify the execution of transactions.

These peers do not attempt to fully verify the block chain, instead just checking that [block headers connect](../0004-ckb-block-sync/0004-ckb-block-sync.md#connecting-header) together correctly and trusting that the transactions in the block of highest difficulty are in fact valid.

Without this protocol, peers have to download the entire blocks and accept all broadcast transactions, then throw away majority of the transactions. This slows down the synchronization process, wastes users bandwidth and increases memory usage.

## Messages

*Message serialization format is [Molecule](../0008-serialization/0008-serialization.md)*

### SetFilter

Upon receiving a `SetFilter` message, the remote peer will immediately restrict the transactions that it broadcasts to the ones matching the filter, where the [matching algorithm](#filter-matching-algorithm) is specified as below.

```
table SetFilter {
    filter: [uint8];
    num_hashes: uint8;
    hash_seed: uint32;
}
```

`filter`: A bit field of arbitrary byte-aligned size. The maximum size is 36,000 bytes.

`num_hashes`: The number of hash functions to use in this filter. The maximum value allowed in this field is 20. This maximum value and `filter` maximum size allow to store ~10,000 items and the false positive rate is 0.0001%.

`hash_seed`: We use [Kirsch-Mitzenmacher-Optimization](https://www.eecs.harvard.edu/~michaelm/postscripts/tr-02-05.pdf) hash function in this protocol, `hash_seed` is a random offset, `h1` is low uint32 of hash value, `h2` is high uint32 of hash value, and the nth hash value is `(hash_seed + h1 + n * h2) mod filter_size`.

### AddFilter

Upon receiving a `AddFilter` message, the given bit data will be added to the exsiting filter via bitwise OR operator. A filter must have been previously provided using `SetFilter`. This messsage is useful if a new filter is added to a peer whilst it has connections to the network open, alsp avoids the need to re-calculate and send an entirely new filter to every peer.

```
table AddFilter {
    filter: [uint8];
}
```

`filter`: A bit field of arbitrary byte-aligned size. The data size must be litter than or equal to previously provided filter size.

### ClearFilter

The `ClearFilter` message tells the receiving peer to remove a previously-set bloom filter.

```
table ClearFilter {
}
```

The `ClearFilter` message has no arguments at all.


### FilteredBlock

After a filter has been set, peers don't merely stop announcing non-matching transactions, they can also serve filtered blocks. This message is a replacement for `Block` message of sync protocol and `CompactBlock` message of relay protocol.

```
table FilteredBlock {
    header: Header;
    transactions: [IndexTransaction];
    hashes: [H256];
}

table IndexTransaction {
    index:                      uint32;
    transaction:                Transaction;
}
```

`header`: Standard block header struct.

`transactions`: Standard transaction struct plus transaction index.

`hashes`: Partial [Merkle](../0006-merkle-tree/0006-merkle-tree.md#merkle-proof) branch proof.

## Filter matching algorithm

The filter can be tested against all broadcast transactions, to determine if a transaction matches the filter, the following algorithm is used. Once a match is found the algorithm aborts.

1. Test the hash of the transaction itself.
2. For each CellInput, test the hash of `previous_output`.
3. For each CellOutput, test the `lock hash` and `type hash` of script.
4. Otherwise there is no match.
