---
Number: "0009"
Category: Standards Track
Status: Proposal
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2018-12-14
---

# VM Syscalls

## Abstract

This document describes all the RISC-V VM syscalls implemented in CKB so far.

## Introduction

CKB VM syscalls are used to implement communications between the RISC-V based CKB VM, and the main CKB process, allowing scripts running in the VM to read current transaction information as well as general blockchain information from CKB. Leveraging syscalls instead of custom instructions allow us to maintain a standard compliant RISC-V implementation which can embrace the broadest industrial support.

## Specification

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
- [Load Transaction]
- [Load Cell]
- [Load Cell By Field]
- [Load Input By Field]
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

### Load Transaction
[load transaction]: #load-transaction

*Load Transaction* syscall has a signature like following:

```c
int ckb_load_tx(void* addr, uint64_t* len, size_t offset)
{
  return syscall(2049, addr, len, offset, 0, 0, 0);
}
```

The arguments used here are:

* `addr`: a pointer to a buffer in VM memory space denoting where we would load the serialized transaction data.
* `len`: a pointer to a 64-bit unsigned integer in VM memory space, when calling the syscall, this memory location should store the length of the buffer specified by `addr`, when returning from the syscall, CKB VM would fill in `len` with the actual length of the buffer. We would explain the exact logic below.
* `offset`: an offset specifying from which offset we should start loading the serialized transaction data.

When calling, this syscall would take the current transaction, and remove:

* `unlock` scripts in all inputs
* `data` part in all outputs
* `type` scripts in all outputs

It then takes the modified transaction and serializes it into the CFB Encoding [1] format. Then the serialized result is fed into VM via the steps below. For ease of reference, we refer the serialized result as `data`, and the length of `data` as `data_length`.

1. A memory read operation is executed to read the value in `len` pointer from VM memory space, we call the read result `size` here.
2. `full_size` is calculated as `data_length - offset`.
3. `real_size` is calculated as the minimal value of `size` and `full_size`
4. The serialized value starting from `&data[offset]` till `&data[offset + real_size]` is written into VM memory space location starting from `addr`.
5. `full_size` is written into `len` pointer
6. `0` is returned from the syscall denoting execution success.

The whole point of this process, is providing VM side a way to do partial reading when the available memory is not enough to support reading the whole data altogether.

One trick here, is that by providing `NULL` as `addr`, and a `uint64_t` pointer with 0 value as `len`, this syscall can be used to fetch the length of the serialized data part without reading any actual data.

### Load Cell
[load cell]: #load-cell

*Load Cell* syscall has a signature like following:

```c
int ckb_load_cell(void* addr, uint64_t* len, size_t offset, size_t index, size_t source)
{
  return syscall(2053, addr, len, offset, index, source, 0);
}
```

The arguments used here are:

* `addr`: the exact same `addr` pointer as used in *Load Transaction* syscall.
* `len`: the exact same `len` pointer as used in *Load Transaction* syscall.
* `offset`: the exact same `offset` value as used in *Load Transaction* syscall.
* `index`: an index value denoting the index of cells to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 0: current cell, in this case `index` value would be ignored since there's only one current cell.
    + 1: input cells.
    + 2: output cells.
    + 3: dep cells.

This syscall would locate a single cell in the current transaction based on `source` and `index` value, serialize the whole cell into the CFB Encoding [1] format, then use the same step as documented in *Load Transaction* syscall to feed the serialized value into VM.

Specifying an invalid source value here would immediately trigger a VM error, specifying an invalid index value here, however, would result in `2` as return value, denoting item missing state. Otherwise the syscall would return `0` denoting success state.

Note this syscall is only provided for advanced usage that requires hashing the whole cell in a future proof way. In practice this is a very expensive syscall since it requires serializing the whole cell, in the case of a large cell with huge data, this would mean a lot of memory copying. Hence CKB should charge much higher cycles for this syscall and encourage using *Load Cell By Field* syscall below.

### Load Cell By Field
[load cell by field]: #load-cell-by-field

*Load Cell By Field* syscall has a signature like following:

```c
int ckb_load_cell_by_field(void* addr, uint64_t* len, size_t offset,
                           size_t index, size_t source, size_t field)
{
  return syscall(2054, addr, len, offset, index, source, field);
}
```

The arguments used here are:

* `addr`: the exact same `addr` pointer as used in *Load Transaction* syscall.
* `len`: the exact same `len` pointer as used in *Load Transaction* syscall.
* `offset`: the exact same `offset` value as used in *Load Transaction* syscall.
* `index`: an index value denoting the index of cells to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 0: current cell, in this case `index` value would be ignored since there's only one current cell.
    + 1: input cells.
    + 2: output cells.
    + 3: dep cells.
