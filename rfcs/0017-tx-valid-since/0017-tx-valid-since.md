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

Transaction input adds a new `u64` type field `valid_since`, which prevents the transaction to be mined before an absolute or relative time.

The highest 8 bits of `valid_since` is `flags`, the remain `56` bits represent `value`, `flags` allow us to determine behaviours:
* `flags & (1 << 7)` represent `relative_flag`.
* `flags & (1 << 6)` represent `metric_flag`.
    * `valid_since` use a block based lock-time if `metric_flag` is `0`, `value` can be explained as a block number or a relative number.
    * `valid_since` use a time based lock-time if `metric_flag` is `1`, `value` can be explained as a block timestamp(unix time) or a relative seconds.
* other 6 `flags` bits remain for other use.

The consensus to validate this field described as follow:
* iterate inputs, and validate each input by following rules.
* ignore this validate rule if all 64 bits of `valid_since` are 0.
* check `metric_type` flag:
    * the lower 56 bits of `valid_since` represent block number if `metric_type` is `0`.
    * the lower 56 bits of `valid_since` represent block timestamp if `metric_type` is `1`.
* check `relative_flag`:
    * consider field as absolute lock time if `relative_flag` is `0`:
        * fail the validation if tip's block number or block timestamp is less than `valid_since` field.
    * consider field as relative lock time if `relative_flag` is `1`:
        * find the block which produced the input cell, get the block timestamp or block number based on `metric_type` flag.
        * fail the validation if tip's number or timestamp minus block's number or timestamp is less than `valid_since` field.
* Otherwise, the validation SHOULD continue.

A cell lock script can check the `valid_since` field of an input and return invalid when `valid_since` not satisfied condition, to indirectly prevent cell to be spent.

This provides the ability to implement time-based fund lock scripts:

``` ruby
# absolute time lock
# cell only can be spent when block number greater than 10000.
def unlock?
  input = CKB.load_current_input
  # fail if it is relative lock
  return false if input.valid_since[63] == 1
  # fail if metric_type is timestamp
  return false if input.valid_since[62] == 1
  input.valid_since > 10000
end
```

``` ruby
# relative time lock
# cell only can be spent after 3 days after block that produced this cell get confirmed
def unlock?
  input = CKB.load_current_input
  # fail if it is absolute lock
  return false if input.valid_since[63].zero?
  # fail if metric_type is block number
  return false if input.valid_since[62].zero?
  # extract lower 56 bits and convert to seconds
  time = (valid_since & 0x00ffffffffffffff) << 9
  # check time must greater than 3 days
  time > 3 * 24 * 3600
end
```

## Detailed Specification

`valid_since` SHOULD be validated with the median timestamp of the past 11 blocks to instead the block timestamp when `type flag` is 1, this prevents miner lie on the timestamp for earning more fees by including more transactions that immature.

