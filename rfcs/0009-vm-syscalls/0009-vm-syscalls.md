---
Number: "0009"
Category: Standards Track
Status: Active
Author: Xuejie Xiao <xxuejie@gmail.com>
Created: 2018-12-14
---

# VM Syscalls

## Abstract

This document describes all the RISC-V VM syscalls implemented in CKB Lina. Note that 3 new syscalls have been added to CKB Edition Mirana [2].

## Introduction

CKB VM syscalls are used to implement communications between the RISC-V based CKB VM, and the main CKB process, allowing scripts running in the VM to read current transaction information as well as general blockchain information from CKB. Leveraging syscalls instead of custom instructions allow us to maintain a standard compliant RISC-V implementation which can embrace the broadest industrial support.

## Partial Loading

With the exception of `Exit`, all syscalls included here use a partial loading design. The following 3 arguments are used in each syscall:

* `addr`: a pointer to a buffer in VM memory space denoting where we would load the syscall data.
* `len`: a pointer to a 64-bit unsigned integer in VM memory space, when calling the syscall, this memory location should store the length of the buffer specified by `addr`, when returning from the syscall, CKB VM would fill in `len` with the actual length of the buffer. We would explain the exact logic below.
* `offset`: an offset specifying from which offset we should start loading the syscall data.

Each syscall might have different ways of preparing syscall return data, when the data is successfully prepared, it is fed into VM via the steps below. For ease of reference, we refer to the prepared syscall return data as `data`, and the length of `data` as `data_length`.

1. A memory read operation is executed to read the value in `len` pointer from VM memory space, we call the read result `size` here.
2. `full_size` is calculated as `data_length - offset`.
3. `real_size` is calculated as the minimal value of `size` and `full_size`
4. The serialized value starting from `&data[offset]` till `&data[offset + real_size]` is written into VM memory space location starting from `addr`.
5. `full_size` is written into `len` pointer
6. `0` is returned from the syscall denoting execution success.

The whole point of this process, is providing VM side a way to do partial reading when the available memory is not enough to support reading the whole data altogether.

One trick here, is that by providing `NULL` as `addr`, and a `uint64_t` pointer with 0 value as `len`, this syscall can be used to fetch the length of the serialized data part without reading any actual data.

## Syscall Specifications

In CKB we use RISC-V's standard syscall solution: each syscall accepts 6 arguments stored in register `A0` through `A5`. Each argument here is of register word size so it can store either regular integers or pointers. The syscall number is stored in `A7`. After all the arguments and syscall number are set, `ecall` instruction is used to trigger syscall execution, CKB VM then transfers controls from the VM to the actual syscall implementation beneath. For example, the following RISC-V assembly would trigger *Exit* syscall with a return code of 10:

```
li a0, 10
li a7, 93
ecall
```

As shown in the example, not all syscalls use all the 6 arguments. In this case the caller side can only fill in the needed arguments.

Syscalls can respond to the VM in 2 ways:

* A return value is put in `A0` if exists.
* Syscalls can also write data in memory location pointed by certain syscall arguments, so upon syscall completion, normal VM instructions can read the data prepared by the syscall.

For convenience, we could wrap the logic of calling a syscall in a C function:

```c
static inline long
__internal_syscall(long n, long _a0, long _a1, long _a2, long _a3, long _a4, long _a5)
{
  register long a0 asm("a0") = _a0;
  register long a1 asm("a1") = _a1;
  register long a2 asm("a2") = _a2;
  register long a3 asm("a3") = _a3;
  register long a4 asm("a4") = _a4;
  register long a5 asm("a5") = _a5;

  register long syscall_id asm("a7") = n;

  asm volatile ("scall"
		: "+r"(a0) : "r"(a1), "r"(a2), "r"(a3), "r"(a4), "r"(a5), "r"(syscall_id));

  return a0;
}

#define syscall(n, a, b, c, d, e, f) \
        __internal_syscall(n, (long)(a), (long)(b), (long)(c), (long)(d), (long)(e), (long)(f))
```

