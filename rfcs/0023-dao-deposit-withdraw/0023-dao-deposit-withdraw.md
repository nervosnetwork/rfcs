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

Note: a `Common Gotchas` page is maintained at [here](https://github.com/nervosnetwork/ckb/wiki/Common-Gotchas#nervos-dao), including common and very important points you should be aware to use Nervos DAO well without losing CKBs. Please pay attention to this page even if you might want to skip some parts of this RFC.

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

Users can send a transaction to withdraw deposited CKBytes from Nervos DAO at any time(but a locking period will be applied to determine when exactly the tokens can be withdrawed). The compensation gained by a Nervos DAO cell will only be issued in the withdraw phase, this means for a transaction including Nervos DAO withdraw, the sum of capacities from all output cells might exceed the sum of capacities from all input cells. Unlike the deposit, withdraw is a 2-phase process:

- In phase 1, the first transaction transforms a `Nervos DAO deposit cell` into a `Nervos DAO withdrawing cell`.
- In phase 2, a second transaction will be used to withdraw tokens from Nervos DAO withdrawing cell.

### Withdraw Phase 1

Phase 1 is used to transform `Nervos DAO deposit cell` into `Nervos DAO withdrawing cell`, the purpose here, is to determine the duration a cell has been deposited into Nervos DAO. Once phase 1 transaction is included in CKB blockchain, the duration betwen `Nervos DAO deposit cell` and `Nervos DAO withdrawing cell` can then be used to calculate compensation, as well as remaining lock period of the deposited tokens.

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

Phase 2 transaction is used to withdraw deposited tokens together with compensation from Nervos DAO. Notice unlike phase 1 transaction which can be sent at any time the user wish, the assembled phase 2 transaction here, will have a since field set to fulfill lock period requirements, so it might be possible that one can only generate a transaction first, but has to wait for some time before he/she can send the transaction to CKB.

A phase 2 transaction should satisfying the following conditions:

- One or more Nervos DAO withdrawing cells should be included in the transaction as inputs.
- For each Nervos DAO withdrawing cell, the transaction should also include the reference to its associated including block in `header_deps`, which will be used by Nervos DAO type script as the end point of deposit.
- For a Nervos DAO withdrawing cell at input index `i`, the user should locate the deposit block header, meaning the block header in which the original Nervos DAO deposit cell is included. With the deposit block header, 2 operations are required:
    - The deposit block header hash should be included in `header_deps` of current transaction
    - The index of the deposit block header hash in `header_deps` should be kept using 64-bit unsigned little endian integer format in the part belonging to input cell's type script of corresponding witness at index `i`. A separate RFC would explain current argument organization in the witness. An example will also show this process in details below.
- For a Nervos DAO withdrawing cell, the `since` field in the cell input should reflect the Nervos DAO cell's lock period requirement, which is 180 epoches. For example, if one deposits into Nervos DAO at epoch 5, he/she can only expect to withdraw Nervos DAO at epoch 185, 365, 545, etc. Notice the calculation of lock period is independent of the calculation of compensation. It's totally valid to deposit at epoch 5, use a `withdraw block` at epoch 100, and use a `since` field at 185. Please refer to the [since RFC](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0017-tx-valid-since/0017-tx-valid-since.md) on how to represent valid epoch numbers, Nervos DAO type script only accepts absolute epoch numbers as since values now.
- The compensation calculation logic is totally separate from the lock period calculation logic, we will explain the compensation calculation logic in the next section.
- The Nervos DAO type script requires the sum of all input cells' capacities plus compensation is larger or equaled to the sum of all output cells' capacities.
- The Nervos DAO type script should be included in the `cell_deps`.

As hinted in the above steps, it's perfectly possible to do multiple withdraws in one transaction. What's more, Nervos DAO doesn't limit the purpose of withdrawed tokens, it's also valid to deposit the newly withdrawed tokens again to Nervos DAO right away in the same transaction. In fact, one transaction can be used to freely mix all the following actions together:

1. Deposit tokens into Nervos DAO.
2. Transform some Nervos DAO deposit cells to Nervos DAO withdrawing cells.
3. Withdraw from other Nervos DAO withdrawing cells.

## Calculation

This section explains the calculation of Nervos DAO compensation and relevant fields in the CKB block header.

CKB's block header has a special field named `dao` containing auxiliary information for Nervos DAO's use. Specifically, the following data are packed in a 32-byte `dao` field in the following order:

- `C_i` : the total issuance up to and including block `i`.
- `AR_i`: the current `accumulated rate` at block `i`. `AR_j / AR_i` reflects the CKByte amount if one deposit 1 CKB to Nervos DAO at block `i`, and withdraw at block `j`.
- `S_i`: the total unissued secondary issuance up to and including block `i`, including unclaimed Nervos DAO compensation and treasury funds.
- `U_i` : the total `occupied capacities` currently in the blockchain up to and including block `i`. Occupied capacity is the sum of capacities used to store all cells.

Each of the 4 values is stored as unsigned 64-bit little endian number in the `dao` field. To maintain enough precision `AR_i`  is stored as the original value multiplied by `10 ** 16` .

For a single block `i`, it's easy to calculate the following values:

- `p_i`: primary issuance for block `i`
- `s_i`: secondary issuance for block `i`
- `U_{in,i}` : occupied capacities for all input cells in block `i`
- `U_{out,i}` : occupied capacities for all output cells in block `i`
- `C_{in,i}` : total capacities for all input cells in block `i`
- `C_{out,i}` : total capacities for all output cells in block `i`
- `I_i` : total withdrawed Nervos DAO compensation in block `i` (not includes withdrawing compensation)

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

With those values, it's now possible to calculate the Nervos DAO compensation for a deposited cell. Assuming a Nervos DAO cell is deposited at block `m` (also meaning the Nervos DAO deposit cell is included at block `m`), the user chooses to start withdrawing process from block `n` (meaning the Nervos DAO withdrawing cell is included at block `n`), the total capacity for the Nervos DAO cell is `c_t`, the occupied capacity for the Nervos DAO cell is `c_o`. The Nervos DAO compensation is calculated with the following formula:

( `c_t` - `c_o` ) * `AR_n` / `AR_m` - ( `c_t` - `c_o` )

Meaning that the maximum total withdraw capacity one can get from this Nervos DAO input cell is:

( `c_t` - `c_o` ) * `AR_n` / `AR_m` + `c_o`

## Example

The following type script represents the Nervos DAO script on CKB mainnet:

    {
      "code_hash": "0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e",
      "args": "0x",
      "hash_type": "type"
    }

And the following OutPoint refers to cell containing NervosDAO script:

    {
      "out_point": {
        "tx_hash": "0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c",
        "index": "0x2"
      },
      "dep_type": "code"
    }

The following transaction deposits 100 CKB into Nervos DAO:

    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        },
        {
          "out_point": {
            "tx_hash": "0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c",
            "index": "0x2"
          },
          "dep_type": "code"
        }
      ],
      "header_deps": [],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0xeb4644164c4dc64f195bb3b0c6e4f417e11519b1931e5f7177ff8008d96dbe83",
            "index": "0x1"
          },
          "since": "0x0"
        }
      ],
      "outputs": [
        {
          "capacity": "0x2e90edd000",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0xe5f99902495d04d9dcb013aefc96093d365b77dc",
            "hash_type": "type"
          },
          "type": {
            "code_hash": "0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e",
            "args": "0x",
            "hash_type": "type"
          }
        },
        {
          "capacity": "0x101db898cb1",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x9776eaa16af9cd8b6a2d169ae95671b0bcb8b0c4",
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
        "0x5500000010000000550000005500000041000000c22c72efb85da607ac48b220ad5b7132dc7abe50c3337c9a51e75102e8efaa5557e8b0567f9e0d9753016ebd52be3091bd55d4b87d7d4845f0d56ccf06e6ffe400"
      ],
      "hash": "0x81c400a761b0b5f1d8b00d8939e5a729d21d25a08e14e54f0661cb4f6fc6fb81"
    }