* `field`: a flag denoting the field of the cell to read, possible values include:
    + 0: capacity.
    + 1: data.
    + 2: data hash.
    + 3: lock hash.
    + 4: type.
    + 5: type hash.

This syscall would locate a single cell in current transaction just like *Load Cell* syscall, but what's different, is that this syscall would only extract a single field in the specified cell based on `field`, then serialize the field into binary format with the following rules:

* `capacity`: capacity is serialized into 8 little endian bytes, this is also how CFB Encoding [1] handles 64-bit unsigned integers.
* `data`: data field is already in binary format, we can just use it directly, there's no need for further serialization
* `data hash`: 32 raw bytes are extracted from `H256` structure by serializing data field
* `lock hash`: 32 raw bytes are extracted from `H256` structure and used directly
* `type`: type script is serialized into the CFB Encoding [1] format
* `type hash`: 32 raw bytes are extracted from `H256` structure and used directly

With the binary result converted from different rules, CKB VM then applies the same steps as documented in *Load Transaction* syscall to feed data into CKB VM.

Specifying an invalid source value here would immediately trigger a VM error, specifying an invalid index value here, however, would result in `2` as return value, denoting item missing state. Specifying any invalid field will also trigger VM error immediately. Otherwise the syscall would return `0` denoting success state.

### Load Input By Field
[load input by field]: #load-input-by-field

*Load Input By Field* syscall has a signature like following:

```c
int ckb_load_input_by_field(void* addr, uint64_t* len, size_t offset,
                            size_t index, size_t source, size_t field)
{
  return syscall(2055, addr, len, offset, index, source, field);
}
```

The arguments used here are:

* `addr`: the exact same `addr` pointer as used in *Load Transaction* syscall.
* `len`: the exact same `len` pointer as used in *Load Transaction* syscall.
* `offset`: the exact same `offset` value as used in *Load Transaction* syscall.
* `index`: an index value denoting the index of inputs to read.
* `source`: a flag denoting the source of inputs to locate, possible values include:
    + 0: current input, in this case `index` value would be ignored since there's only one current input.
    + 1: inputs.
    + 2: outputs, note this is here to maintain compatibility of `source` flag, when this value is used in *Load Input By Field* syscall, the syscall would always return `2` since output doesn't have any input fields.
    + 3: deps, when this value is used, the syscall will also always return `2` since dep doesn't have input fields.
* `field`: a flag denoting the field of the input to read, possible values include:
    + 0: unlock.
    + 1: out_point.

This syscall would first locate an input in current transaction via `source` and `index` value, it then serialize the extracted field into flatbuffer format, then use the same steps as documented in *Load Transaction* syscall to feed data into VM. Note that we can already use *Load Cell By Field* to load lock hash from input cell, hence this syscall only supports reading original `unlock` data to preserve orthogonality.

Specifying an invalid source value here would immediately trigger a VM error, however specifying `output` as the source here would only result in `2` as return value, specifying `current` as source in a *type* script, which doesn't have input, would also result in `2` as return value. Specifying an invalid index value here, would result in `2` as return value, denoting item missing state. Specifying any invalid field will also trigger VM error immediately. Otherwise the syscall would return `0` denoting success state.

### Load Header Via Cell
[load Header via cell]: #load-header-via-cell

*Load Header Via Cell* syscall has a signature like following:

```c
int ckb_load_header_via_cell(void* addr, uint64_t* len, size_t offset,
                            size_t index, size_t source, size_t field)
{
  return syscall(2056, addr, len, offset, index, source, field);
}
```

The arguments used here are:

* `addr`: the exact same `addr` pointer as used in *Load Transaction* syscall.
* `len`: the exact same `len` pointer as used in *Load Transaction* syscall.
* `offset`: the exact same `offset` value as used in *Load Transaction* syscall.
* `index`: an index value denoting the index of cells to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 0: current cell, in this case `index` value would be ignored since there's only one current cell.
    + 1: input cells.
    + 2: dep cells.
* `field`: a flag denoting the field of the header to read, possible values include:
    + 0: all, read the whole header
    + 1: version.
    + 2: parent_hash.
    + 3: timestamp.
    + 4: number.
    + 5: txs_commit.
    + 6: txs_proposal.
    + 7: difficulty.
    + 8: cellbase_id.
    + 9: uncles_hash.
    + 10: uncles_count.

This syscall would locate an ancestor header via a single cell we indicate based on `source` and `index` value, serialize the whole header into the CFB Encoding [1] format, then use the same step as documented in *Load Transaction* syscall to feed the serialized value into VM.

Specifying an invalid source value here would immediately trigger a VM error, specifying an invalid index value here, however, would result in `2` as return value, denoting item missing state. Otherwise the syscall would return `0` denoting success state.

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

* [1]: CFB Encoding, *citation link pending*
