---
Number: "0016"
Category: Informational
Status: Draft
Author: Dingwei Zhang
Organization: Nervos Foundation
Created: 2019-03-08
---

# CKB-Verification

## Abstract

This RFC describes ckb block data verification rules.

Verification rules are split into three categories in CKB implementation. `Header Verification`,  `Block Verification` and `Transaction Verification`.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.


## Specification

1. Header Verification

    1. proof-of-work verification

        The `seal` field in block header is miner's proof of work, it MUST satisfy the block's difficulty target. Cuckoo Cycle is the temporary proof-of-work function used in CKB testnet, a new hash function will be proposed and used in mainnet.

    2. number verification

        The `number` field in block header MUST equal parent’s block number incremented by one, the genesis block has a number of zero.

    3. block version verification

        The version field is for doing parallel soft forking deployments. Currently, block version MUST be zero.

    4. timestamp verification

        Timestamp (Unix’s time in milliseconds) of block timestamp MUST greater than the median timestamp of previous 11 blocks and less than the network-adjusted time + MAX_ALLOWED_FUTURE_TIME.

    5. epoch verification

        CKB has an difficulty adjustment mechanism, which is based on epochs.
        block header epoch number MUST equal to the number of ancestor epochs.
        The canonical difficulty of a block of header H is defined as D, the last epoch difficulty is define as D_last, the last epoch orphan rate is define as o_last, the orphan rate target is define as o:

            D = D0 if H = 0
            D = max(max(D0, D_last / 2), min(D_last * (o_last / o), D_last * 2))

        Note that D0 is the difficulty of the genesis.

2. Block Verification

   1. uniqueness verification

        All transactions and proposals included in one block MUST be diffirent.

   2. cellbase

      * Block MUST have exactly one cellbase.
      * cellbase MUST be the first transaction in block.
      * cellbase MUST contain a special input so called as null input which indicating reference nothing one, the input's script fill binary with current block number.
      * output capacity must less or equal than block reward. Block reward includes primary issuance, secondary issuance and transaction fees, according to RFC#0015.

   3. merkle_root

       * proposals_root: The Blake2b 256-bit hash of the root node of the [tree structure][2] populated with each transaction's proposal short id of the block.
       * transaction_root: The Blake2b 256-bit hash of the root node of the [tree structure][2] populated with each transaction id of the block.

        proposals_root and proposals_root of block header MUST equal results of calculation.

   4. transaction proposal rules

        Transaction must be proposed within consensus rules specify proposal window.

   5. uncles

      * uncles hash: The hash MUST match the [CFB][3] serialized uncles.
      * number: there are at most 2 uncles included in one block.
      * depth: we define uncle number H(u), block number H(b), uncle number MUST satisfy H(b) - m < H(u) < H(b). Currently, m = 8.
      * epoch: uncle MUST be the same epoch with block.
      * uniqueness: an uncle must be different from all uncles included in previous blocks and all other uncles included in the same block (non-double-inclusion).

   6. block size limit

        The block size MUST be less or equal than block size limit. The current block size limit is 10_000_000 bytes (10MB).

   7. proposals limit

        The amount of block proposals MUST be less or equal than proposals limit. The current proposals limit is 5_000.

   8. cycles limit

        The maximum cycles expenditure per block. The current cycles limit is 100_000_000.

3. Transaction Verification

    Cellbase transaction is excluded from following rules unless otherwise noted.

    1. transaction version verification

        The version field is for doing parallel soft forking deployments. Currently, transaction version MUST be zero.

    2. null verification

        A special input called as null input which indicating reference nothing, null input only allowed to appear in cellbase.

    3. empty inputs/outputs verification

        Transaction inputs or outputs MUST NOT be empty.

    4. capacity verification

       * Transaction capacity sum of inputs MUST greater or equal capacity sum of outputs.
       * Each output's occupied_capacity MUST less than or equal to specify capacity.

    5. input uniqueness verification

        All inputs included in transaction must be different.

    6. input/dep status verification

        All inputs and deps MUST be live cell.

    7. script verification

        Execution script in [CKB-VM][4], perform user-define validation rules.

    8. cellbase maturity verification

        For each input, if the referenced output transaction is cellbase, it must have at least CELLBASE_MATURITY confirmations, according to [RFC#0010][5].

    9. transaction since verification

        Transaction since MUST satisfy consensus rule according to [RFC#0017][6]

## References

1. https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0002-ckb/0002-ckb.md#42-cell

2. https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0006-merkle-tree/0006-merkle-tree.md#tree-struct

3. https://github.com/nervosnetwork/rfcs/pull/47

4. https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0003-ckb-vm

5. https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0010-cellbase-maturity-period

6. https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0017-tx-valid-since

[1]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0002-ckb/0002-ckb.md#42-cell
[2]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0006-merkle-tree/0006-merkle-tree.md#tree-struct
[3]: https://github.com/nervosnetwork/rfcs/pull/47
[4]: https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0003-ckb-vm
[5]: https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0010-cellbase-maturity-period
[6]: https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0017-tx-valid-since
