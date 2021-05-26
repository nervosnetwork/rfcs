---
Number: "0028"
Category: Standards Track
Status: Proposal
Author: Wanbiao Ye
Organization: Nervos Foundation
Created: 2021-05-25
---

# VM version1

This RFC describes the version 1 of CKB-VM. Compared with the version 0, it

- Fix several bugs
- Behavior changes that do not affect execution results
- New features
- Performance optimization

## 1 Fix several bugs

CKB-VM version 1 fixes known bugs discovered in version 0.

### 1.1 Make the stack pointer sp is always 16-byte aligned

SP misalignment during stack initialization in the previous version. See [issues](https://github.com/nervosnetwork/ckb-vm/issues/97).

### 1.2 Add a NULL to argv

The C Standard 5.1.2.2.1/2 says: `argv[argc]` shall be a null pointer. `NULL` was unfortunately forgotten on stack initialization, but now it is back. See [issues](https://github.com/nervosnetwork/ckb-vm/issues/98).

### 1.3 JALR causes wrong behavior on AsmMachine when rs1 and rd use the same register

The problem is with the JALR instruction, CKB-VM made a mistake in the order of its different steps. The correct step is first calculate pc, and then update rd. See [issues](https://github.com/nervosnetwork/ckb-vm/issues/92).

### 1.4 Reading the last byte of memory would trigger OutOfBound error

As the title describes, we have fixed it.

### 1.5 Loading binary with unaligned executable page would trigger error

As the title describes, we have fixed it.

### 1.6 Writable page frozen by error

This bug occurred during elf loading. CKB-VM incorrectly set the freeze flag on the writable page, this makes this page can no longer be modified.

It mainly occurs on the external variables with dynamic link.

### 1.7 Update crate goblib

goblin is a cross-platform trifecta of binary parsing and loading fun. ckb-vm uses it to load RISC-V programs. But in the past period of time goblin fixed many bugs and produced destructive upgrades, we decided to upgrade goblin: this will cause the binary that could not be loaded before can now be normal Load, or vice versa.

https://github.com/m4b/goblin/blob/master/CHANGELOG.md#040---2021-4-11

## 2 Behavior changes that do not affect execution results

### 2.1 Skip writing 0 to the memory when argc is 0 during stack initialization

For ckb scripts, argc is always 0 and the memory is initialized to 0, so memory writing can be safely skipped. It should be noted that when "chaos_mode" enabled and "argv" is empty, reading "argc" will return an unexpected data. This situation is not very common and it never happened on mainnet.

### 2.2 Redesign inner instruction format

For fast decoding and cache friendly, RISC-V instruction is decoded into 64 bit unsigned integer. This format is only used inside ckb-vm and not the original RISC-V instruction format.

## 3 New features

### 3.1 B extension

We have added the RISC-V B extension(v0.92) [1]. The overall goal of this extension is covering the four major categories of bit manipulation: Count, Extract, Insert, Swap. The execution of the B instruction is divided into two directions, the slow path and the fast path. The slow path will always generate a context switch overhead.  All B instructions consume 1 cycle except the following ones:

| Instruction |        Cycles        |
| ----------- | -------------------- |
| GREV        | CONTEXT_SWITCH + 20  |
| GREVI       | CONTEXT_SWITCH + 20  |
| GREVW       | CONTEXT_SWITCH + 18  |
| GREVIW      | CONTEXT_SWITCH + 18  |
| SHFL        | CONTEXT_SWITCH + 20  |
| UNSHFL      | CONTEXT_SWITCH + 20  |
| SHFLI       | CONTEXT_SWITCH + 20  |
| UNSHFLI     | CONTEXT_SWITCH + 20  |
| SHFLW       | CONTEXT_SWITCH + 18  |
| UNSHFLW     | CONTEXT_SWITCH + 18  |
| GORC        | CONTEXT_SWITCH + 20  |
| GORCI       | CONTEXT_SWITCH + 20  |
| GORCW       | CONTEXT_SWITCH + 18  |
| GORCIW      | CONTEXT_SWITCH + 18  |
| BFP         | CONTEXT_SWITCH + 15  |
| BFPW        | CONTEXT_SWITCH + 15  |
| BDEP        | CONTEXT_SWITCH + 350 |
| BEXT        | CONTEXT_SWITCH + 270 |
| BDEPW       | CONTEXT_SWITCH + 180 |
| BEXTW       | CONTEXT_SWITCH + 140 |
| CLMUL       | CONTEXT_SWITCH + 320 |
| CLMULR      | CONTEXT_SWITCH + 380 |
| CLMULH      | CONTEXT_SWITCH + 400 |
| CLMULW      | CONTEXT_SWITCH + 60  |
| CLMULRW     | CONTEXT_SWITCH + 60  |
| CLMULHW     | CONTEXT_SWITCH + 60  |
| CRC32B      | CONTEXT_SWITCH + 15  |
| CRC32H      | CONTEXT_SWITCH + 30  |
| CRC32W      | CONTEXT_SWITCH + 45  |
| CRC32D      | CONTEXT_SWITCH + 60  |
| CRC32CB     | CONTEXT_SWITCH + 15  |
| CRC32CH     | CONTEXT_SWITCH + 30  |
| CRC32CW     | CONTEXT_SWITCH + 45  |
| CRC32CD     | CONTEXT_SWITCH + 60  |
| BMATFLIP    | CONTEXT_SWITCH + 40  |
| BMATOR      | CONTEXT_SWITCH + 500 |
| BMATXOR     | CONTEXT_SWITCH + 800 |

Where CONTEXT_SWITCH = 500.

### 3.2 Chaos memory mode

Chaos memory mode added for the debug tools. In this mode, the program memory is forced to initialize randomly, this helps us discover uninitialized objects/values in scripts.

### 3.3 Suspend/resume a running VM

It's able to suspend a running CKB VM, save the states somewhere, and resume the previously running VM at a latter time, or even on a different machine.

## 4 Performance optimization

### 4.1 Lazy initialization memory

In the version 0, program memory will be initialized with zero value when the virtual machine is initialized. Now, we have delayed the initialization time of the program memory. The program memory is divided into several different frames, and only when a frame is used (read, write), the program memory area corresponding to the frame will be initialized with a zero value. This effectively improves the running speed of small programs that do not need to use too much memory.

### 4.2 MOP

Macro-Operation Fusion (also Macro-Op Fusion, MOP Fusion, or Macrofusion) is a hardware optimization technique found in many modern microarchitectures whereby a series of adjacent macro-operations are merged into a single macro-operation prior or during decoding. Those instructions are later decoded into fused-µOPs.

The cycle consumption of the merged instruction is the maximum value of cycles of the two instructions before the merge. We have confirmed that in some cryptographic algorithms, the use of MOP can bring huge improvements.


|            Opcode            |    Origin    | Cycles |
| ---------------------------- | ------------ | ------ |
| WIDE_MUL                     | mulh + mul   | 5 + 0  |
| WIDE_MULU                    | mulhu + mulu | 5 + 0  |
| WIDE_DIV                     | div + rem    | 32 + 0 |
| WIDE_DIVU                    | divu + remu  | 32 + 0 |
| FAR_JUMP_REL                 | auipc + jalr | 0 + 3  |
| FAR_JUMP_ABS                 | lui + jalr   | 0 + 3  |
| LD_SIGN_EXTENDED_32_CONSTANT | lui + addiw  | 1 + 0  |
| LD_ZERO_EXTENDED_32_CONSTANT | lui + addiwu | 1 + 0  |

# Reference

* [1]: [B extension][1]

[1]: https://github.com/riscv/riscv-bitmanip
