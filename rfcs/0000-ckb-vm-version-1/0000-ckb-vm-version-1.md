---
Number: "0000"
Category: Informational
Status: Draft
Author: Wanbiao Ye
Organization: Nervos Foundation
Created: 2021-05-25
---

# VM version1

This RFC describes version 1 of the CKB-VM, in comparison to version 0, which

- Fixed several bugs
- Behavioural changes not affecting execution results
- New features
- Performance optimisations

## 1 Fixed Several Bugs

CKB-VM Version 1 has fixed identified bugs discovered in Version 0.

### 1.1 Enabling Stack Pointer SP To Be Always 16-byte Aligned

In the previous version, SP incorrectly aligned during stack initialisation. See [issue](https://github.com/nervosnetwork/ckb-vm/issues/97).

### 1.2 Added a NULL To Argv

C Standard 5.1.2.2.1/2 states: `argv[argc]` should be a null pointer. `NULL` was unfortunately omitted during the initialization of the stack, and now it has returned. See [issue](https://github.com/nervosnetwork/ckb-vm/issues/98).

### 1.3 JALR Caused Erroneous Behaviour on AsmMachine When rs1 and rd utilised the same register

The problem arose with the JALR instruction, where the CKB-VM had made an error in the sequence of its different steps. The correct step to follow would be to calculate the pc first and then update the rd. See [problem](https://github.com/nervosnetwork/ckb-vm/issues/92).

### 1.4 Error OutOfBound was triggered by reading the last byte of memory

We have fixed it, as described in the title.

### 1.5 Unaligned executable pages from loading binary would raise an error

We have fixed it, as described in the title.

### 1.6 Frozen writable pages by error

This error occurred during the loading of elf. The CKB-VM has incorrectly set a freeze flag on a writeable page, which made the page unmodifiable.

It happened mainly with external variables that have dynamic links.

### 1.7 Update crate goblib

goblin is a cross-platform trifecta of binary parsing and loading fun. ckb-vm uses it to load RISC-V programs. But in the past period of time goblin fixed many bugs and produced destructive upgrades, we decided to upgrade goblin: this will cause the binary that could not be loaded before can now be normal Load, or vice versa.

## 2 Behavioural Changes that will not affect the execution outcomes

### 2.1 Skip writing 0 to memory when argc equals 0 during stack initialisation

For ckb scripts, argc is always 0 and the memory is initialised to 0, so memory writing can be safely skipped. Note that when "chaos_mode" is enabled and "argv" is empty, the reading of "argc" will return an unexpected data. This happens uncommonly, and never happens on the mainnet.

### 2.2 Redesign of the internal instruction format

For the sake of fast decoding and cache convenience, RISC-V instruction is decoded into the 64-bit unsigned integer. Such a format used only internally in ckb-vm rather than the original RISC-V instruction format.

## 3 New features

### 3.1 B extension

We have added the RISC-V B extension (v0.92) [1]. This extension aims at covering the four major categories of bit manipulation: counting, extracting, inserting and swapping. The execution of B instructions has been divided into two directions, a slow path and a fast path.  The slow path always generates a context switching overhead. For all B instructions, 1 cycle will be consumed, excluding the followings:

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

Chaos memory mode was added for the debugging tools. Under this mode, the program memory forcibly initializes randomly, helping us to discover uninitialized objects/values in the script.

### 3.3 Suspend/resume a running VM

It is possible to suspend a running CKB VM, save the state to a certain place and to resume the previously running VM later on, possibly even on a different machine.

## 4 Performance optimization

### 4.1 Lazy initialization memory

In version 0, when the VM was initialised, the program memory would be initialised to zero value. Now, we have deferred the initialisation of program memory. The program memory is divided into several different frames, so that only when a frame is used (read, write), the corresponding program memory area of that frame will be initialised with zero value. As a result , small programs that do not need to use large volumes of memory will be able to run faster.

### 4.2 MOP

Macro-Operation Fusion (also Macro-Op Fusion, MOP Fusion, or Macrofusion) is a hardware optimization technique found in many modern microarchitectures whereby a series of adjacent macro-operations are merged into a single macro-operation prior or during decoding. Those instructions are later decoded into fused-µOPs.

The cycle consumption of the merged instructions is the maximum cycle value of the two instructions before the merge. We have verified that the use of MOPs can lead to significant improvements in some encryption algorithms.


|            Opcode            |    Origin    | Cycles |
| ---------------------------- | ------------ | ------ |
| WIDE_MUL                     | mulh + mul   | 5 + 0  |
| WIDE_MULU                    | mulhu + mul  | 5 + 0  |
| WIDE_MULSU                   | mulhsu + mul | 5 + 0  |
| WIDE_DIV                     | div + rem    | 32 + 0 |
| WIDE_DIVU                    | divu + remu  | 32 + 0 |
| FAR_JUMP_REL                 | auipc + jalr | 0 + 3  |
| FAR_JUMP_ABS                 | lui + jalr   | 0 + 3  |
| LD_SIGN_EXTENDED_32_CONSTANT | lui + addiw  | 1 + 0  |

# Reference

* [1]: [B extension][1]

[1]: https://github.com/riscv/riscv-bitmanip
