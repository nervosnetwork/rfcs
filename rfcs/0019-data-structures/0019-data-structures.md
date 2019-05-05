---
Number: "0019"
Category: Informational
Status: Draft
Author: Haichao Zhu, Xuejie Xiao
Organization: Nervos Foundation
Created: 2019-03-26
---

# Data Structures of Nervos CKB

This documents explains all the basic data structures used in CKB.

* [Cell](#Cell)
* [Script](#Script)
* [Transaction](#Transaction)
* [Block](#Block)



## Cell

### Example

```json
{
    "capacity": 500_000_000_000_000,
    "data": "0x",
    "lock": {
      "args": [],
      "code_hash": "0xa58a960b28d6e283546e38740e80142da94f88e88d5114d8dc91312b8da4765a"
    },
    "type": null
}
```

## Description

| Name       | Type       | Description                                                  |
| :--------- | :--------- | :----------------------------------------------------------- |
| `capacity` | uint64     | **The size of the cell (in shannons).** When a new cell is generated (via transaction), one of the verification rule is `capacity_in_bytes >= len(capacity) + len(data) + len(type) + len(lock)`. This value also represents the balance of CKB coin, just like the `nValue` field in the Bitcoin's CTxOut. (E.g. Alice owns 100 CKB coins means she can unlock a group of cells that has 100 amount of `bytes` (which is 10_000_000_000 amount of `shannons`) in total.) |
| `data`     | Bytes      | **Arbitrary data.** This part is for storing states or scripts.  In order to make this cell valid on-chain, the data filled in this field should comply with the logics and rules defined by `type`. |
| `type`     | `Script`   | **A Script that defines the type of the cell.** It limits how the `data` field of the new cells can be changed from old cells. `type` is required to has a data structure of `script`. **This field is optional.** |
| `lock`     | `Script`   | **A Script that defines the ownership of the cell**, just like the `scriptPubKey` field in the Bitcoin's CTxOut. Whoever can provide unlock arguments that makes the execution of this script success can consume this cell as input in an transaction (i.e. has the ownership of this cell). |



More information about Cell can be found in the [whitepaper](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0002-ckb/0002-ckb.md#42-cell).



## Script

### Example

```json
{
  "code_hash": "0x12b464bcab8f55822501cdb91ea35ea707d72ec970363972388a0c49b94d377c",
  "args": [
    "3044022038f282cffdd26e2a050d7779ddc29be81a7e2f8a73706d2b7a6fde8a78e950ee0220538657b4c01be3e77827a82e92d33a923e864c55b88fd18cd5e5b25597432e9b",
    "1"
  ]
}
```



### Description

| Name          | Type       | Description                                                  |
| :------------ | :--------- | :----------------------------------------------------------- |
| `code_hash` | H256(hash) | **The hash of ELF formatted RISC-V binary that contains a CKB script.** For space efficiency consideration, the actual script is attached to current transaction as a dep cell, the hash specified here should match the hash of cell data part in the dep cell. The actual binary is loaded into an CKB-VM instance when they are specified upon the transaction verification. |
| `args`        | [Bytes]    | **An array of arguments as the script input.** The arguments here are imported into the CKB-VM instance as input arguments for the scripts. Note that for lock scripts, the corresponding CellInput would have another args field which is appended to the array here to form the complete input argument list. |



When a script is validated, CKB will run it in a RISC-V VM, `args` will be included via UNIX standard `argc`/`argv` convention. For more information on the CKB VM please refer to [CKB VM RFC](../0003-ckb-vm/0003-ckb-vm.md).

For more information regardingt how `Script` structure is implemented please refer to the [CKB repo](https://github.com/nervosnetwork/ckb).



## Transaction

### Example

```json
{
    "deps": [],
    "inputs": [
      {
        "previous_output": {
          "hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
          "index": 4294967295
        },
        "args": []
      }
    ],
    "outputs": [
      {
        "capacity": 500_000_000_000_000,
        "data": "0x",
        "lock": {
          "args": [],
          "code_hash": "0xa58a960b28d6e283546e38740e80142da94f88e88d5114d8dc91312b8da4765a"
        },
        "type": null
      }
    ],
    "version": 0
}
```

### Description

#### Transaction

| Name              | Type                           | Description                                                  |
| ----------------- | ------------------------------ | ------------------------------------------------------------ |
| `version`         | uint32                         | **The version of the transaction.** It‘s used to distinguish transactions when there's a fork happened to the blockchain system. |
| `deps`            | [`outpoint`]                   | **An array of `outpoint` that point to the cells that are dependencies of this transaction.** Only live cells can be listed here. The cells listed are read-only. |
| `inputs`          | [{`previsou_output` , `args`}] | **An array of {`previous_output`, `args`}.** |
| `previous_output` | `outpoint`                     | **A cell outpoint that point to the cells used as inputs.** Input cells are in fact the output of previous transactions, hence they are noted as `previous_output` here. These cells are referred through  `outpoint`, which contains the transaction `hash` of the previous transaction, as well as this cell's `index` in its transaction's output list. |
| `args`            | [Bytes]                        | **Additional input arguments provided by transaction creator to make the execution of corresponding lock script success**. One example here, is that signatures might be include here to make sure a signature verification lock script passes. |
| `outputs`         | [`cell`]                       | **An array of cells that are used as outputs**, i.e. the newly generated cells. These are the cells may be used as inputs for other transactions. Each of the Cell has the same structure to [the Cell section](#cell) above. |



#### OutPoint



| Name             | Type               | Description                                                  |
| ---------------- | ------------------ | ------------------------------------------------------------ |
| `outpoint`       | {`hash` , `index`} | **An outpoint is pointer to a specific cell.** This is used in a transaction to refer a cell that is generated in a previous transaction. |
| `outpoint.hash`  | H256(hash)         | **The hash of the transaction that this cell belongs to.**   |
| `outpoint.index` | uint32             | **The index of the cell in its transaction's output list.**  |





More information about the Transaction of Nervos CKB can be found in [whitepaper](../0002-ckb/0002-ckb.md#44-transaction).



## Block

### Example

```json
{
  "commit_transactions": [
    {
      "deps": [],
      "inputs": [
          {
            "previous_output": {
              "hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
              "index": 4294967295
            },
            "args": []
          }
      ],
      "outputs": [
        {
          "capacity": 500_000_000_000_000,
          "data": "0x",
          "lock": {
            "args": [],
            "code_hash": "0xa58a960b28d6e283546e38740e80142da94f88e88d5114d8dc91312b8da4765a"
          },
          "type": null
        }
      ],
      "version": 0
    }
  ],
  "header": {
    "difficulty": "0x100",
    "number": 11,
    "parent_hash": "0x255f65bf9dc00bcd9f9b8be8624be222cba16b51366208a8267f1925eb40e7e4",
    "seal": {
        "nonce": 503529102265201399,
        "proof": "0x"
    },
    "timestamp": 1551155125985,
    "txs_commit": "0xabeb06aea75b59ec316db9d21243ee3f0b0ad0723e50f57761cef7e07974b9b5",
    "txs_proposal": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "uncles_count": 1,
    "uncles_hash": "0x99cf8710e59303bfac236b57256fcea2c58192f2c9c39d1ea4c19cbcf88b4952",
    "version": 0
  },
  "proposal_transactions": [],
  "uncles": [
    {
    "cellbase": {
        ...
    },
    "header": {
        ...
    },
    "proposal_transactions": []
    }
  ]
}
```

### Description

#### Block

| Name                    | Type            | Description                                                  |
| ----------------------- | --------------- | ------------------------------------------------------------ |
| `header`                | `Header`        | **The block header of the block.** This part contains some metadata of the block. See [the Header section](#header) below for the details of this part. |
| `commit_trasactions`    | [`Transaction`] | **An array of committed transactions contained in the block.** Each element of this array has the same structure as [the Transaction structure](#transaction) above. |
| `proposal_transactions` | [string]        | **An array of hex-encoded short transaction ID of the proposed transactions.** |
| `uncles`                | [`UncleBlock`]  | **An array of uncle blocks of the block.** See [the UncleBlock section](#uncleblock) below for the details of this part. |

#### Header

(`header` is a sub-structure of `block` and `UncleBlock`.)

| Name           | Type                | Description                                                  |
| -------------- | ------------------- | ------------------------------------------------------------ |
| `difficulty`   | Bytes               | **The difficulty of the PoW puzzle.**                        |
| `number`       | uint64              | **The block height.**                                        |
| `parent_hash`  | H256(hash)          | **The hash of the parent block.**                            |
| `seal`         | `nonce` and `proof` | **The seal of a block.** After finished the block assembling, the miner can start to do the calculation for finding the solution of the PoW puzzle. The "solution" here is called `seal`. |
| `seal.nonce`   | uint64              | **The nonce.** Similar to [the nonce in Bitcoin](https://en.bitcoin.it/wiki/Nonce). |
| `seal.proof`   | Bytes               | **The solution of the PoW puzzle.**                          |
| `timestamp`    | uint64              | **A [Unix time](http://en.wikipedia.org/wiki/Unix_time) timestamp.** |
| `txs_commit`   | H256(hash)          | **The Merkle Root of the Merkle trie with the hash of transactions as leaves.** |
| `txs_proposal` | H256(hash)          | **The Merkle Root of the Merkle trie with the hash of short transaction IDs as leaves.** |
| `uncles_count` | uint32              | **The number of uncle blocks.**                              |
| `uncles_hash`  | H256(hash)          | **The hash of the serialized uncle blocks data.** This will later be changed to using [CFB Encoding](https://github.com/nervosnetwork/cfb). |
| `version`      | uint32              | **The version of the block**. This is for solving the compatibility issues might be occurred after a fork. |

#### UncleBlock

(`UncleBlock` is a sub-structure of `Block`.)

| Name                    | Type          | Description                                                  |
| ----------------------- | ------------- | ------------------------------------------------------------ |
| `cellbase`              | `Transaction` | **The cellbase transaction of the uncle block.** The inner structure of this part is same as [the Transaction structure](#transaction) above. |
| `header`                | `Header`      | **The block header of the uncle block.** The inner structure of this part is same as [the Header structure](#header) above. |
| `proposal_transactions` | [`string`]    | **An array of short transaction IDs of the proposed transactions in the uncle block.** |

