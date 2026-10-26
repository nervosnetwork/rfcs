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

| VM Ver. | Syscall ID | C Function Name                                                                                                                                                                                 | Description                                                                                                                                                                                                                                                                                                     |
| ------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0       | 93         | [ckb_exit](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#exit)                                                                                    | Immediately terminate the execution of the currently running Script and exit with the specified return code.                                                                                                                                                                                                    |
| 0       | 2061       | [ckb_load_tx_hash](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-transaction-hash)                                                           | Calculate the hash of the current transaction and copy it using partial loading.                                                                                                                                                                                                                                |
| 0       | 2051       | [ckb_load_transaction](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-transaction)                                                            | Serialize the full transaction of the running Script using the Molecule Encoding 1 format and copy it using partial loading.                                                                                                                                                                                    |
| 0       | 2062       | [ckb_load_script_hash](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-script-hash)                                                            | Calculate the hash of currently running Script and copy it using partial loading.                                                                                                                                                                                                                               |
| 0       | 2052       | [ckb_load_script](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-script)                                                                      | Serialize the currently running Script using the Molecule Encoding 1 format and copy it using partial loading.                                                                                                                                                                                                  |
| 0       | 2071       | [ckb_load_cell](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell)                                                                          | Serialize the specified Cell in the current transaction using the Molecule Encoding 1 format and copy it using partial loading.                                                                                                                                                                                 |
| 0       | 2081       | [ckb_load_cell_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-by-field)                                                        | Load a single field from the specified Cell in the current transaction and copy it using partial loading.                                                                                                                                                                                                       |
| 0       | 2092       | [ckb_load_cell_data](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data)                                                                | Load the data from the Cell data field in the specified Cell from the current transaction and copy it using partial loading.                                                                                                                                                                                    |
| 0       | 2091       | [ckb_load_cell_data_as_code](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data-as-code)                                                | Load the data from the Cell data field in the specified Cell from the current transaction, mark the loaded memory page as executable, and copy it using partial loading. The loaded code can then be executed by CKB-VM at a later time.                                                                        |
| 0       | 2073       | [ckb_load_input](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-input)                                                                        | Serialize the specified input Cell in the current transaction using the Molecule Encoding 1 format and copy it using partial loading.                                                                                                                                                                           |
| 0       | 2083       | [ckb_load_input_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-input-by-field)                                                      | Load a single field from the specified input Cell in the current transaction and copy it using partial loading.                                                                                                                                                                                                 |
| 0       | 2072       | [ckb_load_header](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-header)                                                                      | Serialize the specified header associated with an input Cell, dep Cell, or header dep using the Molecule Encoding 1 format and copy it using partial loading.                                                                                                                                                   |
| 0       | 2082       | [ckb_load_header_by_field](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-header-by-field)                                                    | Load a single field from the specified header associated with an input Cell, dep Cell, or header dep and copy it using partial loading.                                                                                                                                                                         |
| 0       | 2074       | [ckb_load_witness](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-witness)                                                                    | Load the specified witness in the current transaction and copy it using partial loading.                                                                                                                                                                                                                        |
| 0       | 2177       | [ckb_debug](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#debug)                                                                                  | Print the specified message in CKB's terminal output for the purposes of debugging.                                                                                                                                                                                                                             |
| 1       | 2041       | [ckb_vm_version](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#vm-version)                                                                    | Return the version of CKB-VM being used to execute the current Script.                                                                                                                                                                                                                                          |
| 1       | 2042       | [ckb_current_cycles](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#current-cycles)                                                            | Return the number of cycles consumed by the currently running Script _immediately before_ executing this syscall. This syscall will consume an additional 500 cycles.                                                                                                                                           |
| 1       | 2043       | [ckb_exec](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#exec) (deprecated, see [known issues](https://docs.nervos.org/docs/script/vm-version#known-issues-1)) | Run a Script executable from the specified Cell using the current VM context. This replaces the original calling running Script executable with the new specified Script executable. This is similar to the [exec call](<https://en.wikipedia.org/wiki/Exec_(system_call)>) found in several operating systems. |
| 2       | 2104       | [ckb_load_block_extension](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#load-block-extension)                                                      | Load the extension field data and copy it using partial loading.
| 2       | 2601       | [ckb_spawn](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#spawn)                                                                              | Run a Script executable from the specified Cell using the current VM context, but return to the original calling Script executable upon termination. This is similar to the [spawn function](<https://en.wikipedia.org/wiki/Spawn_(computing)>) found in several operating systems and programming languages.   |                                                        |
| 2       | 2602       | [ckb_wait](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#wait)                                                                                | Pause until the execution of a process specified by `pid` has ended.                                                                                                                                                                                                                                            |
| 2       | 2603       | [ckb_process_id](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#process-id)                                                                    | Get the current process id.                                                                                                                                                                                                                                                                                     |
| 2       | 2604       | [ckb_pipe](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#pipe)                                                                                | Create a pipe with read-write pair of file descriptions.                                                                                                                                                                                                                                                        |
| 2       | 2605       | [ckb_write](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#write)                                                                              | Write data to a pipe via a file descriptor.                                                                                                                                                                                                                                                                     |
| 2       | 2606       | [ckb_read](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#read)                                                                                | Read data from a pipe via a file descriptor.                                                                                                                                                                                                                                                                    |
| 2       | 2607       | [ckb_inherited_fds](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#inherited-file-descriptors)                                    | Retrieve the file descriptors available to the current process, which are passed in from the parent process.                                                                                                                                                                                                    |
| 2       | 2608       | [ckb_close](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0050-vm-syscalls-3/0050-vm-syscalls-3.md#close)                                                                              | Manually close a file descriptor.                                                                                                                                                                                                                                                                               |                                                                                                                                                                                                                                                                           |

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
