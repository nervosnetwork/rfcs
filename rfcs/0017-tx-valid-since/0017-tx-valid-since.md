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

Transaction input adds a new `u64` (unsigned 64-bit integer) type field `since`, which prevents the transaction to be mined before an absolute or relative time.

The highest 8 bits of `since` is `flags`, the remain `56` bits represent `value`, `flags` allow us to determine behaviours:
* `flags & (1 << 7)` represent `relative_flag`.
* `flags & (1 << 6)` and `flags & (1 << 5)` together represent `metric_flag`.
    * `since` use a block based lock-time if `metric_flag` is `00`, `value` can be explained as a block number or a relative block number.
    * `since` use a epoch based lock-time if `metric_flag` is `01`, `value` can be explained as epoch information or relative epoch information.
    * `since` use a time based lock-time if `metric_flag` is `10`, `value` can be explained as a block timestamp(unix time) or a relative seconds.
    * `metric_flag` `11` is invalid.
* other 5 `flags` bits remain for other use.

The consensus to validate this field described as follow:
* iterate inputs, and validate each input by following rules.
* ignore this validate rule if all 64 bits of `since` are 0.
* check `metric_flag` flag:
    * the lower 56 bits of `since` represent block number if `metric_flag` is `00`.
    * the lower 56 bits of `since` represent epoch information if `metric_flag` is `01`.
    * the lower 56 bits of `since` represent block timestamp if `metric_flag` is `10`.
* check `relative_flag`:
    * consider field as absolute lock time if `relative_flag` is `0`:
        * fail the validation if tip's block number or epoch or block timestamp is less than `since` field.
    * consider field as relative lock time if `relative_flag` is `1`:
        * find the block which produced the input cell, get the block timestamp or block number or epoch based on `metric_flag` flag.
        * fail the validation if tip's number or epoch or timestamp minus block's number or epoch or timestamp is less than `since` field.
* Otherwise, the validation SHOULD continue.

A cell lock script can check the `since` field of an input and return invalid when `since` not satisfied condition, to indirectly prevent cell to be spent.

This provides the ability to implement time-based fund lock scripts:

``` ruby
# absolute time lock
# The cell can't be spent unless block number is greater than 10000.
def unlock?
  input = CKB.load_current_input
  # fail if it is relative lock
  return false if input.since[63] == 1
  # fail if metric_flag is not block_number
  return false (input.since & 0x6000_0000_0000_0000) != (0b0000_0000 << 56)
  input.since > 10000
end
```

``` ruby
# relative time lock
# The cell can't be spent unless 3 days(blockchain time) later since the cell gets confirmed on-chain.
def unlock?
  input = CKB.load_current_input
  # fail if it is absolute lock
  return false if input.since[63].zero?
  # fail if metric_flag is not timestamp
  return false (input.since & 0x6000_0000_0000_0000) != (0b0100_0000 << 56)
  # extract lower 56 bits and convert to seconds
  time = since & 0x00ffffffffffffff
  # check time must greater than 3 days
  time > 3 * 24 * 3600
end
```

``` ruby
# relative time lock with epoch
# The cell can't be spent in the next epoch
def unlock?
  input = CKB.load_current_input
  # fail if it is absolute lock
  return false if input.since[63].zero?
  # fail if metric_flag is not epoch information
  return false (input.since & 0x6000_0000_0000_0000) != (0b0010_0000 << 56)
  # extract lower 56 bits
  epoch= since & 0x00ffffffffffffff
  # extract epoch information
  epoch_number = epoch & 0xffffff
  # enforce only can unlock in next or further epochs
  epoch_number >= 1
end
```

## Examples

``` txt
# Absolute time lock

0x0000_0000_0000_3039 # The tx failed verification unless the block number is greater than #12345

0x4000_0000_5e83_d980 # The tx failed verification unless current blockchain date is later than 2020-04-01

0x2000_0000_0000_0400 # The tx failed verification unless the epoch number is greater than 1024

# Relative time lock

0x8000_0000_0000_0064 # The tx failed verification unless it is 100 blocks later since the input cell get confirmed on-chain

0xc000_0000_0012_7500 # The tx failed verification unless it is 14 days(blockchain time) later since the input cell get confirmed on-chain

0xa000_0000_0000_0018 # The tx failed verification unless it is 24 epochs later since the input cell get confirmed on-chain
```

