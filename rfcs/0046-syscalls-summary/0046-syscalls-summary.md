---
Number: "0046"
Category: Informational
Status: Draft (for Informational)
Author: Shan <github.com/linnnsss>
Created: 2023-07-21
---

# CKB VM Syscalls Summary

This RFC aims to provide a comprehensive summary of all CKB VM syscalls as specified in RFC documents [RFC9 VM Syscalls](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md), [RFC34 VM Syscalls 2](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md), and RFC50 VM Syscalls 3 (currently under review). The goal is to gather relevant information from these documents and present it in an organized table for easy reference and comparison. This RFC also includes relevant constants, such as return codes, sources, cell fields, header fields, and input fields.

## CKB VM Syscalls

| VM Ver. | Syscall ID | C Function Name                                              | Description                                                  |
| ------- | ---------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1       | 93         | [ckb_exit](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#exit) | Immediately terminate the execution of the currently running script and exit with the specified return code. |
| 1       | 2061       | [ckb_load_tx_hash](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-transaction-hash) | Calculate the hash of the current transaction and copy it using partial loading. |
| 1       | 2051       | [ckb_load_transaction](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-transaction) | Serialize the full transaction of the running script using the Molecule Encoding 1 format and copy it using partial loading. |
| 1       | 2062       | [ckb_load_script_hash](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-script-hash) | Calculate the hash of currently running script and copy it using partial loading. |
| 1       | 2052       | [ckb_load_script](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-script) | Serialize the currently running script using the Molecule Encoding 1 format and copy it using partial loading. |
| 1       | 2071       | [ckb_load_cell](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell) | Serialize the specified cell in the current transaction using the Molecule Encoding 1 format and copy it using partial loading. |
| 1       | 2081       | [ckb_load_cell_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-by-field) | Load a single field from the specified cell in the current transaction and copy it using partial loading. |
| 1       | 2092       | [ckb_load_cell_data](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data) | Load the data from the cell data field in the specified cell from the current transaction and copy it using partial loading. |
| 1       | 2091       | [ckb_load_cell_data_as_code](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data-as-code) | Load the data from the cell data field in the specified cell from the current transaction, mark the loaded memory page as executable, and copy it using partial loading. The loaded code can then be executed by CKB VM at a later time. |
| 1       | 2073       | [ckb_load_input](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-input) | Serialize the specified input cell in the current transaction using the Molecule Encoding 1 format and copy it using partial loading. |
| 1       | 2083       | [ckb_load_input_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-input-by-field) | Load a single field from the specified input cell in the current transaction and copy it using partial loading. |
| 1       | 2072       | [ckb_load_header](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-header) | Serialize the specified header associated with an input cell, dep cell, or header dep using the Molecule Encoding 1 format and copy it using partial loading. |
| 1       | 2082       | [ckb_load_header_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-header-by-field) | Load a single field from the specified header associated with an input cell, dep cell, or header dep and copy it using partial loading. |
| 1       | 2074       | [ckb_load_witness](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-witness) | Load the specified witness in the current transaction and copy it using partial loading. |
| 1       | 2177       | [ckb_debug](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#debug) | Print the specified message in CKB's terminal output for the purposes of debugging. |
| 2       | 2041       | [ckb_vm_version](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#vm-version) | Return the version of CKB VM being used to execute the current script. |
| 2       | 2042       | [ckb_current_cycles](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#current-cycles) | Return the number of cycles consumed by the currently running script *immediately before* executing this syscall. This syscall will consume an additional 500 cycles. |
| 2       | 2043       | [ckb_exec](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#exec) | Run a script executable from the specified cell using the current VM context. This replaces the original calling running script executable with the new specified script executable. This is similar to the [exec call](https://en.wikipedia.org/wiki/Exec_(system_call)) found in several operating systems. |
| | | ckb_spawn | (To be added in CKB2023.) Run a script executable from the specified cell using the current VM context, but return to the original calling script executable upon termination. This is similar to the [spawn function](https://en.wikipedia.org/wiki/Spawn_(computing)) found in several operating systems and programming languages. |
| | | ckb_get_memory_limit | (To be added in CKB2023.) Return the maximum amount of memory available to the current script being executed. |
| | | ckb_set_content | (To be added in CKB2023.) Set the content of the designated memory region that can be read by the parent (calling) script which executed the current script via the spawn function. |
| | | ckb_load_extension | (To be added in CKB2023.) Load the extention field data and copy it using partial loading. |

## Constants

### Return Codes

These are the return codes used by the CKB VM syscalls. 

| Const No. | C Example              | Description                                       |
| --------- | ---------------------- | ------------------------------------------------- |
| 0         | CKB_SUCCESS            | No error.                                         |
| 1         | CKB_INDEX_OUT_OF_BOUND | Index out of bound. (e.g. No such input cell.)    |
| 2         | CKB_ITEM_MISSING       | The requested resource does not exist.            |
| 3         | CKB_LENGTH_NOT_ENOUGH  | The supplied memory buffer too small.             |
| 4         | CKB_INVALID_DATA       | The data provided is invalid.                     |

### Source

These are the sources for syscalls that query the transaction for input cells, output cells, dep cells, and header deps. 

| Const No.          | C Example               | Description                                                                                 |
| ------------------ | ----------------------- | ------------------------------------------------------------------------------------------- |
| 0x1                | CKB_SOURCE_INPUT        | All input cells in the transaction.                                                         |
| 0x0100000000000001 | CKB_SOURCE_GROUP_INPUT  | Only the input cells in the transaction using the same script as currently running script.  |
| 2                  | CKB_SOURCE_OUTPUT       | All output cells in the transaction.                                                        |
| 0x0100000000000002 | CKB_SOURCE_GROUP_OUTPUT | Only the output cells in the transaction using the same script as currently running script. |
| 3                  | CKB_SOURCE_CELL_DEP     | All dep cells in the transaction.                                                           |
| 4                  | CKB_SOURCE_HEADER_DEP   | All header deps in the transaction.                                                         |

### Cell Fields

These are the field specifiers for syscalls that request a specific field of a cell.

| Const No. | C Example                        | Description                                                            |
| --------- | -------------------------------- | ---------------------------------------------------------------------- |
| 0         | CKB_CELL_FIELD_CAPACITY          | The capacity (CKB) contained in the cell.                              |
| 1         | CKB_CELL_FIELD_DATA_HASH         | The hash of the data within the data field of the cell.                |
| 2         | CKB_CELL_FIELD_LOCK              | The lock script of the cell.                                           |
| 3         | CKB_CELL_FIELD_LOCK_HASH         | The hash of the lock script of the cell.                               |
| 4         | CKB_CELL_FIELD_TYPE              | The type script of the cell.                                           |
| 5         | CKB_CELL_FIELD_TYPE_HASH         | The hash of the type script of the cell.                               |
| 6         | CKB_CELL_FIELD_OCCUPIED_CAPACITY | The amount of capacity (CKB) that is currently being used by the cell. |

### Header Fields

These are the field specifiers for syscalls that request a specific field of a header dep.

| Const No. | C Example                                 | Description                                                      |
| --------- | ----------------------------------------- | ---------------------------------------------------------------- |
| 0         | CKB_HEADER_FIELD_EPOCH_NUMBER             | The epoch number for the header dep.                             |
| 1         | CKB_HEADER_FIELD_EPOCH_START_BLOCK_NUMBER | The block number of first block in the epoch for the header dep. |
| 2         | CKB_HEADER_FIELD_EPOCH_LENGTH             | The length of the epoch for the header dep.                      |

### Input Fields

These are the field specifiers for syscalls that request a specific field of an input cell.

| Const No. | C Example                 | Description                                  |
| --------- | ------------------------- | -------------------------------------------- |
| 0         | CKB_INPUT_FIELD_OUT_POINT | The out point of the specified input cell.   |
| 1         | CKB_INPUT_FIELD_SINCE     | The since value of the specified input cell. |