(NOTE: this is adapted from [riscv-newlib](https://github.com/riscv/riscv-newlib/blob/77e11e1800f57cac7f5468b2bd064100a44755d4/libgloss/riscv/internal_syscall.h#L25))

Now we can trigger the same *Exit* syscall more easily in C code:

```c
syscall(93, 10, 0, 0, 0, 0, 0);
```

Note that even though *Exit* syscall only needs one argument, our C wrapper requires us to fill in all 6 arguments. We can initialize other unused arguments as all 0. Below we would illustrate each syscall with a C function signature to demonstrate each syscall's accepted arguments. Also for clarifying reason, all the code shown in this RFC is assumed to be written in pure C.

- [Exit]
- [Load Transaction Hash]
- [Load Transaction]
- [Load Script Hash]
- [Load Script]
- [Load Cell]
- [Load Cell By Field]
- [Load Cell Data]
- [Load Cell Data As Code]
- [Load Input]
- [Load Input By Field]
- [Load Header]
- [Load Header By Field]
- [Load Witness]
- [Debug]

### Exit
[exit]: #exit

As shown above, *Exit* syscall has a signature like following:

```c
void exit(int8_t code)
{
  syscall(93, code, 0, 0, 0, 0, 0);
}
```

*Exit* syscall don't need a return value since CKB VM is not supposed to return from this function. Upon receiving this syscall, CKB VM would terminate execution with the specified return code. This is the only way of correctly exiting a script in CKB VM.

### Load Transaction Hash
[load transaction hash]: #load-transaction-hash

*Load Transaction Hash* syscall has a signature like following:

```c
int ckb_load_tx_hash(void* addr, uint64_t* len, size_t offset)
{
  return syscall(2061, addr, len, offset, 0, 0, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.

This syscall would calculate the hash of current transaction and copy it to VM memory space based on *partial loading* workflow.

### Load Transaction
[load transaction]: #load-transaction

*Load Transaction* syscall has a signature like following:

```c
int ckb_load_transaction(void* addr, uint64_t* len, size_t offset)
{
  return syscall(2051, addr, len, offset, 0, 0, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.

This syscall serializes the full transaction containing running script into the Molecule Encoding [1] format, then copy it to VM memory space based on *partial loading* workflow.

### Load Script Hash
[load script hash]: #load-script-hash

*Load Script Hash* syscall has a signature like following:

```c
int ckb_load_script_hash(void* addr, uint64_t* len, size_t offset)
{
  return syscall(2062, addr, len, offset, 0, 0, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.

This syscall would calculate the hash of current running script and copy it to VM memory space based on *partial loading* workflow.

### Load Script
[load script]: #load-script

*Load Script* syscall has a signature like following:

```c
int ckb_load_script(void* addr, uint64_t* len, size_t offset)
{
  return syscall(2052, addr, len, offset, 0, 0, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.

This syscall serializes the current running script into the Molecule Encoding [1] format, then copy it to VM memory space based on *partial loading* workflow.

### Load Cell
[load cell]: #load-cell

*Load Cell* syscall has a signature like following:

```c
int ckb_load_cell(void* addr, uint64_t* len, size_t offset, size_t index, size_t source)
{
  return syscall(2071, addr, len, offset, index, source, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 2: output cells.
    + `0x0100000000000002`: output cells with the same running script as current script
    + 3: dep cells.

This syscall would locate a single cell in the current transaction based on `source` and `index` value, serialize the whole cell into the Molecule Encoding [1] format, then use the same step as documented in [Partial Loading](#partial-loading) section to feed the serialized value into VM.

This syscall might return the following errors:

* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.

In case of errors, `addr` and `index` will not contain meaningful data to use.

### Load Cell By Field
[load cell by field]: #load-cell-by-field

*Load Cell By Field* syscall has a signature like following:

```c
int ckb_load_cell_by_field(void* addr, uint64_t* len, size_t offset,
                           size_t index, size_t source, size_t field)
{
  return syscall(2081, addr, len, offset, index, source, field);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 2: output cells.
    + `0x0100000000000002`: output cells with the same running script as current script
    + 3: dep cells.
* `field`: a flag denoting the field of the cell to read, possible values include:
    + 0: capacity in 64-bit unsigned little endian integer value.
    + 1: data hash.
    + 2: lock in the Molecule Encoding format.
    + 3: lock hash.
    + 4: type in the Molecule Encoding format.
    + 5: type hash.
    + 6: occupied capacity in 64-bit unsigned little endian integer value.

This syscall would locate a single cell in current transaction just like *Load Cell* syscall, and then fetches the data denoted by the `field` value. The data is then fed into VM memory space using the *partial loading* workflow.

This syscall might return the following errors:

* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.
* An invalid field value would immediately trigger an VM error and halt execution.
* In some cases certain values are missing(such as requesting type on a cell without type script), the syscall would return `2` as return value then.

In case of errors, `addr` and `index` will not contain meaningful data to use.

### Load Cell Data
[load cell Data]: #load-cell-data

*Load Cell Data* syscall has a signature like following:

```c
int ckb_load_cell_data(void* addr, uint64_t* len, size_t offset,
                       size_t index, size_t source)
{
  return syscall(2092, addr, len, offset, index, source, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 2: output cells.
    + `0x0100000000000002`: output cells with the same running script as current script
    + 3: dep cells.

This syscall would locale a single cell in the current transaction just like *Load Cell* syscall, then locates its cell data section. The cell data is then fed into VM memory space using the *partial loading* workflow.

This syscall might return the following errors:

* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.

In case of errors, `addr` and `index` will not contain meaningful data to use.

### Load Cell Data As Code
[load cell Data As Code]: #load-cell-data-as_code

*Load Cell Data* syscall has a signature like following:

```c
int ckb_load_cell_data_as_code(void* addr, size_t memory_size, size_t content_offset,
                               size_t content_size, size_t index, size_t source)
{
  return syscall(2091, addr, memory_size, content_offset, content_size, index, source);
}
```

The arguments used here are:

* `addr`: a pointer to a buffer in VM memory space used to hold loaded code, must be aligned on a 4KB boundary.
* `memory_size`: the size of memory buffer used to hold code, must be a multiple of 4KB.
* `content_offset`: start offset of code to load in cell data.
* `content_size`: size of code content to load in cell data.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 2: output cells.
    + `0x0100000000000002`: output cells with the same running script as current script
    + 3: dep cells.

This syscall would locale a single cell in the current transaction just like *Load Cell* syscall, then locates its cell data section. But different from *Load Cell Data* syscall, this syscall would load the requested cell data content into VM memory, and marked the loaded memory page as executable. Later CKB VM can then jump to the loaded memory page to execute loaded code. This can be used to implement dynamic linking in CKB VM.

Notice this syscall does not implement *partial loading* workflow.

For now, memory pages marked as executable cannot be reverted to non-executable pages.

This syscall might return the following errors:

* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.
* An unaligned `addr` or `memory_size` would immediately trigger an VM error and halt execution.
* Out of bound`content_offset` or `content_size` values would immediately trigger an VM error and halt execution.
* `content_size` must not be larger than `memory_size`, otherwise it would immediately trigger an VM error and halt execution.

In case of errors, `addr` and `index` will not contain meaningful data to use.

For an example using this syscall, please refer to [this script](https://github.com/nervosnetwork/ckb-miscellaneous-scripts/blob/0759a656c20e652e9ad2711fde0ed96ce9f1130b/c/or.c).

### Load Input
[load input]: #load-input

*Load Input* syscall has a signature like following:

```c
int ckb_load_input(void* addr, uint64_t* len, size_t offset,
                   size_t index, size_t source)
{
  return syscall(2073, addr, len, offset, index, source, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of inputs to read.
* `source`: a flag denoting the source of inputs to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script

This syscall would locate a single cell input in the current transaction based on `source` and `index` value, serialize the whole cell input into the Molecule Encoding [1] format, then use the same step as documented in [Partial Loading](#partial-loading) section to feed the serialized value into VM.

This syscall might return the following errors:
* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.
* When `output cells` or `dep cells` is used in `source` field, the syscall would return with `2` as return value, since cell input only exists for input cells.

In case of errors, `addr` and `index` will not contain meaningful data to use.

### Load Input By Field
[load input by field]: #load-input-by-field

*Load Input By Field* syscall has a signature like following:

```c
int ckb_load_input_by_field(void* addr, uint64_t* len, size_t offset,
                            size_t index, size_t source, size_t field)
{
  return syscall(2083, addr, len, offset, index, source, field);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of inputs to read.
* `source`: a flag denoting the source of inputs to locate, possible values include:
    + 1: inputs.
    + `0x0100000000000001`: input cells with the same running script as current script
* `field`: a flag denoting the field of the input to read, possible values include:
    + 0: out_point in the Molecule Encoding format.
    + 1: since in 64-bit unsigned little endian integer value.

This syscall would locate a single cell input in current transaction just like *Load Cell* syscall, and then fetches the data denoted by the `field` value. The data is then fed into VM memory space using the *partial loading* workflow.

This syscall might return the following errors:
* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.
* When `output cells` or `dep cells` is used in `source` field, the syscall would return with `2` as return value, since cell input only exists for input cells.
* An invalid field value would immediately trigger an VM error and halt execution.

In case of errors, `addr` and `index` will not contain meaningful data to use.

### Load Header
[load header]: #load-header

*Load Header* syscall has a signature like following:

```c
int ckb_load_header(void* addr, uint64_t* len, size_t offset, size_t index, size_t source)
{
  return syscall(2072, addr, len, offset, index, source, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 3: dep cells.
    + 4: header deps.

This syscall would locate the header associated either with an input cell, a dep cell, or a header dep based on `source` and `index` value, serialize the whole header into Molecule Encoding [1] format, then use the same step as documented in [Partial Loading](#partial-loading) section to feed the serialized value into VM.

Note when you are loading the header associated with an input cell or a dep cell, the header hash should still be included in `header deps` section of current transaction.

This syscall might return the following errors:
* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.
* This syscall would return with `2` as return value if requesting a header for an input cell, but the `header deps` section is missing the header hash for the input cell.

In case of errors, `addr` and `index` will not contain meaningful data to use.

#### Loading Header Immature Rule
[loading header immature Rule]: #loading-header-immature-error

Attention that all the blocks referenced in header deps must be 4 epochs ago, otherwise the header is immature and the transaction must wait. For example, if the block is the first block in epoch 4, a transaction with its header as a header dep can only be included in the first block of epoch 8 and later blocks.

This rule will be removed since CKB Edition Mirana as proposed in [RFC36].

[RFC36]: ../0036-remove-header-deps-immature-rule/0036-remove-header-deps-immature-rule.md

### Load Header By Field
[load header by field]: #load-header-by-field

*Load Header By Field* syscall has a signature like following:

```c
int ckb_load_header_by_field(void* addr, uint64_t* len, size_t offset,
                             size_t index, size_t source, size_t field)
{
  return syscall(2082, addr, len, offset, index, source, field);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 3: dep cells.
    + 4: header deps.
* `field`: a flag denoting the field of the header to read, possible values include:
    + 0: current epoch number in 64-bit unsigned little endian integer value.
    + 1: block number for the start of current epoch in 64-bit unsigned little endian integer value.
    + 2: epoch length in 64-bit unsigned little endian integer value.

This syscall would locate the header associated either with an input cell, a dep cell, or a header dep based on `source` and `index` value, and then fetches the data denoted by the `field` value. The data is then fed into VM memory space using the *partial loading* workflow.

Note when you are loading the header associated with an input cell or a dep cell, the header hash should still be included in `header deps` section of current transaction.

This syscall might return the following errors:
* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.
* This syscall would return with `2` as return value if requesting a header for an input cell, but the `header deps` section is missing the header hash for the input cell.
* An invalid field value would immediately trigger an VM error and halt execution.

In case of errors, `addr` and `index` will not contain meaningful data to use.

*Attention** that this syscall also follows [loading header immature rule][].

### Load Witness
[load witness]: #load-witness

*Load Witness* syscall has a signature like following:

```c
int ckb_load_witness(void* addr, uint64_t* len, size_t offset, size_t index, size_t source)
{
  return syscall(2074, addr, len, offset, index, source, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage descripted in [Partial Loading](#partial-loading) section.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 2: output cells.
    + `0x0100000000000002`: output cells with the same running script as current script

This syscall locates a witness entry in current transaction based on `source` and `index` value, then use the same step as documented in [Partial Loading](#partial-loading) section to feed the serialized value into VM.

The `source` field here, is only used a hint helper for script side. As long as one provides a possible `source` listed above, the corresponding witness entry denoted by `index` will be returned.

This syscall might return the following errors:

* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.

In case of errors, `addr` and `index` will not contain meaningful data to use.

### Debug
[debug]: #debug

*Debug* syscall has a signature like following:

```c
void ckb_debug(const char* s)
{
  syscall(2177, s, 0, 0, 0, 0, 0);
}
```

This syscall accepts a null terminated string and prints it out as debug log in CKB. It can be used as a handy way to debug scripts in CKB. This syscall has no return value.

# Reference

* [1]: [Molecule Encoding][1]
* [2]: [VM Syscalls 2][2]

[1]: ../0008-serialization/0008-serialization.md
[2]: ../0034-vm-syscalls-2/0034-vm-syscalls-2.md
