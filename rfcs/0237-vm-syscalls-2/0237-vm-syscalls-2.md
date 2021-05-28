---
Number: "0237"
Category: Standards Track
Status: Proposal
Author: Wanbiao Ye
Organization: Nervos Foundation
Created: 2021-05-25
---

# VM Syscalls 2

## Abstract

This document describes the addition of the syscalls during the ckb's first hard fork.

- [VM Version]
- [Current Cycles]
- [Exec]

### VM Version
[vm version]: #vm-version

As shown above, *VM Version* syscall has a signature like following:

```c
int ckb_vm_version()
{
  return syscall(2041, 0, 0, 0, 0, 0, 0);
}
```

*VM version* syscall returns current running VM version, so far 2 values will be returned: 0 for Lina CKB-VM version, 1 for the new hardfork version. This syscall consumes 500 cycles.

### Current Cycles
[current cycles]: #current-cycles

*Current Cycles* syscall has a signature like following:

```c
uint64_t ckb_current_cycles()
{
  return syscall(2042, 0, 0, 0, 0, 0, 0);
}
```

*Current Cycles* returns current cycle consumption just before executing this syscall. This syscall consumes 500 cycles.


### Exec
[exec]: #exec

Exec runs an executable file from specified cell data in the context of an already existing machine, replacing the previous executable. The used cycles does not change, but the code, registers and memory of the vm are replaced by those of the new program. It's cycles consumption consists of two parts:

- Fixed 500 cycles
- Initial Loading Cycles [1]

*Exec* syscall has a signature like following:

```c
int ckb_exec(size_t index, size_t source, size_t place, size_t bounds, int argc, char* argv[])
{
  return syscall(2043, index, source, place, bounds, argc, argv);
}
```

The arguments used here are:

* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells or witnesses to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 2: output cells.
    + `0x0100000000000002`: output cells with the same running script as current script
    + 3: dep cells.
* `place`: A value of 0 or 1:
    + 0: read from cell data
    + 1: read from witness
* `bounds`: high 32 bits means `offset`, low 32 bits means `length`. if `length` equals to zero, it read to end instead of reading 0 bytes.
* `argc`: argc contains the number of arguments passed to the program
* `argv`: argv is a one-dimensional array of strings


# Reference

* [1]: [Vm Cycle Limits][1]

[1]: ../0014-vm-cycle-limits/0014-vm-cycle-limits.md