This transaction is actually committed in the following block:

    {
      "compact_target": "0x1a2158d9",
      "hash": "0x37ef8cf2407044d74a71f927a7e3dcd3be7fc5e7af0925c0b685ae3bedeec3bc",
      "number": "0x105f",
      "parent_hash": "0x36990fe91a0ee3755fd6faaa2563349425b56319f06aa70d2846af47e3132262",
      "nonce": "0x19759fb43000000000000000b28a9573",
      "timestamp": "0x16e80172dbf",
      "transactions_root": "0x66866dcfd5426b2bfeecb3cf4ff829d353364b847126b2e8d2ce8f8aecd28fb8",
      "proposals_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "uncles_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "version": "0x0",
      "epoch": "0x68d0288000002",
      "dao": "0x8268d571c743a32ee1e547ea57872300989ceafa3e710000005d6a650b53ff06"
    }

As mentioned above, `dao` field here contains 4 fields, `AR` is the second field in the list, extracting the little endian integer from offset `8` through offset `16`, the current deposit `AR` is `10000435847357921`, which is `1.0000435847357921` considering `AR` is stored with the original value multiplied by `10 ** 16` .

The following transaction, can then be used to start phase 1 of withdrawing process, which transforms Nervos DAO deposit cell to Nervos DAO withdrawing cell:

    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        },
        {
          "out_point": {
            "tx_hash": "0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c",
            "index": "0x2"
          },
          "dep_type": "code"
        }
      ],
      "header_deps": [
        "0x37ef8cf2407044d74a71f927a7e3dcd3be7fc5e7af0925c0b685ae3bedeec3bc"
      ],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0x81c400a761b0b5f1d8b00d8939e5a729d21d25a08e14e54f0661cb4f6fc6fb81",
            "index": "0x0"
          },
          "since": "0x0"
        },
        {
          "previous_output": {
            "tx_hash": "0x043639b6aedcd0d897583e3d056e5a9c4875538533733818aca31fbeabfd5fba",
            "index": "0x1"
          },
          "since": "0x0"
        }
      ],
      "outputs": [
        {
          "capacity": "0x2e90edd000",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0xe5f99902495d04d9dcb013aefc96093d365b77dc",
            "hash_type": "type"
          },
          "type": {
            "code_hash": "0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e",
            "args": "0x",
            "hash_type": "type"
          }
        },
        {
          "capacity": "0x179411d65",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x5df75f10330a05ec9f862dec9bb37b5e11171475",
            "hash_type": "type"
          },
          "type": null
        }
      ],
      "outputs_data": [
        "0x5f10000000000000",
        "0x"
      ],
      "witnesses": [
        "0x5500000010000000550000005500000041000000d952a9b844fc441529dd310e49907cc5eba009dcf0fcd7a5fb1394017c29b90b7c68e1d0db52c67d444accec4c04670d197630656837b33d07f0cbdd1f33907d01",
        "0x5500000010000000550000005500000041000000d8e77676d57742b9b1e3a47e53f023ade294af5ca501f33406e992af01b1d0dd4a4f22d478c9497b184b04ea56c4ce71fccd9f0d4c25f503324edff5f2b26f0d00"
      ],
      "hash": "0x9ab05d622dc6d9816f70094242740cca594e677009b88c3f2b367d8b32f928fd"
    }

