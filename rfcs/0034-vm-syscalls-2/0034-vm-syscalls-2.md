---
Number: "0034"
Category: Standards Track
Status: Proposal
Author: Wanbiao Ye <mohanson@outlook.com>
Created: 2021-05-25
---

# CKB VM Syscalls 2

## Abstract

This document describes the addition of the syscalls in CKB2021. These syscalls are only available since CKB VM version 1 and CKB2021 [2].

- [VM Version]
- [Current Cycles]
- [Exec]

### VM Version
[vm version]: #vm-version

The *VM Version* syscall has a signature like this:

```c
int ckb_vm_version()
{
  return syscall(2041, 0, 0, 0, 0, 0, 0);
}
```

The *VM version* syscall returns the current VM version. So far, two values will be returned:

- Lina CKB VM version error
- 1 for the CKB VM version of the new hardfork 

This syscall consumes 500 cycles.

### Current Cycles
[current cycles]: #current-cycles

The *Current Cycles* syscall has a signature like this:

```c
uint64_t ckb_current_cycles()
{
  return syscall(2042, 0, 0, 0, 0, 0, 0);
}
```

The *Current Cycles* syscall returns the number of cycles that were consumed just before the syscall was executed. This syscall consumes 500 cycles.


### Exec
[exec]: #exec

Exec runs an executable file from specified cell data in the context of an already existing machine, replacing the previous executable. The used cycles do not change, however the code, registers and memory of the VM are replaced by those of the new program. The used cycles are in two parts:

- Fixed 500 cycles
- Initial loading cycles [1]

The *Exec* syscall has a signature like this:

```c
int ckb_exec(size_t index, size_t source, size_t place, size_t bounds, int argc, char* argv[])
{
  return syscall(2043, index, source, place, bounds, argc, argv);
}
```

Here are the arguments:

* `index`: an index value that indicates the index of entries to read
* `source`: a flag that indicates the source of cells or witnesses to locate. Possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 2: output cells.
    + `0x0100000000000002`: output cells with the same running script as current script
    + 3: dep cells.
* `place`: a value of 0 or 1
    + 0: read from cell data
    + 1: read from witness
* `bounds`: 
    * The high 32 bits means `offset`.
    * The low 32 bits means `length`. If `length` is zero, it reads to the end instead of reading zero bytes.
* `argc`: the number of arguments passed to the program
* `argv`: a one-dimensional array of strings.


# Reference

* [1]: [Vm Cycle Limits][1]
* [2]: [CKB VM Version Selection][2]

[1]: ../0014-vm-cycle-limits/0014-vm-cycle-limits.md
[2]: ../0032-ckb-vm-version-selection/0032-ckb-vm-version-selection.md

