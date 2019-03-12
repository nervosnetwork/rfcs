---
Number: "0000"
Category: Standards Track
Status: Proposal
Author: Jinyang Jiang
Organization: Nervos Foundation
Created: 2019-03-11
---

# Transaction valid since

## Abstract

This RFC suggests adding a new consensus rule to prevent a cell to be spent before a certain block timestamp or a block number.

## Summary 

Transaction adds a new `u64` type field `valid_since`, which prevent the transaction to be mined before a certain point, the highest bit of `valid_since` is `type flag`, the other 63 bits represent the actual value `V`, the consensus to validate this field described as follow:

* ignore this validate rule if all bits of `valid_since` is 0.
* `V` represent a block number when `type flag` is 0, the validation MUST failed if `tip.block_number < V`.
* `V` represent a block timestamp when `type flag` is 1, the timestamp represented as `V * 512` seconds, the validation MUST failed if `tip.timestamp < V * 512`.

Otherwise, the transaction validate SHOULD continue.

A cell lock script can check the `valid_since` field of a transaction and return invalid when `valid_since` not satisfied condition, to indirectly prevent cell to be spent before a certain block timestamp or a block number.

This provides the ability to implement time-based fund lock scripts:

``` ruby
# cell only can be spent when block number greater than 10000.
def unlock?
  tx = CKB.load_tx
  tx.valid_since[63].zero? && tx.valid_since > 10000
end
```

``` ruby
# cell only can be spent when block timestamp greater than "2019-03-12".
def unlock?
  tx = CKB.load_tx
  return false if tx.valid_since[63].zero?
  timestamp = (tx.valid_since & ~(1 << 63)) * 512
  timestamp > 1552348800
end
```

