---
Number: 0005
Category: Informational
Status: Draft
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2018-11-26
---

# Optional priviledged architecture support for CKB VM

## Abstract

This RFC aims to introduce optional priviledged architecture support for CKB VM. While CKB VM doesn't require a priviledged model since it only runs one contract at a time, priviledged model can help bring MMU support, which can be quite useful in the following cases:

* Implementing sophisticated contracts that require dynamic memory allocation, MMU can be used here to prevent invalid memory access for better security.
* Beginners can leverage MMU to trade some cycles for better security.

Specifically, we plan to add the following features to CKB VM:

* Just enough CSR(control and status register) instructions and VM changes to support a) priviledge mode switching and b) page fault function installation.
* An optional [TLB](https://en.wikipedia.org/wiki/Translation_lookaside_buffer) structure

## Privileged mode support via CSR instructions

To ensure maximum compatibility, we will use the exact instructions and workflows defined in the [RISC-V spec](https://riscv.org/specifications/privileged-isa/) to implement priviledge mode support here:

* First, CSR instructions as defined in RISC-V will be implemented in CKB VM to implement read/write on control and status registers(CSR).
* For simplicity reasons, we might not implement every control and status register as defined in RISC-V spec. For now, we are planning to implement `Supervisor Trap Vector Base Address Register(stvec)` and any other register that might be used in the trap phase. Reading/writing other registers will result immediate termination with VM errors as return result.
* For now, CKB VM will only use 2 priviledged modes: `machine` priviledged mode and `user` priviledged mode. In machine mode, the contract is free to do anything, in user mode, on the other hand, the operations will be limited.

The trap function installed in `stvec` is nothing but a normal RISC-V function except that it runs with machine priviledged mode. As a result, we will also add proper permission checkings to prevent certain operations in user mode, which might include but are not limited to:

* CSR instructions
* Accessing memory pages belonging to machine priviledged mode
* Accessing memory pages without correct permissions, for example, it's forbidden to execute a memory page which doesn't have `EXECUTE` permission

Note that when CKB VM first loads, it will be in machine priviledged mode, hence contracts that doesn't need priviledged mode support can act as if privileged mode doesn't exist. Contracts that do leverage priviledged mode, however, can first setup metadata, then switch to user priviledged mode by leveraging RISC-V standard `mret` instruction.

## TLB

To help with MMU, a TLB structure will also be included in CKB VM. For simplicity, we will implement a TLB now with the following characteristics:

* The TLB entry will have 64 entries, each entry is 4KB(exactly 1 memory page).
* The TLB implemented will be one-way associative, meaning if 2 memory pages have the same value for the last 6 bits, they will evict each other.
* Whenever we are switching between different privildged levels, the TLB will be fully flushed.

Notice TLB will only be instantiated when CKB VM is generating the first page fault trap, that means if a contract keeps running in machine mode, the contract might never interact with the TLB.

After a TLB is instantiated, there's no way to turn it down in current CKB VM's lifecycle.
