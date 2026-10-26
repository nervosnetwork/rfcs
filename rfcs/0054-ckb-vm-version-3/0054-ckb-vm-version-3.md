---
Number: "0054"
Category: Standards Track
Status: Draft
Author: Wanbiao Ye <mohanson@outlook.com>
Created: 2025-12-23
---

# VM version3

## Abstract

This RFC delineates the specifications for CKB-VM version 3.

## CFI (Control Flow Integrity) Extension Support

The primary enhancement in this version is the introduction of the RISC-V CFI (Control Flow Integrity) extension support, which provides hardware-level security protection against control flow hijacking attacks such as ROP (Return-Oriented Programming) through shadow stack mechanisms.

The latest version of the specification is located at:

- <https://github.com/riscv/riscv-isa-manual/blob/main/src/priv-cfi.adoc>
- <https://github.com/riscv/riscv-isa-manual/blob/main/src/unpriv-cfi.adoc>

In the RISC-V architecture, the function call mechanism relies on the ra (return address) register to store the return address. When executing a function jump, the processor writes the return address into the ra register. For nested function call scenarios, since there is only one ra register, the current return address in ra must be saved to the stack for later restoration.

This design introduces a critical security risk: if an attacker can corrupt the stack contents through some means (such as buffer overflow vulnerabilities), they can tamper with the return address saved on the stack. This is the core principle of ROP (Return-Oriented Programming) or JOP attacks. Attackers hijack the program's control flow through carefully constructed gadgets (code snippets) chains, thereby achieving arbitrary code execution.

In CKB smart contracts, this attack threat is particularly severe. When stack content is corrupted, attackers can possibly bypass all security checks simply by redirecting the return address to syscall exit with an exit code of 0, effectively disabling the contract's verification logic. Unlike traditional exploits requiring complex ROP chains, this attack vector is remarkably simple yet devastating in its impact.

Therefore, protection mechanisms for the stack, especially integrity verification of return addresses, are crucial for ensuring the security of CKB-VM. This is also the fundamental motivation for introducing the CFI (Control Flow Integrity) extension.

For CKB-VM, the core focus is on the Unprivileged ISA part, which introduces the following 6 new instructions:

1. **LPAD (Landing Pad)**: Marks legal indirect jump target locations for forward-edge protection
2. **SSPUSH (Shadow Stack Push)**: Pushes the return address onto the shadow stack
3. **SSPOPCHK (Shadow Stack Pop and Check)**: Pops the return address from the shadow stack and verifies its integrity
4. **SSRDP (Shadow Stack Read Pointer)**: Reads the shadow stack pointer
5. **SSAMOSWAP.W (Shadow Stack Atomic Swap)**: Atomically swaps values on the shadow stack
6. **SSAMOSWAP.D (Shadow Stack Atomic Swap)**: Atomically swaps values on the shadow stack

The cycles cost for these instructions are defined as follows:

| Instruction | Cycle Cost |
|-------------|------------|
| LPAD        | 3          |
| SSPUSH      | 3          |
| SSPOPCHK    | 3          |
| SSRDP       | 3          |
| SSAMOSWAP.W | 4          |
| SSAMOSWAP.D | 4          |

The core mechanism of these instructions is the Shadow Stack: in addition to the regular program stack, the hardware maintains an independent shadow stack dedicated to storing return addresses. When a function call occurs, the return address is saved on both the regular stack and the shadow stack; upon function return, the hardware verifies that the return addresses on both stacks are consistent. Since the shadow stack is invisible to normal memory access instructions, even if attackers can corrupt the regular stack, they cannot synchronously tamper with the shadow stack, thus achieving return address integrity protection.

In addition to the regular 4MB of memory, ckb-vm maintains a **64KB** shadow stack.

In addition to the CKB-VM flag itself, the spec requires an additional ELF flag. Consider a scenario: a contract that has not enabled the `Zicfilp` extension (such as an old contract) needs to be guaranteed to still run normally. Because it does not contain `LPAD` instructions, and according to the specification, when this extension is enabled, the system will perform checks, and if the corresponding LPAD instruction is missing, it will directly report an error. Therefore, there is an additional flag in the ELF file. The spec states:

> Compilers and linkers should provide an attribute flag to indicate if the program has been compiled with the Zicfilp extension and use that to determine if the Zicfilp extension should be activated.
>

When this additional flag is not enabled, LPAD will be treated as a no-op. This flag depends on the compiler's implementation. LLVM currently places the information in the `.note.gnu.property` section.

It is worth noting that `Zicfiss` also has the same flag. You can use llvm-readelf to read the flag:

```bash
llvm-readelf -n build/your_program_with_cfi
Displaying notes found in: .note.gnu.property
Owner                Data size 	Description
GNU                  0x00000010	NT_GNU_PROPERTY_TYPE_0 (property note)
    Properties:    RISC-V feature: ZICFISS
```

See [code](https://github.com/llvm/llvm-project/blob/66b481556e01e6e2508d7c9146849167b9e0323f/llvm/include/llvm/BinaryFormat/ELF.h#L1909-L1913):

```C
// RISC-V processor feature bits.
enum : unsigned {
    GNU_PROPERTY_RISCV_FEATURE_1_CFI_LP_UNLABELED = 1 << 0,
    GNU_PROPERTY_RISCV_FEATURE_1_CFI_SS = 1 << 1,
    GNU_PROPERTY_RISCV_FEATURE_1_CFI_LP_FUNC_SIG = 1 << 2,
};
```

These flags are very useful. For example, in the implementation, when GNU_PROPERTY_RISCV_FEATURE_1_CFI_SS is not enabled, all shadow stack related instructions can be directly translated to no-ops at the decode stage.

## References

- [RISC-V CFI Specification](https://github.com/riscv/riscv-cfi)
- [RISC-V Unprivileged ISA Manual - CFI](https://github.com/riscv/riscv-isa-manual/blob/main/src/unpriv-cfi.adoc)
- [RISC-V Privileged ISA Manual - CFI](https://github.com/riscv/riscv-isa-manual/blob/main/src/priv-cfi.adoc)
- [Return-Oriented Programming (Wikipedia)](https://en.wikipedia.org/wiki/Return-oriented_programming)
