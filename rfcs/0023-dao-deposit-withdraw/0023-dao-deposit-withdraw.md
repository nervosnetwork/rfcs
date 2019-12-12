---
Number: "0023"
Category: Standards Track
Status: Proposal
Author: Jan Xie, Xuejie Xiao, Ian Yang
Organization: Nervos Foundation
Created: 2019-10-30
---

# Deposit and Withdraw in Nervos DAO

## Abstract

This document describes deposit and withdraw transaction in Nervos DAO.

Note: a `Common Gotchas` page is maintained at [here](https://github.com/nervosnetwork/ckb/wiki/Common-Gotchas#nervos-dao), including common and very important points you should be aware to use Nervos DAO well without losing CKBs. Please pay attention to this page even if you might want to skip some part of this RFC.

## Motivation

Nervos DAO is a smart contract, with which users can interact the same way as any smart contract on CKB. One function of Nervos DAO is to provide an dilution counter-measure for CKByte holders. By deposit in Nervos DAO, holders get proportional secondary rewards, which guarantee their holding are only affected by hardcapped primary issuance as in Bitcoin.

Holders can deposit their CKBytes into Nervos DAO at any time. Nervos DAO deposit is a time deposit with a minimum deposit period (counted in blocks). Holders can only withdraw after a full deposit period. If the holder does not withdraw at the end of the deposit period, those CKBytes should enter a new deposit period automatically, so holders' interaction with CKB could be minimized.

## Background

CKB's token issuance curve consists of two components:

- Primary issuance: Hardcapped issuance for miners, using the same issuance curve as Bitcoin, half at every 4 years.
- Secondary issuance: Constant issuance, the same amount of CKBytes will be issued at every epoch, which means secondary issuance rate approaches zero gradually over time. [Because epoch length is dynamically adjusted](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md), secondary issuance at every block is a variable. 

If there's only primary issuance but no secondary issuance in CKB, the total supply of CKBytes would have a hardcap and the issuance curve would be the exact same as Bitcoin. To counter the dilution effect caused by secondary issuance, CKBytes locked in Nervos DAO will get the proportion of secondary issuance equals to the locked CKByte's percentage in circulation.

For more information of Nervos DAO and CKB's economic model, please check [Nervos RFC #0015](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0015-ckb-cryptoeconomics/0015-ckb-cryptoeconomics.md).

## Deposit

Users can send a transaction to deposit CKBytes into Nervos DAO at any time. CKB includes a special Nervos DAO type script in the genesis block. To deposit to Nervos DAO, one simply needs to create any transaction containing new output cell with the following requirements:

- The type script of the created output cell must be set to the Nervos DAO script.
- The output cell must have 8 byte length cell data, filled with all zeros.

For convenience, a cell satisfying the above conditions will be called a `Nervos DAO deposit cell`. To obey CKB's script validation logic, one also needs to include a reference to Nervos DAO type script in the `cell_deps` part of the enclosing transaction. Notice there's no limit on the number of deposits completed in one transaction, more than one Nervos DAO deposit cell can be created in a single valid transaction.

## Withdraw

Users can send a transaction to withdraw deposited CKBytes from Nervos DAO at any time(but a locking period will be applied to determine when exactly the tokens can be withdrawed). The interest gained by a Nervos DAO cell will only be issued in the withdraw phase, this means for a transaction including Nervos DAO withdraw, the sum of capacities from all output cells might exceed the sum of capacities from all input cells. Unlike the deposit, withdraw is a 2-phase process:

- In phase 1, the first transaction transforms a `Nervos DAO deposit cell` into a `Nervos DAO withdrawing cell`.
- In phase 2, a second transaction will be used to withdraw tokens from Nervos DAO withdrawing cell.

### Withdraw Phase 1

Phase 1 is used to transform `Nervos DAO deposit cell` into `Nervos DAO withdrawing cell`, the purpose here, is to determine the duration a cell has been deposited into Nervos DAO. Once phase 1 transaction is included in CKB blockchain, the duration betwen `Nervos DAO deposit cell` and `Nervos DAO withdrawing cell` can then be used to calculate interests, as well as remaining lock period of the deposited tokens.

A phase 1 transaction should satisfying the following conditions:

- One or more Nervos DAO deposit cells should be included in the transaction as inputs.
- For each Nervos DAO deposit cell, the transaction should also include reference to its associated including block in `header_deps`, which will be used by Nervos DAO type script as the starting point of deposit.
- For a Nervos DAO deposit cell at input index `i`, a Nervos DAO withdrawing cell should be created at output index `i` with the following requirements:
    - The withdrawing cell should have the same lock script as the deposit cell
    - The withdrawing cell should have the same Nervos DAO type script as the deposit cell
    - The withdrawing cell should have the same capacity as the deposit cell
    - The withdrawing cell should also have 8 byte length cell data, but instead of 8 zero, the cell data part should store the block number of the deposit cell's including block. The number should be packed in 64-bit unsigned little endian integer format.
- The Nervos DAO type script should be included in the `cell_deps` of withdraw transaction.

Once this transaction is included in CKB, the user can start preparing phase 2 transaction.

### Withdraw Phase 2

Phase 2 transaction is used to withdraw deposited tokens together with interests from Nervos DAO. Notice unlike phase 1 transaction which can be sent at any time the user wish, the assembled phase 2 transaction here, will have a since field set to fulfill lock period requirements, so it might be possible that one can only generate a transaction first, but has to wait for some time before he/she can send the transaction to CKB.

A phase 2 transaction should satisfying the following conditions:

- One or more Nervos DAO withdrawing cells should be included in the transaction as inputs.
- For each Nervos DAO withdrawing cell, the transaction should also include the reference to its associated including block in `header_deps`, which will be used by Nervos DAO type script as the end point of deposit.
- For a Nervos DAO withdrawing cell at input index `i`, the user should locate the deposit block header, meaning the block header in which the original Nervos DAO deposit cell is included. With the deposit block header, 2 operations are required:
    - The deposit block header hash should be included in `header_deps` of current transaction
    - The index of the deposit block header hash in `header_deps` should be kept using 64-bit unsigned little endian integer format in the part belonging to input cell's type script of corresponding witness at index `i`. A separate RFC would explain current argument organization in the witness. An example will also show this process in details below.
- For a Nervos DAO withdrawing cell, the `since` field in the cell input should reflect the Nervos DAO cell's lock period requirement, which is 180 epoches. For example, if one deposits into Nervos DAO at epoch 5, he/she can only expect to withdraw Nervos DAO at epoch 185, 365, 545, etc. Notice the calculation of lock period is independent of the calculation of interest. It's totally valid to deposit at epoch 5, use a `withdraw block` at epoch 100, and use a `since` field at 185. Please refer to the [since RFC](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0017-tx-valid-since/0017-tx-valid-since.md) on how to represent valid epoch numbers, Nervos DAO type script only accepts absolute epoch numbers as since values now.
- The interest calculation logic is totally separate from the lock period calculation logic, we will explain the interest calculation logic in the next section.
- The Nervos DAO type script requires the sum of all input cells' capacities plus interests is larger or equaled to the sum of all output cells' capacities.
- The Nervos DAO type script should be included in the `cell_deps`.

As hinted in the above steps, it's perfectly possible to do multiple withdraws in one transaction. What's more, Nervos DAO doesn't limit the purpose of withdrawed tokens, it's also valid to deposit the newly withdrawed tokens again to Nervos DAO right away in the same transaction. In fact, one transaction can be used to freely mix all the following actions together:

1. Deposit tokens into Nervos DAO.
2. Transform some Nervos DAO deposit cells to Nervos DAO withdrawing cells.
3. Withdraw from other Nervos DAO withdrawing cells.

## Calculation

This section explains the calculation of Nervos DAO interest and relevant fields in the CKB block header.

CKB's block header has a special field named `dao` containing auxiliary information for Nervos DAO's use. Specifically, the following data are packed in a 32-byte `dao` field in the following order:

- `C_i` : the total issuance up to and including block `i`.
- `AR_i`: the current `accumulated rate` at block `i`. `AR_j / AR_i` reflects the CKByte amount if one deposit 1 CKB to Nervos DAO at block `i`, and withdraw at block `j`.
- `S_i`: the total secondary issuance up to and including block `i`.
- `U_i` : the total `occupied capacities` currently in the blockchain up to and including block `i`. Occupied capacity is the sum of capacities used to store all cells.

Each of the 4 values is stored as unsigned 64-bit little endian number in the `dao` field. To maintain enough precision `AR_i`  is stored as the original value multiplied by `10 ** 16` .

For a single block `i`, it's easy to calculate the following values:

- `p_i`: primary issuance for block `i`
- `s_i`: secondary issuance for block `i`
- `U_{in,i}` : occupied capacities for all input cells in block `i`
- `U_{out,i}` : occupied capacities for all output cells in block `i`
- `C_{in,i}` : total capacities for all input cells in block `i`
- `C_{out,i}` : total capacities for all output cells in block `i`
- `I_i` : the sum of all Nervos DAO interested 

In genesis block, the values are defined as follows:

- `C_0` : `C_{out,0}` - `C_{in,0}` + `p_0` + `s_0`
- `U_0` : `U_{out,0}` - `U_{in,0}`
- `S_0` : `s_0`
- `AR_0` : `10 ^ 16`

Then from the genesis block, the values for each succeeding block can be calculated in an induction way:

- `C_i` : `C_{i-1}` + `p_i` + `s_i`
- `U_i` : `U_{i-1}` + `U_{out,i}` - `U_{in,i}`
- `S_i` : `S_{i-1}` - `I_i` + `s_i` - floor( `s_i` * `U_{i-1}` / `C_{i-1}` )
- `AR_i` : `AR_{i-1}` + floor( `AR_{i-1}` * `s_i` / `C_{i-1}` )

With those values, it's now possible to calculate the Nervos DAO interest for a cell. Assuming a Nervos DAO cell is deposited at block `m` (also meaning the Nervos DAO deposit cell is included at block `m`), the user chooses to start withdrawing process from block `n` (meaning the Nervos DAO withdrawing cell is included at block `n`), the total capacity for the Nervos DAO cell is `c_t`, the occupied capacity for the Nervos DAO cell is `c_o`. The Nervos DAO interest is calculated with the following formula:

( `c_t` - `c_o` ) * `AR_n` / `AR_m` - ( `c_t` - `c_o` )

Meaning that the maximum total withdraw capacity one can get from this Nervos DAO input cell is:

( `c_t` - `c_o` ) * `AR_n` / `AR_m` + `c_o`

## Example

In this Nervos DAO example, it's assumed that the type script below is used to represent a Nervos DAO script:

    {
      "code_hash": "0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e",
      "args": "0x",
      "hash_type": "type"
    }

And the following OutPoint refers to cell containing NervosDAO script:

    {
      "out_point": {
        "tx_hash": "0x2d99f0718b29d200ed2e0ca562561f1c5a2b820402a3540e4a4e0070f21d5637",
        "index": "0x2"
      },
      "dep_type": "code"
    }

Note that each independent chain configuration might use different values here, it's always a good idea to check the chain configuration first to make sure the correct values are used.

The following transaction deposits 100 CKB into Nervos DAO:

    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0x234d0b79c7b2e2b23bd691838bf985ed0503984d9e9a37e232ef1cbb27f78e3e",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        },
        {
          "out_point": {
            "tx_hash": "0x2d99f0718b29d200ed2e0ca562561f1c5a2b820402a3540e4a4e0070f21d5637",
            "index": "0x2"
          },
          "dep_type": "code"
        }
      ],
      "header_deps": [],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0xfded18e32bfab3f15e6887021cd12e2428c95c024e5190507e99f4d3d4dca558",
            "index": "0x0"
          },
          "since": "0x0"
        }
      ],
      "outputs": [
        {
          "capacity": "0x2cb417800",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x3c699fa525ccd12d8c3bf60557a89fb4f67065a0",
            "hash_type": "type"
          },
          "type": {
            "code_hash": "0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e",
            "args": "0x",
            "hash_type": "type"
          }
        },
        {
          "capacity": "0x2d1afd18ae",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x3c699fa525ccd12d8c3bf60557a89fb4f67065a0",
            "hash_type": "type"
          },
          "type": null
        }
      ],
      "outputs_data": [
        "0x0000000000000000",
        "0x"
      ],
      "witnesses": [
        "0x32e24489fee6fbc71fe0c666a3317a433fdf31984e4c2785a75efde36906c0a6537fe356e4b7970435c569149ce9f4868ae264218cdc1a75be398d2d22aa364800"
      ],
      "hash": "0x5104f7af12799eb9b1049e89cdc4118f1ac2a78438a49eba5dc729a83f0f5f7d"
    }