There're couple of important points worth mentioning in this transaction:

- The input Nervos DAO deposit cell is included in `0x37ef8cf2407044d74a71f927a7e3dcd3be7fc5e7af0925c0b685ae3bedeec3bc` block, hence it is included in `header_deps`.
- The including block number is `4191`, which is `0x5f10000000000000` packed in 64-bit unsigned little endian integer number also in HEX format.
- Looking at the above 2 transactions together, the output cell in this transaction has the same type and capacity as previous Nervos DAO deposit cell, while uses a different cell data.

Assume this transaction is included in the following block:

    {
      "compact_target": "0x1a2dfb48",
      "hash": "0xba6eaa7e0acd0dc78072c5597ed464812391161f0560c35992ae0c96cd1d6073",
      "number": "0x11ea4",
      "parent_hash": "0x36f16c9a1abea1cb44bc1d923feb9f62ff45b9327188dca954968dfdecc03bd0",
      "nonce": "0x74e39f370400000000000000bb4b3299",
      "timestamp": "0x16ea78c300f",
      "transactions_root": "0x4efccc5beeeae3847aa65f2e987947957d68f13687af069f52be361d0648feb8",
      "proposals_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "uncles_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
      "version": "0x0",
      "epoch": "0x645017e00002f",
      "dao": "0x77a7c6ea619acb2e4b841a96c88e2300b6b274a096c1080000ea07db0efaff06"
    }

