---
Number: "0000"
Category: Informational
Status: Draft (for Informational)
Author: Shan <github.com/linnnsss>
Created: 2023-07-21
---

# VM Syscalls Summary

This RFC aims to provide a comprehensive summary of CKB VM syscalls as specified in three different RFC documents: [RFC9 VM Syscalls](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md), [RFC34 VM Syscalls 2](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md), and RFC50 VM Syscalls 3 (currently under review). The goal is to gather relevant information from these documents and present it in an organized table for easy reference and comparison. This RFC also includes relevant constants, such as return codes, sources, cell fields, header fields, and input fields.

## Table Summary

| VM Ver. | Syscall ID | C Function Name                                              | Description                                                  |
| ------- | ---------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1       | 93         | [ckb_exit](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#exit) | terminate execution with the specified return code           |
| 1       | 2061       | [ckb_load_tx_hash](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-transaction-hash) | load transaction hash                                        |
| 1       | 2051       | [ckb_load_transaction](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-transaction) | load transaction                                             |
| 1       | 2062       | [ckb_load_script_hash](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-script-hash) | load script hash                                             |
| 1       | 2052       | [ckb_load_script](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-script) | load script                                                  |
| 1       | 2071       | [ckb_load_cell](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell) | load cell                                                    |
| 1       | 2081       | [ckb_load_cell_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-by-field) | load field in cell data                                      |
| 1       | 2092       | [ckb_load_cell_data](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data) | load cell data                                               |
| 1       | 2091       | [ckb_load_cell_data_as_code](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data-as-code) | load cell data as executable code and then execute it        |
| 1       | 2073       | [ckb_load_input](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-input) | load cell input                                              |
| 1       | 2083       | [ckb_load_input_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-input-by-field) | load field in cell input                                     |
| 1       | 2072       | [ckb_load_header](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-header) | load header                                                  |
| 1       | 2082       | [ckb_load_header_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-header-by-field) | load field in cell header                                    |
| 1       | 2074       | [ckb_load_witness](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-witness) | load witness                                                 |
| 1       | 2177       | [ckb_debug](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#debug) | print debug message                                          |
| 2       | 2041       | [ckb_vm_version](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#vm-version) | get VM version                                               |
| 2       | 2042       | [ckb_current_cycles](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#current-cycles) | get current cycle consumption                                |
| 2       | 2043       | [ckb_exec](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#exec) | run an executable file from specified cell data in the context of an already existing machine, replacing the previous executable  
|         |            | ckb_spawn                                                    | spawn a script as a subprocess                               |
|         |            | ckb_get_memory_limit                                         | get the maximum available memory for the current script      |
|         |            | ckb_set_content                                              | set memory content to be read by the parent script           |
|         |            | ckb_load_extension                                           | locate extention field and feed the serialized value into VM |

## Constants

### Return Code

| Const Nr. | C Example              | Description                                  |
| --------- | ---------------------- | -------------------------------------------- |
| 0         | CKB_SUCCESS            | no errors                                    |
| 1         | CKB_INDEX_OUT_OF_BOUND | index out of bound (e.g. no such input cell) |
| 2         | CKB_ITEM_MISSING       | output cells                                 |
| 3         | CKB_LENGTH_NOT_ENOUGH  | supplied memory buffer too small             |
| 4         | CKB_INVALID_DATA       | data in an invalid format                    |

### Source

| Const Nr.          | C Example               | Description                                                 |
| ------------------ | ----------------------- | ----------------------------------------------------------- |
| 0x1                | CKB_SOURCE_INPUT        | input cells                                                 |
| 0x0100000000000001 | CKB_SOURCE_GROUP_INPUT  | input cells with the same running script as current script  |
| 2                  | CKB_SOURCE_OUTPUT       | output cells                                                |
| 0x0100000000000002 | CKB_SOURCE_GROUP_OUTPUT | output cells with the same running script as current script |
| 3                  | CKB_SOURCE_CELL_DEP     | dep cells                                                   |
| 4                  | CKB_SOURCE_HEADER_DEP   | header deps                                                 |

### Cell Fields

| Const Nr | C Example                        | Description            |
| -------- | -------------------------------- | ---------------------- |
| 0        | CKB_CELL_FIELD_CAPACITY          | cell capacity          |
| 1        | CKB_CELL_FIELD_DATA_HASH         | cell data hash         |
| 2        | CKB_CELL_FIELD_LOCK              | cell lock script       |
| 3        | CKB_CELL_FIELD_LOCK_HASH         | cell lock script hash  |
| 4        | CKB_CELL_FIELD_TYPE              | cell type script       |
| 5        | CKB_CELL_FIELD_TYPE_HASH         | cell type script hash  |
| 6        | CKB_CELL_FIELD_OCCUPIED_CAPACITY | occupied cell capacity |

### Header Fields

| Const Nr. | C Example                                 | Description              |
| --------- | ----------------------------------------- | ------------------------ |
| 0         | CKB_HEADER_FIELD_EPOCH_NUMBER             | epoch number             |
| 1         | CKB_HEADER_FIELD_EPOCH_START_BLOCK_NUMBER | epoch’s 1st block number |
| 2         | CKB_HEADER_FIELD_EPOCH_LENGTH             | epoch length             |

### Input Fields

| Const Nr. | C Example                 | Description          |
| --------- | ------------------------- | -------------------- |
| 0         | CKB_INPUT_FIELD_OUT_POINT | input cell out point |
| 1         | CKB_INPUT_FIELD_SINCE     | input cell since     |
