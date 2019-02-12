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

## Specification

Define two variables:

* `MAX_BLOCK_BYTES`                 - the max size of a block, value: 10 MB
* `MAX_INCREMENT_OCCUPIED_CAPACITY` - the max increment occupied capacity of a block, value: 2 MB

Add two verification rules to CKB consensus:

### 1. Block size verification rule

Serialized block size must be smaller than or equal to `MAX_BLOCK_BYTES`.

Pseudo code: 
``` rust
assert!(serialized_block_size <= MAX_BLOCK_BYTES)
```

CKB uses [CFB][1] as the serializer. Considering that the serializer format should not affects consensus rule, the `serialized_block_size` should be the actual byte size of data excluding metadata introduced by CFB.

This rule makes a single block occupied capacity under control, and also solves several other problems (unlock script size is too big, arguments size is too long, ...).

### 2. Increment occupied capacity verification rule

Define `increment_occupied_capacity` as the sum of all outputs occupied capacity in the block minus all inputs occupied capacity in the block.
The occupied capacity that a block introduced must be less than or equal to `MAX_INCREMENT_OCCUPIED_CAPACITY`.

Pseudo code:
``` rust
let mut inputs_occupied_capacity = 0;
let mut outputs_occupied_capacity = 0;
for tx in block.commit_transactions() {
  inputs_occupied_capacity += tx.inputs.map(|input| input.occupied_capacity()).sum();
  outputs_occupied_capacity += tx.outputs.map(|output| output.occupied_capacity()).sum();
}

assert!(outputs_occupied_capacity - inputs_occupied_capacity <= MAX_INCREMENT_OCCUPIED_CAPACITY);
```

### Conclusion

The two rules make the increment of the whole network occupied capacity under control, and leaves room for other RFCs to make proposals like adjusting these two values via consensus (DAO or soft-fork).

## References

1. [CFB][1]

[1]: https://github.com/nervosnetwork/rfcs/pull/47