The median block time calculated from the past 11 blocks timestamp (from block's parent), we pick the older timestamp as median if blocks number is not enough and is odd, the details behavior defined as the following code:

``` rust
pub trait BlockMedianTimeContext {
    fn median_block_count(&self) -> u64;
    /// block timestamp
    fn timestamp(&self, block_number: BlockNumber) -> Option<u64>;
    /// ancestor timestamps from a block
    fn ancestor_timestamps(&self, block_number: BlockNumber) -> Vec<u64> {
        let count = self.median_block_count();
        (block_number.saturating_sub(count)..=block_number)
            .filter_map(|n| self.timestamp(n))
            .collect()
    }

    /// get block median time
    fn block_median_time(&self, block_number: BlockNumber) -> Option<u64> {
        let mut timestamps: Vec<u64> = self.ancestor_timestamps(block_number);
        timestamps.sort_by(|a, b| a.cmp(b));
        // return greater one if count is even.
        timestamps.get(timestamps.len() / 2).cloned()
    }
}
```

Validation of transaction `valid_since` defined as follow code:

``` rust
const LOCK_TYPE_FLAG: u64 = 1 << 63;
const TIME_TYPE_FLAG: u64 = 1 << 62;
const TIMESTAMP_SCALAR: u64 = 9;
const VALUE_MUSK: u64 = 0x00ff_ffff_ffff_ffff;

#[derive(Copy, Clone, Debug)]
struct ValidSince(u64);

impl ValidSince {
    pub fn is_absolute(self) -> bool {
        self.0 & LOCK_TYPE_FLAG == 0
    }

    #[inline]
    pub fn is_relative(self) -> bool {
        !self.is_absolute()
    }

    fn metric_type_is_number(self) -> bool {
        self.0 & TIME_TYPE_FLAG == 0
    }

    #[inline]
    fn metric_type_is_timestamp(self) -> bool {
        !self.metric_type_is_number()
    }

    pub fn block_timestamp(self) -> Option<u64> {
        if self.metric_type_is_timestamp() {
            Some(((self.0 & VALUE_MUSK) << TIMESTAMP_SCALAR) * 1000)
        } else {
            None
        }
    }

    pub fn block_number(self) -> Option<u64> {
        if self.metric_type_is_number() {
            Some(self.0 & VALUE_MUSK)
        } else {
            None
        }
    }
}

pub struct ValidSinceVerifier<'a, M> {
    rtx: &'a ResolvedTransaction,
    block_median_time_context: &'a M,
    tip_number: BlockNumber,
    median_timestamps_cache: RefCell<LruCache<BlockNumber, Option<u64>>>,
}

impl<'a, M> ValidSinceVerifier<'a, M>
where
    M: BlockMedianTimeContext,
{
    pub fn new(
        rtx: &'a ResolvedTransaction,
        block_median_time_context: &'a M,
        tip_number: BlockNumber,
    ) -> Self {
        let median_timestamps_cache = RefCell::new(LruCache::new(rtx.input_cells.len()));
        ValidSinceVerifier {
            rtx,
            block_median_time_context,
            tip_number,
            median_timestamps_cache,
        }
    }

    fn block_median_time(&self, n: BlockNumber) -> Option<u64> {
        let result = self.median_timestamps_cache.borrow().get(&n).cloned();
        match result {
            Some(r) => r,
            None => {
                let timestamp = self.block_median_time_context.block_median_time(n);
                self.median_timestamps_cache
                    .borrow_mut()
                    .insert(n, timestamp);
                timestamp
            }
        }
    }

    fn verify_absolute_lock(&self, valid_since: ValidSince) -> Result<(), TransactionError> {
        if valid_since.is_absolute() {
            if let Some(block_number) = valid_since.block_number() {
                if self.tip_number < block_number {
                    return Err(TransactionError::Immature);
                }
            }

            if let Some(block_timestamp) = valid_since.block_timestamp() {
                let tip_timestamp = self
                    .block_median_time(self.tip_number.saturating_sub(1))
                    .unwrap_or_else(|| 0);
                if tip_timestamp < block_timestamp {
                    return Err(TransactionError::Immature);
                }
            }
        }
        Ok(())
    }
    fn verify_relative_lock(
        &self,
        valid_since: ValidSince,
        cell_meta: &CellMeta,
    ) -> Result<(), TransactionError> {
        if valid_since.is_relative() {
            // cell still in tx_pool
            let cell_block_number = match cell_meta.block_number {
                Some(number) => number,
                None => return Err(TransactionError::Immature),
            };
            if let Some(block_number) = valid_since.block_number() {
                if self.tip_number < cell_block_number + block_number {
                    return Err(TransactionError::Immature);
                }
            }

            if let Some(block_timestamp) = valid_since.block_timestamp() {
                let tip_timestamp = self
                    .block_median_time(self.tip_number.saturating_sub(1))
                    .unwrap_or_else(|| 0);
                let median_timestamp = self
                    .block_median_time(cell_block_number.saturating_sub(1))
                    .unwrap_or_else(|| 0);
                if tip_timestamp < median_timestamp + block_timestamp {
                    return Err(TransactionError::Immature);
                }
            }
        }
        Ok(())
    }

    pub fn verify(&self) -> Result<(), TransactionError> {
        for (cell_status, input) in self
            .rtx
            .input_cells
            .iter()
            .zip(self.rtx.transaction.inputs())
        {
            let cell = match cell_status.get_live() {
                Some(cell) => cell,
                None => return Err(TransactionError::Conflict),
            };
            // ignore empty valid_since
            if input.valid_since == 0 {
                continue;
            }
            let valid_since = ValidSince(input.valid_since);
            self.verify_absolute_lock(valid_since)?;
            self.verify_relative_lock(valid_since, cell)?;
        }
        Ok(())
    }
}
```

