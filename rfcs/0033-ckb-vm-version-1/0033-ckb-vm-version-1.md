---
Number: "0033"
Category: Informational
Status: Draft
Author: Wanbiao Ye <mohanson@outlook.com>
Created: 2021-05-25
---

# CKB VM Version 1 Changes

The following changes have been made to CKB VM version 1 in comparison to version 0:

- Bug fixes
- Behavior changes without affecting execution results
- New features
- Performance optimization

## Bug Fixes

CKB VM version 1 has corrected the following problems found in version 0:

1. Incorrect alignment for the stack pointer. The stack pointer was incorrectly aligned during stack initialization in the previous version. In version 1, the stack pointer is kept 16-byte aligned. For more information, see [issue #97](https://github.com/nervosnetwork/ckb-vm/issues/97).

2. The argv of CKB VM does not end with null. As stated in C Standard 5.1.2.2.1/2, `argv[argc]` must be a null pointer. `NULL` was unfortunately omitted during stack initialization, and it has now returned. For more information, see [issue #98](https://github.com/nervosnetwork/ckb-vm/issues/98).

3. Unexpected behavior caused by the JALR instruction on AsmMachine. The problem arose with the JALR instruction when `rs1` and `rd` use the same register. CKB VM made an error in the sequence of its steps. The correct procedure is to calculate `pc` first and then update `rd`. For more information, see [issue #92](https://github.com/nervosnetwork/ckb-vm/issues/92).

4. OutOfBound error caused by reading the last byte of memory.

5. Unaligned executable pages from loading binary would raise an error.
6. Writeable pages were frozen. This error occurred during the loading of elf. CKB VM incorrectly set a freeze flag on a writeable page, making the page unmodifiable. The problem occurred primarily with external variables that have dynamic links.

7. Crate goblin upgrade. Goblin is a cross-platform trifecta of binary parsing and loading fun. CKB VM uses it to load RISC-V programs. Due to the fact that goblin fixed many bugs and produced destructive upgrades, we decided to upgrade goblin. In this way, the binary that was unable to be loaded in the past can now be loaded normally.

## Behavior Changes Without Affecting Execution Results

### Skip writing 0 to memory when argc equals 0 during stack initialization

For CKB scripts, argc is always 0 and the memory is initialized to 0, so memory writing can be safely skipped. If "chaos_mode" is enabled and "argv" is empty, reading "argc" will result in unexpected data. This rarely occurs and does not occur on the mainnet.

### Redesign of internal instruction format

For the sake of fast decoding and cache convenience, RISC-V instructions are decoded into 64-bit unsigned integers. CKB VM uses this format internally instead of the original RISC-V instruction format.

## New Features

### B extension

We have added the RISC-V B extension (v1.0.0) [1]. This extension aims cover the four major categories of bit manipulation: counting, extracting, inserting and swapping. For all B instructions, 1 cycle will be consumed.

### Chaos memory mode

The debugging tools now support chaos memory mode. In this mode, the program memory is forcibly initialized randomly, helping us identify uninitialized objects and values in the script.

### Suspend and resume a running VM

It is possible to suspend a running CKB VM, save its state to a specified location, and then resume the previously running VM later, potentially on a different machine.

## Performance Optimization

### Lazy initialization memory

In version 0, when the VM was initialized, program memory was initialized to zero. The initialization of program memory has been deferred in version 1. Program memory is divided into several frames, such that only when a frame is read or written, the corresponding program memory area of that frame is initialized to zero. As a result, small programs with low memory requirements can run faster.

### MOP

Macro-Operation Fusion (also Macro-Op Fusion, MOP Fusion, or Macrofusion) is a hardware optimization technique found in many modern microarchitectures whereby a series of adjacent macro-operations are merged into a single macro-operation prior or during decoding. Those instructions are later decoded into fused-OPs.

The cycle consumption of two merged instructions is equal to the maximum cycle value of the two instructions before merging. We have verified that MOPs can significantly improve some encryption algorithms.

|            Opcode            |            Origin            |      Cycles       |
| ---------------------------- | ---------------------------- | ----------------- |
| ADC [2]                      | add + sltu + add + sltu + or | 1 + 0 + 0 + 0 + 0 |
| SBB                          | sub + sltu + sub + sltu + or | 1 + 0 + 0 + 0 + 0 |
| WIDE_MUL                     | mulh + mul                   | 5 + 0             |
| WIDE_MULU                    | mulhu + mul                  | 5 + 0             |
| WIDE_MULSU                   | mulhsu + mul                 | 5 + 0             |
| WIDE_DIV                     | div + rem                    | 32 + 0            |
| WIDE_DIVU                    | divu + remu                  | 32 + 0            |
| FAR_JUMP_REL                 | auipc + jalr                 | 0 + 3             |
| FAR_JUMP_ABS                 | lui + jalr                   | 0 + 3             |
| LD_SIGN_EXTENDED_32_CONSTANT | lui + addiw                  | 1 + 0             |

## Reference

* [1]: [B extension][1]
* [2]: [Macro-op-fusion: Pattern design of ADC and SBB][2]

[1]: https://github.com/riscv/riscv-bitmanip
[2]: https://github.com/nervosnetwork/ckb-vm/issues/169
