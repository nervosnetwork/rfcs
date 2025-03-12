---
Number: "0049"
Category: Standards Track
Status: Proposal
Author: Wanbiao Ye <mohanson@outlook.com>
Created: 2023-04-17
---

# VM version2

## Abstract

This RFC delineates the specifications for CKB-VM version 2. CKB-VM version 2 pertains to the version implemented in the CKB Meepo hardfork.

## **Motivation**

The upgrade of CKB-VM in Meepo hardfork aims to enhance the security, portability, and efficiency of scripts. Throughout recent years, several questions have been a source of concern for us:

- We currently lack a secure and straightforward method to invoke one script from another.
    - The **[dynamic library call](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data-as-code)** presents a security concern. The sub-script and parent script share the same memory space, leading to an uncontrolled security risk when calling an unknown sub-script.
    - Although the **[Exec](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0034-vm-syscalls-2/0034-vm-syscalls-2.md#exec)** system call doesn't pose any security issues, it is exceptionally challenging to utilize effectively.
- Running more intricate scripts (such as zero-knowledge proofs) on CKB-VM necessitates higher performance requirements for CKB-VM.

## **Specification**

To address the aforementioned issues, we have implemented the following optimizations for CKB-VM. These optimizations have been thoroughly tested and standardized through the use of RFC.

In comparison to version 1, version 2 of CKB-VM incorporates the following enhancements:

1. One notable addition is the inclusion of a new system call called "Spawn," which can be further explored in the RFC titled "VM Syscalls 3." In essence, Spawn serves as an alternative to dynamic library calls and Exec. With Spawn, a script can create a child script with an independent memory area, and data can be passed between the parent and child scripts without restriction.
2. [Macro-Operation Fusion](https://en.wikichip.org/wiki/macro-operation_fusion). There are 5 MOPs added in VM version 2, there are:

| Opcode |      Origin      |  Cycles   |                            Description                             |
| ------ | ---------------- | --------- | ------------------------------------------------------------------ |
| ADCS   | add + sltu       | 1 + 0     | Overflowing addition                                               |
| SBBS   | sub + sltu       | 1 + 0     | Borrowing subtraction                                              |
| ADD3A  | add + sltu + add | 1 + 0 + 0 | Overflowing addition and add the overflow flag to the third number |
| ADD3B  | add + sltu + add | 1 + 0 + 0 | Similar to ADD3A but the registers order is different              |
| ADD3C  | add + sltu + add | 1 + 0 + 0 | Similar to ADD3A but the registers order is different              |

Detailed matching patterns for the above MOPs(Please note that the registers here are only used for placeholders, and it does not mean that the MOP is only established when r0, r1, r2, r3):

**ADCS rd, rs1, rs2, rs3**

```
add r0, r1, r2
sltu r3, r0, r1
// or
add r0, r2, r1
sltu r3, r0, r1

Activated when:
r0 != r1
r0 != x0
```

**SBBS rd, rs1, rs2, rs3**

```
sub r0, r1, r2
sltu r3, r1, r2

Activated when:
r0 != r1
r0 != r2
```

**ADD3A rd, rs1, rs2, rs3, rs4**

```
add r0, r1, r0
sltu r2, r0, r1
add r3, r2, r4

Activated when:
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

Activated when:
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

Activated when:
r0 != r1
r0 != r4
r3 != r4
r0 != x0
r3 != x0
```