## Detailed Specification

`since` SHOULD be validated with the median timestamp of the past 11 blocks to instead the block timestamp when `metric flag` is `10`, this prevents miner lie on the timestamp for earning more fees by including more transactions that immature.

The median block time calculated from the past 37 blocks timestamp (from block's parent), we pick the older timestamp as median if blocks number is not enough and is odd, the details behavior defined as the following code:

``` rust
pub trait BlockMedianTimeContext {
    fn median_block_count(&self) -> u64;

    /// Return timestamp and block_number of the corresponding bloch_hash, and hash of parent block
    fn timestamp_and_parent(&self, block_hash: &H256) -> (u64, BlockNumber, H256);

    /// Return past block median time, **including the timestamp of the given one**
    fn block_median_time(&self, block_hash: &H256) -> u64 {
        let median_time_span = self.median_block_count();
        let mut timestamps: Vec<u64> = Vec::with_capacity(median_time_span as usize);
        let mut block_hash = block_hash.to_owned();
        for _ in 0..median_time_span {
            let (timestamp, block_number, parent_hash) = self.timestamp_and_parent(&block_hash);
            timestamps.push(timestamp);
            block_hash = parent_hash;

            if block_number == 0 {
                break;
            }
        }

        // return greater one if count is even.
        timestamps.sort();
        timestamps[timestamps.len() >> 1]
    }
}
```

Validation of transaction `since` defined as follow code:

``` rust
const LOCK_TYPE_FLAG: u64 = 1 << 63;
const METRIC_TYPE_FLAG_MASK: u64 = 0x6000_0000_0000_0000;
const VALUE_MASK: u64 = 0x00ff_ffff_ffff_ffff;
const REMAIN_FLAGS_BITS: u64 = 0x1f00_0000_0000_0000;

enum SinceMetric {
    BlockNumber(u64),
    EpochNumberWithFraction(EpochNumberWithFraction),
    Timestamp(u64),
}

/// RFC 0017
#[derive(Copy, Clone, Debug)]
pub(crate) struct Since(pub(crate) u64);

impl Since {
    pub fn is_absolute(self) -> bool {
        self.0 & LOCK_TYPE_FLAG == 0
    }

    #[inline]
    pub fn is_relative(self) -> bool {
        !self.is_absolute()
    }

    pub fn flags_is_valid(self) -> bool {
        (self.0 & REMAIN_FLAGS_BITS == 0)
            && ((self.0 & METRIC_TYPE_FLAG_MASK) != METRIC_TYPE_FLAG_MASK)
    }

    fn extract_metric(self) -> Option<SinceMetric> {
        let value = self.0 & VALUE_MASK;
        match self.0 & METRIC_TYPE_FLAG_MASK {
            //0b0000_0000
            0x0000_0000_0000_0000 => Some(SinceMetric::BlockNumber(value)),
            //0b0010_0000
            0x2000_0000_0000_0000 => Some(SinceMetric::EpochNumberWithFraction(EpochNumberWithFraction::from_full_value(value))),
            //0b0100_0000
            0x4000_0000_0000_0000 => Some(SinceMetric::Timestamp(value * 1000)),
            _ => None,
        }
    }
}

/// https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0017-tx-valid-since/0017-tx-valid-since.md#detailed-specification
pub struct SinceVerifier<'a, M> {
    rtx: &'a ResolvedTransaction,
    block_median_time_context: &'a M,
    block_number: BlockNumber,
    epoch_number_with_fraction: EpochNumberWithFraction,
    parent_hash: Byte32,
    median_timestamps_cache: RefCell<LruCache<Byte32, u64>>,
}

impl<'a, M> SinceVerifier<'a, M>
where
    M: BlockMedianTimeContext,
    {
        pub fn new(
            rtx: &'a ResolvedTransaction,
            block_median_time_context: &'a M,
            block_number: BlockNumber,
            epoch_number_with_fraction: EpochNumberWithFraction,
            parent_hash: Byte32,
        ) -> Self {
            let median_timestamps_cache = RefCell::new(LruCache::new(rtx.resolved_inputs.len()));
            SinceVerifier {
                rtx,
                block_median_time_context,
                block_number,
                epoch_number_with_fraction,
                parent_hash,
                median_timestamps_cache,
            }
        }
                                                                                                                            fn parent_median_time(&self, block_hash: &Byte32) -> u64 {
            let (_, _, parent_hash) = self
                .block_median_time_context
                .timestamp_and_parent(block_hash);
            self.block_median_time(&parent_hash)
        }
        
        fn block_median_time(&self, block_hash: &Byte32) -> u64 {
            if let Some(median_time) = self.median_timestamps_cache.borrow().get(block_hash) {
                return *median_time;
            }
            let median_time = self.block_median_time_context.block_median_time(block_hash);
            self.median_timestamps_cache
                .borrow_mut()
                .insert(block_hash.clone(), median_time);
            median_time
        }
        
        fn verify_absolute_lock(&self, since: Since) -> Result<(), Error> {
            if since.is_absolute() {
                match since.extract_metric() {
                    Some(SinceMetric::BlockNumber(block_number)) => {
                        if self.block_number < block_number {
                            return Err(TransactionError::Immature).into());
                        }
                    }
                    Some(SinceMetric::EpochNumberWithFraction(epoch_number_with_fraction)) => {
                        if self.epoch_number_with_fraction < epoch_number_with_fraction {
                            return Err(TransactionError::Immature).into());
                        }
                    }
                    Some(SinceMetric::Timestamp(timestamp)) => {
                        let tip_timestamp = self.block_median_time(&self.parent_hash);
                        if tip_timestamp < timestamp {
                            return Err(TransactionError::Immature).into());
                        }
                    }
                    None => {
                        return Err(TransactionError::InvalidSince).into());
                    }
                }
            }
            Ok(())
        }
        
        fn verify_relative_lock(&self, since: Since, cell_meta: &CellMeta) -> Result<(), Error> {
            if since.is_relative() {
                let info = match cell_meta.transaction_info {
                    Some(ref transaction_info) => Ok(transaction_info),
                    None => Err(TransactionError::Immature),
                }?;
                match since.extract_metric() {
                    Some(SinceMetric::BlockNumber(block_number)) => {
                        if self.block_number < info.block_number + block_number {
                            return Err(TransactionError::Immature).into());
                        }
                    }
                    Some(SinceMetric::EpochNumberWithFraction(epoch_number_with_fraction)) => {
                        let a = self.epoch_number_with_fraction.to_rational();
                        let b =
                            info.block_epoch.to_rational() + epoch_number_with_fraction.to_rational();
                        if a < b {
                            return Err(TransactionError::Immature).into());
                        }
                    }
                    Some(SinceMetric::Timestamp(timestamp)) => {
                        // pass_median_time(current_block) starts with tip block, which is the
                        // parent of current block.
                        // pass_median_time(input_cell's block) starts with cell_block_number - 1,
                        // which is the parent of input_cell's block
                        let cell_median_timestamp = self.parent_median_time(&info.block_hash);
                        let current_median_time = self.block_median_time(&self.parent_hash);
                        if current_median_time < cell_median_timestamp + timestamp {
                            return Err(TransactionError::Immature).into());
                        }
                    }
                    None => {
                        return Err(TransactionError::InvalidSince).into());
                    }
                }
            }
            Ok(())
        }
        
        pub fn verify(&self) -> Result<(), Error> {
            for (cell_meta, input) in self
                .rtx
                .resolved_inputs
                .iter()
                .zip(self.rtx.transaction.inputs()) {
                // ignore empty since
                let since: u64 = input.since().unpack();
                if since == 0 {
                    continue;
                }
                let since = Since(since);
                // check remain flags
                if !since.flags_is_valid() {
                    return Err(TransactionError::InvalidSince).into());
                }
                
                // verify time lock
                self.verify_absolute_lock(since)?;
                self.verify_relative_lock(since, cell_meta)?;
            }
            Ok(())
        }
    }
```
