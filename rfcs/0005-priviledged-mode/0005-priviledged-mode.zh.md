---
Number: 0005
Category: Informational
Status: Draft
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2018-11-26
---

# CKB VM 中的可选特权架构支持

## 概要

本 RFC 的目标是为 CKB VM 添加可选的特权架构支持。虽然由于 CKB VM 每次只运行一个合约，特权模式在 CKB VM 本身的运行中并不需要，但特权模式对添加 MMU 的支持是很有帮助的，MMU 的存在有利于以下几个场景：

* 实现需要动态内存分配的复杂合约时，MMU 可以帮助避免内存越界错误，增加安全性
* MMU 可以帮助初学者在消耗一定 cycle 的情况下增加安全性

具体来说，我们计划为 CKB VM 增加如下部分：

* 为支持特权模式切换功能，以及指定 page fault 函数功能添加刚刚好足够的 CSR(控制与状态寄存器，control and status register) 指令以及 VM 修改
* 可选的 [TLB](https://en.wikipedia.org/wiki/Translation_lookaside_buffer) 结构

## 基于 CSR 指令的特权模式支持

为尽最大可能确保兼容性，我们会用 [RISC-V 标准](https://riscv.org/specifications/privileged-isa/) 中定义的指令以及流程来实现特权指令支持：

* 首先，我们会实现 RISC-V 标准中定义的 CSR 指令，用于读写控制与状态寄存器 (CSR)。
* 出于简化实现的考虑，我们不会实现 RISC-V 中定义的每一个控制与状态寄存器。目前为止，我们只计划实现 `Supervisor Trap Vector Base Address Register(stvec)` 以及其他在 trap 阶段会被用到的寄存器。在 CKB VM 中读写其他寄存器会立即终止 VM 的运行，并返回错误信息。
* 目前 CKB VM 只用到了两个特权模式级别：`machine` 特权模式以及 `user` 特权模式，在 machine 特权模式中，合约可以自由做任何操作，相应的在 user 特权模式中，合约只可以进行允许的操作。

`stvec` 中指定的 trap 方法 其实就是一个普通的 RISC-V 函数，他与其他普通函数的唯一区别在于它运行在 machine 特权模式上。相对应的，我们也会在 user 特权模式中禁止某些操作，这包括但不限于：

* CSR 指令
* 访问属于 machine 特权级别的内存页
* 用错误的权限访问内存页，如执行没有执行权限内存页上的代码

注意 CKB VM 加载时首先会进入 machine 特权模式，因此不需要特权模式支持的合约可以假装特权模式不存在而继续运行。需要特权模式的合约则可以先进行初始化操作，然后通过 RISC-V 的标准指令 `mret` 切换到 user 特权模式。

## TLB

CKB VM 会添加 TLB 结构辅助 MMU 实现。出于简化实现的考虑，我们会实现具有如下特性的 TLB：

* TLB 中有 64 个条目，每个条目为 4KB (即正好一个内存页)
* TLB 为单路组相联，即两个末尾 6 个 bit 相同的内存页会相互竞争一个条目位置
* 切换特权级别时，整个 TLB 会被全部清空

注意 TLB 只会在 CKB VM 第一次生成 page fault trap 操作时才被初始化。这意味着如果一个合约一直在 machine 特权模式下运行的话，该合约可能永远也不会与 TLB 交互。

TLB 成功初始化之后，在 CKB VM 运行期间即无法再被关闭。
