---
Number: "0014"
Category: Standards Track
Status: Active
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2019-01-04
---

# VM Cycle Limits

## Introduction

This RFC describes cycle limits used to regulate VM scripts.

CKB VM is a flexible VM that is free to implement many control flow constructs, such as loops or branches. As a result, we will need to enforce certain rules in CKB VM to prevent malicious scripts, such as a script with infinite loops.

We introduce a concept called `cycles`, each VM instruction or syscall will consume some amount of cycles. At consensus level, a scalar `max_block_cycles` field is defined so that the sum of cycles consumed by all scripts in a block cannot exceed this value. Otherwise, the block will be rejected. This way we can guarantee all scripts running in CKB VM will halt, or result in error state.

## Consensus Change

As mentioned above, a new scalar `max_block_cycles` field is added to chain spec as a consensus rule, it puts a hard limit on how many cycles a block's scripts can consume. No block can consume cycles larger than `max_block_cycles`.

Note there's no limit on the cycles for an individual transaction or a script. As long as the whole block consumes cycles less than `max_block_cycles`, a transaction or a script in that block are free to consume how many cycles they want.

## Cycle Measures

Here we will specify the cycles needed by each CKB VM instructions or syscalls. Note right now in the RFC, we define hard rules for each instruction or syscall here, in future this might be moved into consensus rules so we can change them more easily.

The cycles consumed for each operation are determined based on the following rules:

1. Cycles for RISC-V instructions are determined based on real hardware that implement RISC-V ISA.
2. Cycles for syscalls are measured based on real runtime performance metrics obtained while benchmarking current CKB implementation.

### Initial Loading Cycles

For each byte loaded into CKB VM in the initial ELF loading phase, 0.25 cycles will be charged. This is to encourage dapp developers to ship smaller smart contracts as well as preventing DDoS attacks using large binaries. Notice fractions will be rounded up here, so 30.25 cycles will become 31 cycles.

### Instruction Cycles

All CKB VM instructions consume 1 cycle except the following ones:

| Instruction | Cycles               |
|-------------|----------------------|
| JALR        | 3                    |
| JAL         | 3                    |
| J           | 3                    |
| JR          | 3                    |
| BEQ         | 3                    |
| BNE         | 3                    |
| BLT         | 3                    |
| BGE         | 3                    |
| BLTU        | 3                    |
| BGEU        | 3                    |
| BEQZ        | 3                    |
| BNEZ        | 3                    |
| LD          | 2                    |
| SD          | 2                    |
| LDSP        | 2                    |
| SDSP        | 2                    |
| LW          | 3                    |
| LH          | 3                    |
| LB          | 3                    |
| LWU         | 3                    |
| LHU         | 3                    |
| LBU         | 3                    |
| SW          | 3                    |
| SH          | 3                    |
| SB          | 3                    |
| LWSP        | 3                    |
| SWSP        | 3                    |
| MUL         | 5                    |
| MULW        | 5                    |
| MULH        | 5                    |
| MULHU       | 5                    |
| MULHSU      | 5                    |
| DIV         | 32                   |
| DIVW        | 32                   |
| DIVU        | 32                   |
| DIVUW       | 32                   |
| REM         | 32                   |
| REMW        | 32                   |
| REMU        | 32                   |
| REMUW       | 32                   |
| ECALL       | 500 (see note below) |
| EBREAK      | 500 (see note below) |

### Syscall Cycles

As shown in the above chart, each syscall will have 500 initial cycle consumptions. This is based on real performance metrics gathered benchmarking CKB implementation, certain bookkeeping logics are required for each syscall here.

In addition, for each byte loaded into CKB VM in the syscalls, 0.25 cycles will be charged. Notice fractions will also be rounded up here, so 30.25 cycles will become 31 cycles.

## Guidelines

In general, the cycle consumption rules above follow certain guidelines:

* Branches are more expensive than normal instructions.
* Memory accesses are more expensive than normal instructions. Since CKB VM is a 64-bit system, loading 64-bit value directly will cost less cycle than loading smaller values.
* Multiplication and divisions are much more expensive than normal instructions.
* Syscalls include 2 parts: the bookkeeping part at first, and a plain memcpy phase. The first bookkeeping part includes quite complex logic, which should consume much more cycles. The memcpy part is quite cheap on modern hardware, hence less cycles will be charged.

Looking into the literature, the cycle consumption rules here resemble a lot like the performance metrics one can find in modern computer architecture.
