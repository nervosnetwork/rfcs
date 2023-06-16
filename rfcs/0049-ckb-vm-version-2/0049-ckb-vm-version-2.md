---
Number: "0049"
Category: Standards Track
Status: Draft
Author: Wanbiao Ye <mohanson@outlook.com>
Created: 2023-04-17
---

# VM version2

This RFC describes version 2 of the CKB-VM, in comparison to version 1, it does the following things:

### 1. Assembly mode implementation for aarch64 architecture.
aarch64 is the 64-bit version of the ARM architecture. aarch64 is increasingly used in a wide range of devices, including smartphones, tablets, and servers. ckb-vm implemented assembly mode on aarch64, running ckb-vm on aarch64 can potentially result in faster execution times and better overall performance.

### 2. Updated the trace cache, which almost doubled the performance of ckb-vm.
If we execute all transactions on the CKB mainnet in order, using the new CKB-VM will reduce the time it [takes from 47 hours and 30 minutes to 25 hours and 15 minutes](https://github.com/nervosnetwork/ckb-vm/pull/271).

### 3. Refactor ckb-vm to make it thread-safe.
Thread-safe ckb-vm can take advantage of modern multi-core CPUs and execute multiple threads in parallel, potentially improving performance and throughput. At the same time, many modern applications and frameworks rely on multi-threading, and a thread-unsafe virtual machine may not be compatible with these technologies.

### 4. We can specify the virtual machine memory size at initialization for spawned scripts.
Allowing the ckb-vm to specify memory size ensures that each workload has access to the resources it needs, without wasting resources on unused memory.

### 5. Implement [A Standard Extension](https://five-embeddev.com/riscv-isa-manual/latest/a.html).
Some third-party libraries may contain atomic instructions, and implementing atomic instructions in the ckb-vm is helpful for code porting.

### 6. [Macro-Operation Fusion](https://en.wikichip.org/wiki/macro-operation_fusion). There are 5 MOPs added in VM version 2, there are:

| Opcode | Origin | Cycles | Description |
| --- | --- | --- | --- |
| ADCS | add + sltu | 1 + 0 | Overflowing addition |
| SBBS | sub + sltu | 1 + 0 | Borrowing subtraction |
| ADD3A | add + sltu + add | 1 + 0 + 0 | Overflowing addition and add the overflow flag to the third number |
| ADD3B | add + sltu + add | 1 + 0 + 0 | Similar to ADD3A but the registers order is different |
| ADD3C | add + sltu + add | 1 + 0 + 0 | Similar to ADD3A but the registers order is different |

Detailed matching patterns for the above MOPs:

**ADCS rd, rs1, rs2, rs3**

```
add r0, r1, r2
sltu r3, r0, r1
// or
add r0, r2, r1
sltu r3, r0, r1

r0 != r1
r0 != x0
```

**SBBS rd, rs1, rs2, rs3**

```
sub r0, r1, r2
sltu r3, r1, r2

r0 != r1
r0 != r2
```

**ADD3A rd, rs1, rs2, rs3, rs4**

```
add r0, r1, r0
sltu r2, r0, r1
add r3, r2, r4

r0 != r1
r0 != r4
r2 != r4
r0 != x0
r2 != x0
```

**ADD3B rd, rs1, rs2, rs3, rs4**

```
add r0, r1, r2
sltu r3, r0, r1
add r3, r3, r4

r0 != r1
r0 != r4
r3 != r4
r0 != x0
r3 != x0
```

**ADD3C rd, rs1, rs2, rs3, rs4**

```
add r0, r1, r2
sltu r3, r0, r1
add r3, r3, r4

r0 != r1
r0 != r4
r3 != r4
r0 != x0
r3 != x0
```
