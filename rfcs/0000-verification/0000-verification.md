---
Number: ""
Category: Informational
Status: Draft
Author: Dingwei Zhang
Organization: Nervos Foundation
Created: 2019-03-08
---

# CKB-Verification

## Abstract

This RFC describes ckb block data verification rules.

Verification rules are split into three part in CKB implementation. `Header Verification`,  `Block Verification` and `Transaction Verification`.

## Specification

1. Header Verification

    1. proof-of-work verification

        Block to be valid it must hash to a value less than the current target. current hash algorithm is Cuckoo Cycle.

    2. number verification

        CKB block header contain block number, it MUST equal parent’s block number incremented by one, the genesis block has a number of zero.

    3. block version verification

        Block version MUST obey consensus rules.

    4. timestamp verification

        Timestamp (Unix’s time in milliseconds) of block timestamp MUST greater than the median timestamp of previous 11 blocks and less than the network-adjusted time + 15 seconds.

    5. difficulty verification

        The canonical difficulty of a block of header is defined as Diff == Max(Diff_last * o_last / o, Diff_last * 2) (o: orphan rate), It MUST greater or equal genesis' difficulty.

1. Block Verification

   1. empty transactions verification

        Block transactions MUST not be empty.

   2. duplicate

        Block transactions MUST be uniqueness.

   3. cellbase

      * position: cellbase MUST be the first transaction in block.
      * input: cellbase MUST contain one null input, the input's script fill binary with current block number.
      * output_capacity must less or equal consensus rules specify block reward.

   4. merkle_root

        Verify transaction [merkle-proof][1].

   5. transaction proposal rules

        Commit transaction must be proposed within consensus rules specify proposal window.

   6. uncles

      * uncles hash: The hash MUST match the [CFB][2] serialized uncles.
      * number: there are at most 2 uncles included in one block.
      * depth: an uncle must be the k-th generation ancestor of Block, where 2 <= k <= 7.
      * epoch: uncle must be the same epoch with block.
      * uniqueness: an uncle must be different from all uncles included in previous blocks and all other uncles included in the same block (non-double-inclusion).

   7. block size limit

        The maximum size in bytes that the consensus rules allow a block to be. The current block size limit is 10_000_000 bytes(10MB).

   8. cycles limit

        The maximum cycles expenditure per block. The current cycles limit is 100_000_000.

2. Transaction Verification

    Below transaction verification rules description exclude cellbase by default.

    1. transaction version verification

        Transaction version MUST obey consensus rules.

    2. null verification

        All transaction inputs MUST not be null.

    3. empty inputs/outputs verification

        Transaction inputs or outputs MUST not empty.

    4. capacity verification

       * Transaction capacity sum of inputs MUST greater or equal capacity sum of outputs.
       * All outputs' occupied_capacity MUST less than specify capacity.

    5. input uniqueness verification

        Input must be uniqueness.

    6. input/dep status verification

        All inputs and deps MUST be live cell.

    7. script verification

        Execution script in CKB-VM, perform user-define validation rules.


[1]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0006-merkle-tree/0006-merkle-tree.md#merkle-proof
[2]: https://github.com/nervosnetwork/rfcs/pull/47