The following phase 2 transaction can finally be used to withdraw tokens from Nervos DAO:

    {
      "version": "0x0",
      "cell_deps": [
        {
          "out_point": {
            "tx_hash": "0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c",
            "index": "0x0"
          },
          "dep_type": "dep_group"
        },
        {
          "out_point": {
            "tx_hash": "0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c",
            "index": "0x2"
          },
          "dep_type": "code"
        }
      ],
      "header_deps": [
        "0x37ef8cf2407044d74a71f927a7e3dcd3be7fc5e7af0925c0b685ae3bedeec3bc",
        "0xba6eaa7e0acd0dc78072c5597ed464812391161f0560c35992ae0c96cd1d6073"
      ],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0x9ab05d622dc6d9816f70094242740cca594e677009b88c3f2b367d8b32f928fd",
            "index": "0x0"
          },
          "since": "0x20068d02880000b6"
        }
      ],
      "outputs": [
        {
          "capacity": "0x2e9a2ed603",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x89e1914565e6fcc74e36d6c7bec4bdfa222b3a25",
            "hash_type": "type"
          },
          "type": null
        }
      ],
      "outputs_data": [
        "0x"
      ],
      "witnesses": [
        "0x61000000100000005500000061000000410000006114fee94f91ed089a32df9c3b0cda0ca1e1e97879d0aae253d0785fc6f7019b20cccbc7ea338ea96e64172f4a810ef531ab5ca1570a9742f0fb23378e260d9f01080000000000000000000000"
      ],
      "hash": "0x1c375948bae003ef1a9e86e6b049199480987d7dcf96bdfa2a914ecd4dadd42b"
    }

There're couple of important points worth mentioning in this transaction:

- The `header_deps` in this transaction contains 2 headers: `0x37ef8cf2407044d74a71f927a7e3dcd3be7fc5e7af0925c0b685ae3bedeec3bc` contains block header hash in which the original Nervos DAO deposit cell is included, while `0xba6eaa7e0acd0dc78072c5597ed464812391161f0560c35992ae0c96cd1d6073` is the block in which the Nervos DAO withdrawing cell is included.
- Since `0x37ef8cf2407044d74a71f927a7e3dcd3be7fc5e7af0925c0b685ae3bedeec3bc` is at index 0 in `header_deps`. The number `0` will be packed in 64-bit little endian unsigned integer, which is `0000000000000000`, and appended to the end of the witness corresponding with the Nervos DAO input cell.
- The Nervos DAO input cell has a `since` field of `0x20068d02880000b6`, this is calculated as follows:
    - The deposit block header has an epoch value of `0x68d0288000002`, which means the `2 + 648 / 1677` epoch
    - The block header in which withdrawing cell is included has an epoch value of `0x645017e00002f`, which means the `47 + 382 / 1605` epoch
    - The closest epoch that is past `47 + 382 / 1605` but still satisfies lock period is `182 + 648 / 1677` epoch, which in the correct format, is `0x68d02880000b6`.
    - Since absolute epoch number is used in the since field, necessary flags are needed to make the value `0x20068d02880000b6`. Please refer to since RFC for more details on the format here.

Using the same calculation as above, the `AR` for the withdrawing block `0xba6eaa7e0acd0dc78072c5597ed464812391161f0560c35992ae0c96cd1d6073` is `1.0008616347796555`.

Now the maximum capacity that can be withdrawed from the above NervosDAO input cell can be calculated:

`total_capacity` = 200000000000
`occupied_capacity` = 10200000000 (8 bytes for capacity, 53 bytes for lock script, 33 bytes for type script and another 8 bytes for cell data part are needed cost, the sum of those is 102 bytes, which is exactly 10200000000 shannons)
`counted_capacity` = 200000000000 - 10200000000 = 189800000000
`maximum_withdraw_capacity` = 189800000000 * 10008616347796555 / 10000435847357921 + 10200000000 = 200155259131

200155259131 is hence the maximum capacity that can be withdrawed. The transaction has one output containing 0x2e9a2ed603 = 200155256323, it also pays a transaction fee of 2808 shannons. It's now trivial to test 200155259131 = 200155256323 + 2808, which validates the math here.
