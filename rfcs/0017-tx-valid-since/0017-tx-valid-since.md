---
Number: "0017"
Category: Standards Track
Status: Active
Author: Jinyang Jiang <@jjyr>, Ian Yang <@doitian>
Created: 2019-03-11
---

# Transaction Since Precondition

<!-- Diagrams are created in LucidChart: https://lucid.app/documents/view/d756089a-2388-4ea4-b61a-3943cbe2620a -->

## Abstract

This RFC suggests adding a consensus rule to restrict committing a transaction before a certain time. The time comes from the block headers in the chain via block number, epoch number with fraction, or block timestamp.

## Summary

The new consensus rule allows the transaction input to optionally specify a since precondition. CKB nodes must verify the transactions in the commitment zone of a block that all of the input since preconditions are fulfilled.

The since precondition locates a unique block in any given chain if it is long enough. The precondition is effective before the block, and is fulfilled since the block.

There are three metrics to specify the since precondition:

1. via block number,
2. epoch number with fraction,
3. or the median timestamp of the preceding 37 blocks.

All of them strictly increase along the block number.

The precondition is absolute or relative. A relative precondition depends on which block has commit the input.

In conclusion, the since precondition is a per input threshold value with a specific metric, either absolute or relative to the input commitment block. The precondition prevents a block committing the transaction if the derived metric value from the block has not reached the since precondition threshold yet. 

## Specification

### How to Specify the Since Precondition

The per input field `since` is an unsigned 64-bit integer which encodes the since precondition.[^1] The value 0 indicates that the precondition is absent. Otherwise, the highest 8 bits of the `since` field is the `flags`, and the remaining `56` bits represent the `value`.

[^1]: See [RFC22][../rfcs/0022-transaction-structure/0022-transaction-structure.md] for the full transaction structure.

![](since-encoding.jpg)

* The highest bit is the relative flag.
    * `0`: The `value` is absolute
    * `1`: The `value` is relative
* The following two bits choose which metric to specify the precodition. It is also the unit of the `value`.
    * `00`: Use block number.
    * `01`: Use epoch number with fraction.
    * `10`: Use the timestamp median of previous 37 block headers.
    * `11`: Invalid. Transaction should not set metric flag to `11`.
* The next 5 bits are reserved for future extension. They must be set to all zeros now.

How the `value` is encoded depends on the metric in use.

For block number (`00`) and timestamp median (`10`), `value` is a 56-bit unsigned integer.

When the metric flag is `01`, `value` represents a rational number `E + I / L`, where

* `E` has 3 bytes from the lowest bit 0 to 23.
* `I` has 2 bytes from the bit 24 to 39.
* `L` has 2 bytes from the bit 40 to 55.

Following table shows how to decode different parts of `since` using bit operations right shift (`>>`), left shift (`<<`), and bit and (`&`).

| Name | Bit Operation |
| ---- | ------------- |
| relative flag | `since >> 63` |
| metric flag   | `(since >> 61) & 3` |
| value         | `since & ((1 << 56) - 1)` |
| `E` in value  | `since & ((1 << 24) - 1)` |
| `I` in value  | `(since >> 24) & ((1 << 16) - 1)` |
| `L` in value  | `(since >> 40) & ((1 << 16) - 1)` |

### How to Verify the Since Precondition

There are three major steps to verify the since precondition:

1. Decode: Decode since and verify the format is valid.
2. Compute Threshold: Determine the commitment block and compute the threshold for relative since precondition.
3. Derive and Compare: Derive the target value from the block that is going to commit the transaction. Compare it with threshold to check whether the precondition is fulfilled.

Following is the flow chart of the verification process.

![](since-verification.jpg)

#### Step 1. Decode

> Decode since and verify the format is valid.

If the since field is zero, skip current input since precondition verification. Otherwise, verify that the format is valid:

1. The metric flag should not be `11`.
2. The reserved flags must be all zeros.
3. When the metric flag is epoch number with fraction (`01`), `I` must be either less than `L`, or they are both zeros. If the latter is the case, the since value is `E + 0 / 1`.

Continue the next two steps when the since field format is valid.

#### Step 2. Compute Threshold

> Determine the commitment block and compute the threshold for relative since precondition.

The threshold value is the decoded since value for the absolute precondition.

The relative precondition threshold depends on the commitment block of the current transaction input.

The term "commit" comes from the two step transaction confirmation protocol in [RFC20][]. A block commits a transaction by including it in the commitment zone of the block body. The commitment block of a transaction is the block which has commit the transaction.

[RFC20]: ../0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md#two-step-transaction-confirmation

In CKB, the transaction input is a reference to an output of another transaction. The commitment block of a transaction input is the commitment block of the transaction producing the referenced output.

![](commitment-block.jpg)

For example, in the diagram above, the block B is the commitment block of input 0 of the transaction X.

The base value is from the input commitment block.

1. If the metric flag is `00` (block number), the base value is the block number of the commitment block.
2. If the metric flag is `01` (epoch number with fraction), the base value is the epoch field in the commitment block header, which is also a rational number.
3. If the metric flag is `10` (timestamp), the base value is the timestamp field in the commitment block header.

The threshold value of a relative precondition equals to the base value plus the decoded since value.

The diagram below is a summary of the threshold value computation process.

![](threshold-value.jpg)

#### Step 3. Derive and Compare

> Derive the target value from the block that is going to commit the transaction. Compare it with threshold to check whether the precondition is fulfilled.

This section will refer to the block that is going to commit the transaction as the target block.

The target block of a commit transaction is the block which has commit the transaction.

The target block of a transaction that is pending in the network or the memory pool, is the next to-be-mined block.

The target value does not depend on the fields in the target block headers to ensure that the target value is determined for both commit and pending transactions.

The target value is from the target block preceding blocks that:

1. If the metric flag is `00` (block number), the target value is the parent block number plus 1.
2. If the metric flag is `01` (epoch number with fraction), and the parent block epoch is `E + I / L`, the target value is `E + (I + 1) / L`.
3. If the metric flag is `10` (timestamp), the target value is the median of the timestamp field of the 37 blocks preceding the target block.

![](target-value.jpg)

The last step is comparing the threshold value and the target value. The precondition is fulfilled if the target value is larger than or equals to the threshold value.
