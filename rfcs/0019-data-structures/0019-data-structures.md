---
Number: "0019"
Category: Informational
Status: Draft
Author: Xuejie Xiao
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
  "capacity": "0x19995d0ccf",
  "lock": {
    "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
    "args": "0x0a486fb8f6fe60f76f001d6372da41be91172259",
    "hash_type": "type"
  },
  "type": null
}
```

## Description

| Name       | Type       | Description                                                  |
| :--------- | :--------- | :----------------------------------------------------------- |
| `capacity` | uint64     | **The size of the cell (in shannons).** When a new cell is generated (via transaction), one of the verification rule is `capacity_in_bytes >= len(capacity) + len(data) + len(type) + len(lock)`. This value also represents the balance of CKB coin, just like the `nValue` field in the Bitcoin's CTxOut. (E.g. Alice owns 100 CKB coins means she can unlock a group of cells that has 100 amount of `bytes` (which is 10_000_000_000 amount of `shannons`) in total.). The actual value is returned in hex string format. |
| `type`     | `Script`   | **A Script that defines the type of the cell.** It limits how the `data` field of the new cells can be changed from old cells. `type` is required to has a data structure of `script`. **This field is optional.** |
| `lock`     | `Script`   | **A Script that defines the ownership of the cell**, just like the `scriptPubKey` field in the Bitcoin's CTxOut. Whoever can provide unlock arguments that makes the execution of this script success can consume this cell as input in an transaction (i.e. has the ownership of this cell). |



More information about Cell can be found in the [whitepaper](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0002-ckb/0002-ckb.md#42-cell).



## Script

### Example

```json
{
  "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
  "args": "0x0a486fb8f6fe60f76f001d6372da41be91172259",
  "hash_type": "type"
}
```



### Description

| Name          | Type                                 | Description                                                  |
| :------------ | :----------------------------------- | :----------------------------------------------------------- |
| `code_hash`   | H256(hash)                           | **The hash of ELF formatted RISC-V binary that contains a CKB script.** For space efficiency consideration, the actual script is attached to current transaction as a dep cell. Depending on the value of `hash_type`, the hash specified here should either match the hash of cell data part in the dep cell, or the hash of type script in the dep cell. The actual binary is loaded into an CKB-VM instance when they are specified upon the transaction verification. |
| `args`        | [Bytes]                              | **An array of arguments as the script input.** The arguments here are imported into the CKB-VM instance as input arguments for the scripts. Note that for lock scripts, the corresponding CellInput would have another args field which is appended to the array here to form the complete input argument list. |
| `hash_type`   | String, could be `type` or `code`    | **The interpretation of code hash when looking for matched dep cells.** If this is `code`, `code_hash` should match the blake2b hash of data in a dep cell; if this is `type`, `code_hash` should instead match the type script hash of a dep cell. |



When a script is validated, CKB will run it in a RISC-V VM, `args` must be loaded via special CKB syscalls. UNIX standard `argc`/`argv` convention is not used in CKB. For more information on the CKB VM please refer to [CKB VM RFC](../0003-ckb-vm/0003-ckb-vm.md).

For more information regarding how `Script` structure is implemented please refer to the [CKB repo](https://github.com/nervosnetwork/ckb).



## Transaction

### Example

```json
{
  "version": "0x0",
  "cell_deps": [
    {
      "out_point": {
        "tx_hash": "0xbd864a269201d7052d4eb3f753f49f7c68b8edc386afc8bb6ef3e15a05facca2",
        "index": "0x0"
      },
      "dep_type": "dep_group"
    }
  ],
  "header_deps": [
    "0xaa1124da6a230435298d83a12dd6c13f7d58caf7853f39cea8aad992ef88a422"
  ],
  "inputs": [
    {
      "previous_output": {
        "tx_hash": "0x8389eba3ae414fb6a3019aa47583e9be36d096c55ab2e00ec49bdb012c24844d",
        "index": "0x1"
      },
      "since": "0x0"
    }
  ],
  "outputs": [
    {
      "capacity": "0x746a528800",
      "lock": {
        "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
        "args": "0x56008385085341a6ed68decfabb3ba1f3eea7b68",
        "hash_type": "type"
      },
      "type": null
    },
    {
      "capacity": "0x1561d9307e88",
      "lock": {
        "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
        "args": "0x886d23a7858f12ebf924baaacd774a5e2cf81132",
        "hash_type": "type"
      },
      "type": null
    }
  ],
  "outputs_data": [
    "0x",
    "0x"
  ],
  "witnesses": [
    "0x55000000100000005500000055000000410000004a975e08ff99fa000142ff3b86a836b43884b5b46f91b149f7cc5300e8607e633b7a29c94dc01c6616a12f62e74a1415f57fcc5a00e41ac2d7034e90edf4fdf800"
  ]
}
```

### Description

#### Transaction

| Name              | Type                             | Description                                                  |
| ----------------- | -------------------------------- | ------------------------------------------------------------ |
| `version`         | uint32                           | **The version of the transaction.** It‘s used to distinguish transactions when there's a fork happened to the blockchain system. |
| `cell_deps`       | [`CellDep`]                      | **An array of `outpoint` pointing to the cells that are dependencies of this transaction.** Only live cells can be listed here. The cells listed are read-only. |
| `header_deps`     | [`H256(hash)`]                   | **An array of `H256` hashes pointint to block headers that are dependencies of this transaction.** Notice maturity rules apply here: a transaction can only reference a header that is at least 4 epochs old. |
| `inputs`          | [`CellInput`]                    | **An array of referenced cell inputs.** See below for explanations of underlying data structure |
| `outputs`         | [`Cells`], see above for details | **An array of cells that are used as outputs**, i.e. the newly generated cells. These are the cells may be used as inputs for other transactions. Each of the Cell has the same structure to [the Cell section](#cell) above. |
| `outputs_data`    | [`Bytes`]                        | **An array of cell data for each cell output.** The actual data are kept separated from outputs for the ease of CKB script handling and for the possibility of future optimizations. |
| `witnesses`       | [`Bytes`]                        | **Witnesses provided by transaction creator to make the execution of corresponding lock script success**. One example here, is that signatures might be include here to make sure a signature verification lock script passes. |


#### CellDep


| Name        | Type                                 | Description                                                  |
| ----------- | ------------------------------------ | ------------------------------------------------------------ |
| `out_point` | `OutPoint`                           | **A cell outpoint that point to the cells used as deps.** Dep cells are dependencies of a transaction, it could be used to include code that are loaded into CKB VM, or data that could be used in script execution. |
| `dep_type`  | String, either `code` or `dep_group` | **The way to interpret referenced cell deps.** A cell dep could be referenced in 2 ways: for a cell dep with `code` as `dep_type`, the dep cell is directly included in the transaction. If a cell dep `dep_type` uses `dep_group`, however, CKB would first load this dep cell, assume the content of this cell contains a list of cell deps, then use the extracted list of cell deps to replace current cell dep, and include them in current transaction. This provides a quicker and smaller(in terms of transaction size) to include multiple commonly used dep cells in one CellDep construct. |


#### CellInput


| Name              | Type       | Description                                                  |
| ----------------- | ---------- | ------------------------------------------------------------ |
| `previous_output` | `OutPoint` | **A cell outpoint that point to the cells used as inputs.** Input cells are in fact the output of previous transactions, hence they are noted as `previous_output` here. These cells are referred through  `outpoint`, which contains the transaction `hash` of the previous transaction, as well as this cell's `index` in its transaction's output list. |
| `since`           | uint64     | **Since value guarding current referenced inputs.** Please refer to the [Since RFC](../0017-tx-valid-since/0017-tx-valid-since.md) for details on this field. |


#### OutPoint


| Name    | Type               | Description                                                  |
| ------- | ------------------ | ------------------------------------------------------------ |
| `hash`  | H256(hash)         | **The hash of the transaction that this cell belongs to.**   |
| `index` | uint32             | **The index of the cell in its transaction's output list.**  |





More information about the Transaction of Nervos CKB can be found in [whitepaper](../0002-ckb/0002-ckb.md#44-transaction).



## Block

### Example

```json
{
  "uncles": [
    {
      "proposals": [

      ],
      "header": {
        "compact_target": "0x1a9c7b1a",
        "hash": "0x87764caf4a0e99302f1382421da1fe2f18382a49eac2d611220056b0854868e3",
        "number": "0x129d3",
        "parent_hash": "0x815ecf2140169b9d283332c7550ce8b6405a120d5c21a7aa99d8a75eb9e77ead",
        "nonce": "0x78b105de64fc38a200000004139b0200",
        "timestamp": "0x16e62df76ed",
        "transactions_root": "0x66ab0046436f97aefefe0549772bf36d96502d14ad736f7f4b1be8274420ca0f",
        "proposals_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "uncles_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "version": "0x0",
        "epoch": "0x7080291000049",
        "dao": "0x7088b3ee3e738900a9c257048aa129002cd43cd745100e000066ac8bd8850d00"
      }
    }
  ],
  "proposals": [
    "0x5b2c8121455362cf70ff"
  ],
  "transactions": [
    {
      "version": "0x0",
      "cell_deps": [

      ],
      "header_deps": [

      ],
      "inputs": [
        {
          "previous_output": {
            "tx_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "index": "0xffffffff"
          },
          "since": "0x129d5"
        }
      ],
      "outputs": [
        {
          "capacity": "0x1996822511",
          "lock": {
            "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
            "args": "0x2ec3a5fb4098b14f4887555fe58d966cab2c6a63",
            "hash_type": "type"
          },
          "type": null
        }
      ],
      "outputs_data": [
        "0x"
      ],
      "witnesses": [
        "0x590000000c00000055000000490000001000000030000000310000009bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce801140000002ec3a5fb4098b14f4887555fe58d966cab2c6a6300000000"
      ],
      "hash": "0x84395bf085f48de9f8813df8181e33d5a43ab9d92df5c0e77d711e1d47e4746d"
    }
  ],
  "header": {
    "compact_target": "0x1a9c7b1a",
    "hash": "0xf355b7bbb50627aa26839b9f4d65e83648b80c0a65354d78a782744ee7b0d12d",
    "number": "0x129d5",
    "parent_hash": "0x4dd7ae439977f1b01a8c9af7cd4be2d7bccce19fcc65b47559fe34b8f32917bf",
    "nonce": "0x91c4b4746ffb69fe000000809a170200",
    "timestamp": "0x16e62dfdb19",
    "transactions_root": "0x03c72b4c2138309eb46342d4ab7b882271ac4a9a12d2dcd7238095c2d131caa6",
    "proposals_hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "uncles_hash": "0x90eb89b87b4af4c391f3f25d0d9f59b8ef946d9627b7e86283c68476fee7328b",
    "version": "0x0",
    "epoch": "0x7080293000049",
    "dao": "0xae6c356c8073890051f05bd38ea12900939dbc2754100e0000a0d962db850d00"
  }
}
```

### Description

#### Block

| Name                    | Type            | Description                                                  |
| ----------------------- | --------------- | ------------------------------------------------------------ |
| `header`                | `Header`        | **The block header of the block.** This part contains some metadata of the block. See [the Header section](#header) below for the details of this part. |
| `trasactions`           | [`Transaction`] | **An array of committed transactions contained in the block.** Each element of this array has the same structure as [the Transaction structure](#transaction) above. |
| `proposals`             | [string]        | **An array of hex-encoded short transaction ID of the proposed transactions.** |
| `uncles`                | [`UncleBlock`]  | **An array of uncle blocks of the block.** See [the UncleBlock section](#uncleblock) below for the details of this part. |

#### Header

(`header` is a sub-structure of `block` and `UncleBlock`.)

| Name                | Type       | Description                                                  |
| ------------------- | ---------- | ------------------------------------------------------------ |
| `compact_target`    | uint32     | **The difficulty of the PoW puzzle represented in compact target format.** |
| `number`            | uint64     | **The block height.**                                        |
| `parent_hash`       | H256(hash) | **The hash of the parent block.**                            |
| `nonce`             | uint128    | **The nonce.** Similar to [the nonce in Bitcoin](https://en.bitcoin.it/wiki/Nonce). Represent the solution of the PoW puzzle |
| `timestamp`         | uint64     | **A [Unix time](http://en.wikipedia.org/wiki/Unix_time) timestamp.** |
| `transactions_root` | H256(hash) | **The hash of concatenated transaction hashes CBMT root and transaction witness hashes CBMT root.** |
| `proposals_hash`    | H256(hash) | **The hash of concatenated proposal ids.** (all zeros when proposals is empty) |
| `uncles_hash`       | H256(hash) | **The hash of concatenated hashes of uncle block headers.** （all zeros when uncles is empty) |
| `version`           | uint32     | **The version of the block**. This is for solving the compatibility issues might be occurred after a fork. |
| `epoch`             | uint64     | **Current epoch information.** Assume `number` represents the current epoch number, `index` represents the index of the block in the current epoch(start at 0), `length` represents the length of current epoch. The value store here will then be `(number & 0xFFFFFF) | ((index & 0xFFFF) << 24) | ((length & 0xFFFF) << 40)` |
| `dao`               | Bytes      | **Data containing DAO related information.** Please refer to Nervos DAO RFC for details on this field. |

#### UncleBlock

(`UncleBlock` is a sub-structure of `Block`.)

| Name                    | Type          | Description                                                  |
| ----------------------- | ------------- | ------------------------------------------------------------ |
| `header`                | `Header`      | **The block header of the uncle block.** The inner structure of this part is same as [the Header structure](#header) above. |
| `proposals`             | [`string`]    | **An array of short transaction IDs of the proposed transactions in the uncle block.** |

