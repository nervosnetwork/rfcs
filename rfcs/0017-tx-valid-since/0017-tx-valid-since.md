---
Number: "0017"
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
  timestamp = (tx.valid_since ^ (1 << 63)) * 512
  timestamp > 1552348800
end
```

## Detailed Specification

Transaction `valid_since` SHOULD be validated with the median of the last 11 blocks timestamp to instead the block timestamp when `type flag` is 1, this prevents miner lie on the timestamp for earning more fees by including more transactions that immature.

The median block time calculated from the last 11 blocks timestamp (include tip block), we pick the older timestamp as median if blocks number is not enough and is odd, the details behavior defined as the following code:

``` rust
pub trait BlockMedianTimeContext {
    // number of last blocks, always return 11 in current consensus
    fn block_count(&self) -> u32;
    // Get block timestamp from block hash
    fn timestamp(&self, hash: &H256) -> Option<u64>;
    fn parent_hash(&self, hash: &H256) -> Option<H256>;
    fn block_median_time(&self, hash: &H256) -> Option<u64> {
        let count = self.block_count() as usize;
        let mut block_times = Vec::with_capacity(count);
        let mut current_hash = hash.to_owned();
        for _ in 0..count {
            match self.timestamp(&current_hash) {
                Some(timestamp) => block_times.push(timestamp),
                None => break,
            }
            match self.parent_hash(&current_hash) {
                Some(hash) => current_hash = hash,
                None => break,
            }
        }
        block_times.sort_by(|a, b| b.cmp(a));
        block_times.get(block_times.len() / 2).cloned()
    }
}
```

Validation of transaction `valid_since` defined as follow code:

``` rust
pub struct ValidSinceVerifier<'a, M> {
    transaction: &'a Transaction,
    block_median_time_context: M,
    tip_block_number: BlockNumber,
    tip_block_hash: H256,
}

impl<'a, M> ValidSinceVerifier<'a, M>
where
    M: BlockMedianTimeContext,
{
    pub fn verify(&self) -> Result<(), TransactionError> {
        let valid_since = self.transaction.valid_since().unwrap_or_else(|| 0);
        if valid_since == 0 {
            return Ok(());
        }
        if valid_since >> 63 == 0 && self.tip_block_number < valid_since {
            return Err(TransactionError::Immature);
        } else if self
            .block_median_time_context
            .block_median_time(&self.tip_block_hash)
            .unwrap_or_else(|| 0)
            < (valid_since ^ (1 << 63)) * 512
        {
            return Err(TransactionError::Immature);
        }
        Ok(())
    }
}
```