Assume this transaction is include in the following block:

    {
      "compact_target": "0x20038e38",
      "hash": "0x3553c12dc0c2ba432ede6900c0187c86eececdc748a7244d48df789ad7e2d8f0",
      "number": "0x662",
      "parent_hash": "0xb1ffb12b877d55ef2c475f2796b3d00f803327bf879f503923d60f02f331aaf4",
      "nonce": "0xc5cdda926b67c8871853c3daa58ef094",
      "timestamp": "0x16debf8fc1b",
      "transactions_root": "0xb0a1ae20895e2808db7e407bfb4c6fc0e0e1f9082d2a36085791e01d319113fd",
      "proposals_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "uncles_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "version": "0x0",
      "epoch": "0x708027a000001",
      "dao": "0x936bfda6bfb608008527f42b60d82400ea0bfcc9b53d0000004de839667e0100"
    }

As mentioned above, `dao` field here contains 4 fields, `AR` is the second field in the list, extracting the little endian integer from offset `8` through offset `16`, the current deposit `AR` is `10371006727464837`, which is `1.0371006727464837` considering `AR` is stored with the original value multiplied by `10 ** 16` .

The following transaction, can then be used to start phase 1 of withdrawing process, which transforms Nervos DAO deposit cell to Nervos DAO withdrawing cell:

    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0x234d0b79c7b2e2b23bd691838bf985ed0503984d9e9a37e232ef1cbb27f78e3e",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        },
        {
          "out_point": {
            "tx_hash": "0x2d99f0718b29d200ed2e0ca562561f1c5a2b820402a3540e4a4e0070f21d5637",
            "index": "0x2"
          },
          "dep_type": "code"
        }
      ],
      "header_deps": [
        "0x3553c12dc0c2ba432ede6900c0187c86eececdc748a7244d48df789ad7e2d8f0"
      ],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0x5104f7af12799eb9b1049e89cdc4118f1ac2a78438a49eba5dc729a83f0f5f7d",
            "index": "0x0"
          },
          "since": "0x0"
        }
      ],
      "outputs": [
        {
          "capacity": "0x2cb417800",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x3c699fa525ccd12d8c3bf60557a89fb4f67065a0",
            "hash_type": "type"
          },
          "type": {
            "code_hash": "0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e",
            "args": "0x",
            "hash_type": "type"
          }
        }
      ],
      "outputs_data": [
        "0x6206000000000000",
        "0x"
      ],
      "witnesses": [
        "0x4ccd462166d99340cb98d2630e813a6c507aba3fc9895f347116baa43813923219e5f7b7a46355ff4e4f39f7803aaabfc916072d79914c363a4cc30a2db64fe700"
      ],
      "hash": "0x120ce30560ceef8c4825dac108511ccf2736d84af76dbbc974fa879722405673"
    }

