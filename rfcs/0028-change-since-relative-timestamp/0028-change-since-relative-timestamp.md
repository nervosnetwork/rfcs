---
Number: "0028"
Category: Standards Track
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-02-03
---

# Use input cell committing block timestamp as the start time for the relative timestamp in `since`

## Abstract

The document proposes a consensus change for transaction verification. When the `since` field of the transaction input uses a relative timestamp, the referenced cell committing block timestamp is used instead of the median timestamp.

This is a modification to RFC17, [Transaction Valid Since](../0017-tx-valid-since/0017-tx-valid-since.md).

## Motivation

The current consensus rule uses the median of the timestamps in the 37 blocks preceding the committing block of the referenced cell. The intention of using the median timestamp was to prevent miners from manipulating block timestamps in order to include more transactions. It is resource-consuming to get the median timestamp because it requires either getting 37 block headers or caching the median timestamp for each block.

It is safe to use the committing block timestamp as the start time for two reasons:

1. The timestamp in the block header has already been verified by the network, and it must exceed the median timestamp of the previous 37 blocks and be less than or equal to the current time plus 15 seconds. (See [RFC27](../0027-block-structure/0027-block-structure.md#timestamp-uint64))
2. The transaction that consumes a cell with the `since` requirement must wait until the cell is mature. During this waiting period, the transaction that created the cell has accumulated enough confirmations that it is difficult for the miner to manipulate it.

## Specification

When an input `since` field is present, and

* The `metric_flag` is block timestamp (10).
* The `relative_flag` is relative (1).

The transaction is mature when

```
MedianTimestamp ≥ StartTime + SinceValue
```

where

* `StartTime` is the block timestamp that commits the cell consumed by the input.
* `SinceValue` is the `value` part of the `since` field.
* `MedianTimestamp`
  * If the transaction is in a block, `MedianTimestamp` is the median timestamp of the previous 37 blocks preceding the block.
  * If the transaction is in the pool, `MedianTimestamp` is the median timestamp of the latest 37 blocks.

If the transaction is immature, the transaction verification fails.

The only change is `StartTime`, which was the median of the previous 37 blocks preceding the one that committed the consumed cell. Because the block timestamp must be larger than the median of its previous 37 blocks, the new consensus rule is more strict than the old rule. Transactions that are mature under the old rule may be immature under the new rule, but transactions that are mature under the new rule must also be mature under the old rule.

## Test Vectors

The following is an example of a mature transaction using the new rule, but an immature transaction using the old rule.

Assuming that:

* A transaction consumes a cell in block S and is about to be committed into block T with the since requirement that:
	* The `metric_flag` is block timestamp (10).
	* The `relative_flag` is relative (1).
	* The `value` is 600,000 (10 minutes).
* The median of the previous 37 blocks preceding block S is 10,000.
* The timestamp of block S is 20,000.
* The median of the previous 37 blocks preceding block T is 615,000.

In the old consensus rule, `StartTime` + `SinceValue` = 10,000 + 600,000 = 610,000, which is less than the `MedianTimestamp` 615,000, thus the transaction is mature.

But in the new rule, `StartTime` + `SinceValue` = 20,000 + 600,000 = 620,000 ≥ 615,000, so the transaction is still immature.

## Deployment

The deployment can be performed in two stages.

In the first stage, the new consensus rule will be activated from a specific epoch. Mainnet and testnet will use different epochs, whereas all other chains will use the new rule from epoch 0.

The second stage occurs after the fork is activated, after which, if the transactions in the old epochs all comply with the new rule, the old consensus rule will be removed and the new rule will take effect from the genesis block.

## Backward Compatibility

Because the new consensus rule is more strict than the old one, this proposal can be deployed via a soft fork.
