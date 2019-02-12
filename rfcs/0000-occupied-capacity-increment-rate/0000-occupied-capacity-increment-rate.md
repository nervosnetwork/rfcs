---
Number: 0000
Category: Standards Track
Status: Proposal
Author: Jinyang Jiang
Organization: Nervos Foundation
Created: 2019-2-11
---

# Occupied capacity increment rate

## Abstract

Capacity is one of the core resources in CKB network, itself is just a number representing how much storage resource a user can use.

Once a user decides to store something in CKB, the user must lock some capacity in exchange, the locked capacity which we called occupied capacity represents the actually used resource in the network.

Occupied capacity affects CKB network in two ways:

1. Single block occupied capacity: if a single block or transaction contains too much occupied capacity, it may affect the propagation of the block and may slow down the whole network.
2. The whole network occupied capacity: that every full node must cost the same memory or disk to save these content, it incentives miners to be more centralized which does not make any sense for a decentralized network.

So the solution is to limit occupied capacity in each block, to indirectly control the network's total occupied capacity and the increment rate of occupied capacity.

This RFC proposes to make occupied capacity under control by adding two verification rules:

1. limit the block size
2. limit the increment of total network occupied capacity in block level


## Specification

Define three variables:

* `MAX_BLOCK_BODY_BYTES`           - the max bytes of `commit_transactions` and `proposal_transactions` in a block, value: 10 MB
* `MAX_BLOCK_UNCLES_BYTES`         - the max bytes of uncles blocks, value: 1 MB
* `MAX_INCREMENT_OCCUPIED_CAPACITY` - the max increment occupied capacity of a block, value: 2 MB

Add two verification rules to CKB consensus:

### 1. Block size verification rule

Unfortunately, we could not just put a block size limitation on CKB like Bitcoin.

Because CKB has four fields defined in each block: `header`, `uncles`, `commit_transactions`, `proposal_transactions`, but CKB miner takes fees only from `commit_transactions`, they do not receive any incentives for submitting other parts. So a reasonable miner first packs `commit_transactions` into the block to make sure transactions fees as more as possible and immediately give up packs other parts once block size reaches the limitation.

It is bad news because CKB consensus adjusts the network based on uncle blocks, CKB consensus will not properly work once miners give up to submit `uncles`.

So instead of a simple block size limitation, we must separately limit the size of `uncles` from other parts to make CKB consensus work under the designed intention.

We define two concepts to control the size of a block:

1. block body size  : the bytes size of `commit_transactions` and `proposal_transactions`.
2. block uncles size: the bytes size of `uncles`.

The `header` is always constant size so that we can ignore it safely.

We define "block body size" and "block uncles size" as follow, notice the `CFB_serialize` in pseudo code refers to the [CFB serialization RFC][1].

Pseudo code:

``` rust
fn block_body_size(block: Block) -> u64 {
    let commit_txs_size = block.commit_transactions().map(|tx| CFB_serialize(tx).bytes_size()).sum();
    let proposal_txs_size = block.proposal_transactions().map(|short_id| CFB_serialize(short_id).bytes_size()).sum();
    commit_txs_size + proposal_txs_size
}

fn block_uncles_size(block: Block) -> u64 {
    block.uncles().map(|uncle|{
        let cellbase_size = CFB_serialize(uncle.cellbase()).bytes_size();
        let proposal_txs_size = uncle.proposal_transactions().map(|short_id| CFB_serialize(short_id).bytes_size()).sum();
        cellbase_size + proposal_txs_size
    }).sum()
}
```

The new verification rule:

Block body size must be smaller than or equal to `MAX_BLOCK_BODY_BYTES`;
Block uncles size must be smaller than or equal to `MAX_BLOCK_UNCLES_BYTES`.

Pseudo code: 
``` rust
assert!(block_body_size(block) <= MAX_BLOCK_BODY_BYTES 
    && block_uncles_size(block) <= MAX_BLOCK_UNCLES_BYTES)
```

This rule makes a single block occupied capacity under control, and also solves several other problems (unlock script size is too big, arguments size is too long, ...).

### 2. Increment occupied capacity verification rule

Each transaction spends old outputs and generates new outputs, so it is easy to get increment occupied capacity of a transaction by using the sum of outputs occupied capacity to minus the sum of inputs consumed occupied capacity.
By accumulating the increment occupied capacity of transactions in a block we can get increment occupied capacity of the block.

The occupied capacity that a block introduced must be less than or equal to `MAX_INCREMENT_OCCUPIED_CAPACITY`.

Pseudo code:
``` rust
let mut consumed_occupied_capacity = 0;
let mut generated_occupied_capacity = 0;
for tx in block.commit_transactions() {
  consumed_occupied_capacity += tx.inputs.map(|input| input.previous_output.occupied_capacity()).sum();
  generated_occupied_capacity += tx.outputs.map(|output| output.occupied_capacity()).sum();
}

// NOTICE: this value can be negative
assert!(generated_occupied_capacity - consumed_occupied_capacity <= MAX_INCREMENT_OCCUPIED_CAPACITY);
```

### Conclusion

The two rules make the increment of the whole network occupied capacity under control, and leaves room for other RFCs to make proposals like adjusting these two values via consensus (DAO or soft-fork).

## References

1. [CFB][1]

[1]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0008-serialization/0008-serialization.md