There're couple of important points worth mentioning in this transaction:

- The input Nervos DAO deposit cell is included in `0x3553c12dc0c2ba432ede6900c0187c86eececdc748a7244d48df789ad7e2d8f0` block, hence it is included in `header_deps`.
- The including block number is `1634`, which is `0x6206000000000000` packed in 64-bit unsigned little endian integer number also in HEX format.
- Looking at the above 2 transactions together, the output cell in this transaction has the same lock, type and capacity as previous Nervos DAO deposit cell, while uses a different cell data.

Assume this transaction is included in the following block:

    {
      "compact_target": "0x1f71c71c",
      "hash": "0x460884f23454f885fad82f5bdcf74c76c66c0c90ac1791031a4acdb998c1e388",
      "number": "0x1c34",
      "parent_hash": "0xd0a78fd2bf4de5e2e1f1b2bde659f7d30b1f478365040e5050051fe394662fb1",
      "nonce": "0xaa3955169344d1fc98d8f2ee422d4736",
      "timestamp": "0x16dec12e95b",
      "transactions_root": "0x299bf1b6ddf638472b9823c663218d283a63e73ca1126d32269a670f553dc7d3",
      "proposals_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "uncles_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "version": "0x0",
      "epoch": "0x7080334000004",
      "dao": "0x228720f541810b00b9ff658ba3692700c41ace8c2bd00000001756d6639d0100"
    }

