---
Number: "0000"
Category: Standards Track
Status: Proposal
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2019-04-18
---

# W^X Memory Protection

## Abstract

This RFC suggests adding a new W^X memory feature into CKB VM hoping to simplify the VM implementation significantly, while also improving the security of scripts running in CKB VM.

## Motivation

As of right now, CKB VM does not have MMU. It works quite like CPUs in the very early era or CPUs in some embedded systems: the whole memory block can be readable, writable and executable at the same time. Nothing prevents a script from changing the code running next, or jumping to the stack section and assume the stack just contains code to run.

However, like the early day computers, this architecture has certain problems:

1. It makes the script running in CKB VM very prone to security problems. A buffer overflow, when not managed well, can easily lead to rewriting of code section, which changes the script behavior. On the other hand, specially crafted scripts can also be used to corrupt data section.
2. It also complicates the implementation of CKB VM, when we apply certain optimizations such as [trace cache](https://en.wikipedia.org/wiki/Trace_Cache), we have to add [special code](https://github.com/nervosnetwork/ckb-vm/blob/16207caf5755b5edde6df8228a2366a553960a10/src/machine.rs#L431) to make sure memory writes also invalidates certain trace cache, which is both error-prone and time consuming.

As a result, we suggest adding a small feature into CKB VM named [W^X](https://en.wikipedia.org/wiki/W%5EX), basically, it ensures the memory is either writable or executable. A syscall will be provided to make the conversion between writable memory and executable memory.

For a more complete CPU model with proper MMU unit, it might not be necessary to make this feature mandatory, but we argue that in the sense of CKB VM, having mandatory W^X can actually be extremely useful here:

1. It provides a way for the script to avoid most easily made mistakes out there by having clear distinction between writable memory, and executable memory. Obviously, attacks like [ROP](https://en.wikipedia.org/wiki/Return-oriented_programming) are still possible but W^X can already help with many types of exploits and beginner mistakes.
2. It also simplifies the implementation significantly. In a VM with proper MMU, this won't make much difference, but for CKB VM which already lacks MMU, this can help reduce the last complicated piece in the memory part. In addition, it also enables us to more easily build JIT or even AOT solutions for CKB VM.

## Specification

Following RISC-V specification, CKB VM will divide its running memory into multiple 4KB memory pages. The memory pages will be aligned on a 4KB boundary, meaning the memory pages would start at 0x0, 0x1000, 0x2000, etc. For each memory page, CKB VM will maintain separate flag denoting if the page is writable or executable. Notice the 2 flags will be mutual exclusive, meaning a memory page can either be writable or executable, but not both. The following checks will also be added:

* Before executing an instruction, CKB VM will ensure the memory page containing current instruction is marked executable.
* Before issuing a memory write, CKB VM will ensure the memory page that is written to is marked writable.

Violating either rule above will result in page faults. Handling page faults will be discussed below.

When booting CKB VM, all memory pages will be marked as writable, except for the `LOAD` code sections marked as `executable` in ELF. CKB VM will return immediately with an error when the ELF file tries to load a code section that is both `writable` and `executable`.

When loading a executable code section that is not page aligned in ELF, CKB VM will enlarge the code section just enough to make it aligned to page boundaries. For example, loading an executable code section starting from 0x139080 which spans 0x1320 bytes will result in the memory from 0x139000 till 0x13b000 be marked as executable.

2 syscalls will be added here to handle W^X related logic. For simplicity, we are using the same description format for syscalls as in [../0009-vm-syscalls/0009-vm-syscalls.md].

### Alter Page Permission

*Alter Page Permission* syscall has a signature like following:

```c
int ckb_alter_page_permission(void* addr, size_t len, unsigned char flag)
{
  return syscall(2101, addr, len, flag, 0, 0, 0);
}
```

The arguments used here are:

* `addr`: The starting address of memory to alter permission
* `len`: The length of memory to alter permission, notice this syscall can be used to alter permissions for multiple memory pages at once
* `flag`: Flag denoting memory permission

This syscall would use the flag to update permissions for specified memory ranges. If the specified memory range is not aligned to page boundaries, the syscall would enlarge the memory range just enough to make it aligned to page boundaries. Available flags now are:

* `FLAG_MEMORY_EXECUTABLE`: the memory should be marked executable
* `FLAG_MEMORY_WRITABLE`: the memory should be marked writable

Specifying both flags together will result in `ERROR_INVALID_MEMORY_PERMISSION` error, the exact definitions for all constants here are listed below.

No matter if the operation succeeds, this syscall would consumes 50 initial cycles. It then consumes 50 more cycles for each memory page altered.

### Install Page Fault

*Install Page Fault* syscall has a signature like following:

```c
typedef void (*PAGE_FAULT)(void* addr, void* pc, unsigned char flag);

int ckb_install_page_fault(PAGE_FAULT f)
{
  return syscall(2102, f, 0, 0, 0, 0, 0);
}
```

It only accepts one argument `f`, which indicates a script function to install in case page fault happens. Specifying `0` as the value of `f` uninstalls the page fault function. The usage of page fault function is explained in the next section.

This operation consumes 100 cycles. Notice more cycles will be consumed as usual when the page fault function is executed following the logic described below.

### Page Faults

When CKB VM detects a permission mismatch(such as executing writable memory, or writing executable memory), it would trigger a page fault as following steps:

1. If no page fault function is installed by the user, CKB VM exits immediately with a page fault error.
2. If a page fault function is installed, CKB VM will do a direct jump to page fault function with following arguments:
    * `addr`(stored in `A0` register per convention): the starting address of memory page that result in the page fault.
    * `pc`(stored in `A1` register per convention): the PC address when the page fault happens.
    * `flag`(stored in `A2` register per convention): the correct permission needed for the operation, for example, in the case of writing executable memory, this value would contain `FLAG_MEMORY_WRITABLE`

There are several points regarding jumps to the page fault function:

* Notice this is not a standard RISC-V call, since in a RISC-V standard call, what's stored in `RA` is the instruction after the call instruction, while in this case, we need the exact instruction here so after page fault we can rerun the instruction.
* The original value in `A0`, `A1` and `A2`(in this exact order) will be pushed to the stack before doing the jump, and it's up to the page fault function to restore their original values before resuming normal operation.
* A fixed amount of 100 cycles(like other cycle costs, this should be put as a consensus rule later) will be charged for the page fault operation here.
* After the page fault function is called, if running the instruction(notice the instruction might be different from before the page fault) at the same address result in page fault again, CKB VM will immediately return with an error.

### Constant Definitions

The available error codes are:

* `OK`: 0
* `ERROR_INVALID_MEMORY_PERMISSION`: 1
* `ERROR_INVALID_MEMORY_RANGE`: 2

The available flags are:

* `FLAG_MEMORY_EXECUTABLE`: 0x1
* `FLAG_MEMORY_WRITABLE`: 0x2

## Disadvantages

One obvious disadvantage is that self-modifying code becomes harder to write in CKB VM, it also costs more to write such code since frequent switching between writable and executable memory might be needed. But we want to argue the benefits of introducing this feature outweighs the disadvantages since:

1. It will already be rare to write self-modifying code in CKB VM.
2. Comparing to a full featured MMU, the costs of switching between writable and executable memory is rather low now and might actually still be feasible.
