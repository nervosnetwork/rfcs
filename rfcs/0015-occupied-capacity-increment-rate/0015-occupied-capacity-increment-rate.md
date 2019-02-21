---
Number: 0015
Category: Standards Track
Status: Proposal
Author: Jinyang Jiang
Organization: Nervos Foundation
Created: 2019-2-13
---

# Occupied capacity increment rate

## Abstract

Capacity is one of the core resources in CKB network, itself is just a number representing how much storage resource a user can use, once a user store something in CKB, the occupied part of storage which we called occupied capacity represents the actually used resource in the network.

Occupied capacity affects CKB network because that every full node must cost the same memory or disk to save these content, it incentives miners to be more centralized which does not make any sense for a decentralized network.

So the solution is to limit the increase occupied capacity in each block, to indirectly control the network's total occupied capacity and the increment rate of occupied capacity.

## Specification

Define variable:

* `MAX_INCREMENT_OCCUPIED_CAPACITY` - the max increment occupied capacity of a block, value: 2 MB

Add new verification rule to CKB consensus:

### Increment occupied capacity verification rule

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

This RFC makes the increment of the whole network occupied capacity under control, and leaves room for other RFCs to make improving proposals, such as: adjusting increment rate via consensus (DAO or soft-fork).

## References

1. [CKB][1]

[1]: https://github.com/nervosnetwork/ckb