The following phase 2 transaction can finally be used to withdraw tokens from Nervos DAO:

    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0x234d0b79c7b2e2b23bd691838bf985ed0503984d9e9a37e232ef1cbb27f78e3e",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        },
        {
          "out_point": {
            "tx_hash": "0x2d99f0718b29d200ed2e0ca562561f1c5a2b820402a3540e4a4e0070f21d5637",
            "index": "0x2"
          },
          "dep_type": "code"
        }
      ],
      "header_deps": [
        "0x3553c12dc0c2ba432ede6900c0187c86eececdc748a7244d48df789ad7e2d8f0",
        "0x460884f23454f885fad82f5bdcf74c76c66c0c90ac1791031a4acdb998c1e388"
      ],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0x120ce30560ceef8c4825dac108511ccf2736d84af76dbbc974fa879722405673",
            "index": "0x0"
          },
          "since": "0x200708027a0000b5"
        }
      ],
      "outputs": [
        {
          "capacity": "0x2d2bb54db",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x3c699fa525ccd12d8c3bf60557a89fb4f67065a0",
            "hash_type": "type"
          },
          "type": {
            "code_hash": "0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e",
            "args": "0x",
            "hash_type": "type"
          }
        }
      ],
      "outputs_data": [
        "0x6206000000000000",
        "0x"
      ],
      "witnesses": [
        "0x787c286118988258844017b0a77a038cdb71e4d441f19d172edf74f882553e9e7c7958b87974ed0d2569f233eb044cd4179d1b936aae63cdeceaafec38f33377000000000000000000"
      ],
      "hash": "0x24b76688a4d532271a55d99e80b59ca65f6fbb86567ff9a2071158f26533f287"
    }

