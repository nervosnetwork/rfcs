---
Number: 0014
Category: Standards Track
Status: Proposal
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

### Instruction Cycles

All CKB VM instructions consume 1 cycle except the following ones:

| Instruction | Cycles |
|-------------|--------|
| JALR        | 3      |
| JAL         | 3      |
| J           | 3      |
| JR          | 3      |
| BEQ         | 3      |
| BNE         | 3      |
| BLT         | 3      |
| BGE         | 3      |
| BLTU        | 3      |
| BGEU        | 3      |
| BEQZ        | 3      |
| BNEZ        | 3      |
| LD          | 2      |
| SD          | 2      |
| LDSP        | 2      |
| SDSP        | 2      |
| LW          | 3      |
| LH          | 3      |
| LB          | 3      |
| LWU         | 3      |
| LHU         | 3      |
| LBU         | 3      |
| SW          | 3      |
| SH          | 3      |
| SB          | 3      |
| LWSP        | 3      |
| SWSP        | 3      |
| MUL         | 5      |
| MULW        | 5      |
| MULH        | 5      |
| MULHU       | 5      |
| MULHSU      | 5      |
| DIV         | 16     |
| DIVW        | 16     |
| DIVU        | 16     |
| DIVUW       | 16     |
| REM         | 16     |
| REMW        | 16     |
| REMU        | 16     |
| REMUW       | 16     |
| ECALL       | 0      |
| EBREAK      | 0      |

### Syscall Cycles

Each syscall in CKB has different rules for consuming cycles:

#### Load TX

*Load TX* syscall first consumes 10 initial cycles, it then measures the size of the serialized transaction data: for every single byte in the data, it consumes 10 more cycles.

Note that even though the script only requires part of the serialized TX data, the syscall still charges based on the full serialized data size.

#### Load Cell

*Load Cell* syscall first consumes 100 initial cycles, it then measures the size of the serialized cell structure data: for every single byte in the serialized data, it consumes 100 more cycles.

Notice the charged cycles here is 10 times the cycles charged in `Load Cell By Field` syscall, this is because we are discouraging the use of this syscall. One should only use this if they really need the full serialized Cell structure.

Note that even though the script only requires part of the serialized Cell structure data, the syscall still charges based on the full serialized data size.

#### Load Cell By Field

*Load Cell By Field* syscall first consumes 10 initial cycles, it then measures the size of the serialized data from the specified field: for every single byte in the serialized data, it consumes 10 more cycles.

Note that even though the script only requires part of the specified serialized field, the syscall still charges based on the full serialized field size.

#### Load Input By Field

*Load Input By Field* syscall first consumes 10 initial cycles, it then measures the size of the serialized data from the specified field: for every single byte in the serialized data, it consumes 10 more cycles.

Note that even though the script only requires part of the serialized data, the syscall still charges based on the full serialized data size.

#### Debug

*Debug* syscall first consumes 10 initial cycles, it then consumes 10 more cycles for every single byte in the debug parameter string.