There're couple of important points worth mentioning in this transaction:

- The `header_deps` in this transaction contains 2 headers: `0x3553c12dc0c2ba432ede6900c0187c86eececdc748a7244d48df789ad7e2d8f0` contains block header hash in which the original Nervos DAO deposit cell is included, while `0x460884f23454f885fad82f5bdcf74c76c66c0c90ac1791031a4acdb998c1e388` is the block in which the Nervos DAO withdrawing cell is included.
- Since `0x3553c12dc0c2ba432ede6900c0187c86eececdc748a7244d48df789ad7e2d8f0` is at index 0 in `header_deps`. The number `0` will be packed in 64-bit little endian unsigned integer, which is `0000000000000000`, and appended to the end of the witness corresponding with the Nervos DAO input cell.
- The Nervos DAO input cell has a `since` field of `0x200708027a0000b5`, this is calculated as follows:
    - The deposit block header has an epoch value of `0x708027a000001`, which means the `1 + 634 / 1800` epoch
    - The block header in which withdrawing cell is included has an epoch value of `0x7080334000004`, which means the `4 + 820 / 1800` epoch
    - The closest epoch that is past `4 + 820 / 1800` but still satisfies lock period is `181 + 634 / 1800` epoch, which in the correct format, is `0x708027a00000b5`.
    - Since absolute epoch number is used in the since field, necessary flags are needed to make the value `0x200708027a0000b5`. Please refer to since RFC for more details on the format here.

Using the same calculation as above, the `AR` for the withdraw block `0x460884f23454f885fad82f5bdcf74c76c66c0c90ac1791031a4acdb998c1e388` is `1.10936752310189367`.

Now the maximum capacity that can be withdrawed from the above NervosDAO input cell can be calculated:

`total_capacity` = 12000000000
`occupied_capacity` = 10200000000 (8 CKB for capacity, 53 bytes for lock script, 33 bytes for type script, the sum of those is 94 bytes, which is exactly 9400000000 shannons)
`counted_capacity` = 12000000000 - 10200000000 = 1800000000
`maximum_withdraw_capacity` = 1800000000 * 11093675231018937 / 10371006727464837 + 10200000000 = 12125426907 = 0x2d2bb54db

`0x2d2bb54db` here is exactly the capacity for the output cell in the above transaction.
