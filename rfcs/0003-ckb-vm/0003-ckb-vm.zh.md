---
Number: "0003"
Category: Informational
Status: Draft
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2018-08-01
---

# CKB-VM

## 概述

CKB 的 VM 层用于在给定 transaction 的 inputs 与 outputs 的情况下，执行一系列验证条件，以判断 transaction 是否合法并返回结果。

CKB 使用 [RISC-V](https://riscv.org/) 指令集来实现虚拟机层。更精确的说，CKB 使用 rv64imc 指令集架构：基于 [RV64I](https://riscv.org/specifications/) 核心指令集，并添加 RV32M 整型乘除法扩展以及 RVC 指令压缩功能。注意 CKB 不支持浮点数运算，合约开发者如有需要，可以通过添加 softfloat 实现来完成相应功能。

CKB 通过动态链接库的方式，依赖 syscall 来实现链上运算所需的其他功能，比如读取 Cell 的内容，或是其他与 block 相关的普通运算及加密运算。任何支持 RV64I 的编译器 (如 [riscv-gcc](https://github.com/riscv/riscv-gcc), [riscv-llvm](https://github.com/lowRISC/riscv-llvm), [Rust](https://github.com/rust-embedded/wg/issues/218)) 生成的可执行文件均可以作为 CKB VM 中的 script 来运行。

## RISC-V 运行模型

CKB 中使用 64 位的 RISC-V 虚拟机作为 VM 来执行合约。VM 运行在 64 位地址空间下，提供了 RV32I 定义的核心指令集，以及 RV64M 扩展中的整型乘除法的扩展指令。为减小生成的合约大小，CKB 还支持 RVC 指令压缩功能，尽可能减小指令的存储开销。合约会直接使用 Linux 的 ELF 可执行文件格式，以方便对接开源社区的工具及离线调试。

每个合约在 gzip 后最大提供 1MB 的存储空间，解压后的原始合约最大限制为 10 MB。合约运行时，CKB 虚拟机会为合约提供 128 MB 的运行空间，其中包含合约可执行文件映射到虚拟机上的代码页，合约运行时需要的栈空间，堆空间以及外部的 Cell 通过 mmap 映射后的地址页。

为保证合约运行的唯一性及安全性，CKB 虚拟机中的内存及所有寄存器在未被访问之前，均全部写入 0。

合约的运行等同于 Linux 环境下一个可执行文件在单核 CPU 下的运行：

```c
int main(int argc, char* argv[]) {
  uint64_t input_cell_length = 10000;
  void *input_cell = malloc(input_cell_length);
  ckb_load_cell(input_cell, &input_cell_length, 0, 0, CKB_SOURCE_INPUT);

  uint64_t output_cell_length = 10000;
  void *output_cell = malloc(output_cell_length);
  ckb_load_cell(output_cell, &output_cell_length, 0, 0, CKB_SOURCE_OUTPUT);

  // Consume input & output cell

  return 0;
}
```

合约运行从合约 ELF 文件中的 main 函数开始执行，通过 argc 与 argv 提供输入参数进行合约的执行，当 main 函数返回值为 0 时，认为合约执行成功，否则合约执行失败。注意这里的 argc 与 argv 并不保存完整的 inputs 以及 outputs 数据，而是只保留相应的 metadata，对 inputs 与 outputs 的读取则通过单独定义的库与 syscalls 来实现，以便减少不必要的开销。同时 CKB VM 仅为单线程模型，合约文件可以自行提供 coroutine 实现，但是在 VM 层不提供 threading。

基于简化实现以及确定性的考虑，CKB 不提供浮点数运算。如果有对浮点数的需要，我们建议通过引入 softfloat 来实现需求。同时由于 CKB VM 仅为单线程模型，不提供对于原子性操作的支持。

## 辅助库与 Bootloader

为了尽可能减小合约本身的存储开销，CKB 会在 VM 层及 system cell 中提供合约运行所需的辅助库，包括但不限于：libc 中提供的函数，加密库，读写 inputs，outputs 以及其他 Cell 的工具库。所有这些库通过动态链接的形式提供，以确保不占用合约自身的空间。

与此同时 CKB 会提供定制的简化版 bootloader 用于 gcc, llvm 等编译器的链接步骤，以确保省去不必要的开销。

在目前的条件下，对于如下最简单的合约 C 代码：

```c
int main()
{
  return 0;
}
```

编译后的合约代码大小为 628 字节，gzip 后为 313 字节。可以认为这 313 字节为 RISC-V 合约模型下的固定开销。

## 开发语言

CKB 核心只定义了底层的虚拟机模型，理论上任何提供了 RISC-V 后端的语言均可以用来开发 CKB 合约:

* CKB 可以直接使用标准的 riscv-gcc 以及 riscv-llvm 以 C/C++ 语言来进行开发。编译后的可执行文件可以直接作为 CKB 的合约来使用
* 与此相应的，可以将 C 实现的 Bitcoin 以及 Ethereum VM 编译成 RISC-V 二进制代码，保存在公共 Cell 中，然后在合约中引用公共 Cell 来运行 Bitcoin 或者 Ethereum 的合约
* 其他的高级语言 VM 如 [duktape](http://duktape.org/) 及 [mruby](https://github.com/mruby/mruby) 在编译后，也可以用来相应的运行 JavaScript 或者 Ruby 编写的合约
* 相应的也可以使用 [Rust](https://github.com/riscv-rust/rust) 作为实现语言来编写合约

## Runtime Cost

CKB 会选取合适的 RISC-V 开源实现作为运行模型。在执行合约时，可以收集每条指令执行所需的时钟周期。合约执行完毕后，累积的总时钟周期既可作为合约运行的开销。与此同时，我们还会针对读取 Cell 中内容的操作收取合适的运行开销。

## 示例

以下通过一个用户自定义代币(user defined token, or UDT)的发行过程来介绍 CKB 中虚拟机的执行过程。需要注意的是，为了简化说明，这里描述的 UDT 实现经过了一定程度的简化：

* 使用 64 位整数，而不是 256 位整数来保存代币数目
* 使用简化的线性数组与顺序查询的方式代替哈希数据结构存储代币发行情况。同时对代币最多能发给的账户数直接做上限限制
* 同时这里假设所有的账户信息是按字典序顺序排列，于是判断两组数据结构是否相同就简化成了 memcmp 操作，不需要依次遍历数据结构来判断
* 使用 C 的 struct layout 来直接保存数据，省去序列化的步骤

注意，在生产环境 CKB 不会有以上的假设。

### 数据结构

代币信息保存在如下数据结构内：

```c
#define ADDRESS_LENGTH 32
#define MAX_BALANCES 100
#define MAX_ALLOWED 100

typedef struct {
  char address[ADDRESS_LENGTH];
  int64_t tokens;
} balance_t;

typedef struct {
  char address[ADDRESS_LENGTH];
  char spender[ADDRESS_LENGTH];
  int64_t tokens;
} allowed_t;

typedef struct {
  balance_t balances[MAX_BALANCES];
  int used_balance;
  allowed_t allowed[MAX_ALLOWED];
  int used_allowed;

  char owner[ADDRESS_LENGTH];
  char newOwner[ADDRESS_LENGTH];
  int64_t total_supply;
} data_t;
```

对于数据结构有如下的 API 来提供各种操作：

```c
int udt_initialize(data_t *data, char owner[ADDRESS_LENGTH], int64_t total_supply);
int udt_total_supply(const data_t *data);
int64_t udt_balance_of(data_t *data, const char address[ADDRESS_LENGTH]);
int udt_transfer(data_t *data, const char from[ADDRESS_LENGTH], const char to[ADDRESS_LENGTH], int64_t tokens);
int udt_approve(data_t *data, const char from[ADDRESS_LENGTH], const char spender[ADDRESS_LENGTH], int64_t tokens);
int udt_transfer_from(data_t *data, const char from[ADDRESS_LENGTH], const char spender[ADDRESS_LENGTH], const char to[ADDRESS_LENGTH], int64_t tokens);
```

这些方法的实现既可以直接编译到合约中，也可以保存在 Cell 中，通过动态链接的方式来提供。以下会分别介绍两种使用方式。

### 代币发行

假设 CKB 提供如下的方法用来读取 Cell 中的内容：

```c
int ckb_read_cell_data(size_t index, size_t source, void** buffer, size_t* size);
```

即给定 Cell ID，CKB 的虚拟机读取 Cell 中的内容，并映射到当前虚拟机的地址空间中，返回相应的指针，与 Cell 的大小。

这样就可以通过如下的合约来发行代币：

```c
int udt_initialize(data_t *data, char owner[ADDRESS_LENGTH], int64_t total_supply)
{
  memset(&data, 0, sizeof(data_t));
  memcpy(data->owner, owner, ADDRESS_LENGTH);
  memcpy(data->balances[0].address, owner, ADDRESS_LENGTH);

  data->balances[0].tokens = total_supply;
  data->used_balance = 1;
  data->used_allowed = 0;
  data->total_supply = total_supply;

  return 0;
}

int main(int argc, char* argv[]) {
  data_t data;
  ret = udt_initialize(&data, "<i am an owner>", 10000000);
  if (ret != 0) {
    return ret;
  }

  data_t *output_data = NULL;
  ret = ckb_read_cell(0, CKB_SOURCE_OUTPUT, (void **) &output_data, NULL);
  if (ret != 0) {
    return ret;
  }

  if (memcmp(&data, output_data, sizeof(data_t)) != 0) {
    return -1;
  }
  return 0;
}
```

通过验证 Output Cell 中的数据与自行初始化后的 UDT 代币数据是否一致，这里可以确保当前合约及生成数据均是正确的。

### 转账

上述发行代币模型中，验证 Cell 的脚本直接保存在了 input script 中。这里其实也可以通过引用外部 Cell 的方式，调用外部代码来实现验证 Cell 的方法。

考虑 UDT 代币的转账模型，首先有如下基于 C 的实现：

```c
int udt_transfer(data_t *data, const char from[ADDRESS_LENGTH], const char to[ADDRESS_LENGTH], int64_t tokens)
{
  balance_t *from_balance = NULL, *to_balance = NULL;
  int ret = _udt_find_balance(data, from, 1, &from_balance);
  if (ret != 0) {
    return ret;
  }
  ret = _udt_find_balance(data, to, 1, &to_balance);
  if (ret != 0) {
    return ret;
  }
  if (from_balance->tokens < tokens) {
    return ERROR_NOT_SUFFICIENT_BALANCE;
  }
  int target = to_balance->tokens + tokens;
  if (target < to_balance->tokens) {
    return ERROR_OVERFLOW;
  }
  from_balance->tokens -= tokens;
  to_balance->tokens = target;
  return 0;
}
```

其中 `_udt_find_balance` 的作用是给定地址，从当前代币数据结构中找到该地址对应的 `balance_t` 数据结构。如果该地址不存在的话，则在数据结构中创建该地址的条目。在这里我们略去实现，完整的例子可以参考 CKB 代码库。

可以将该函数编译，得到对应的二进制代码：

```c
00000000 <_udt_find_balance>:
   0:   7179                    addi    sp,sp,-48
   2:   d606                    sw      ra,44(sp)
   4:   d422                    sw      s0,40(sp)
   6:   1800                    addi    s0,sp,48
   8:   fca42e23                sw      a0,-36(s0)
   c:   fcb42c23                sw      a1,-40(s0)
  10:   fcc42a23                sw      a2,-44(s0)
  14:   fcd42823                sw      a3,-48(s0)
  18:   fe042623                sw      zero,-20(s0)
  1c:   57fd                    li      a5,-1
  1e:   fef42423                sw      a5,-24(s0)
  22:   a835                    j       5e <.L2>

00000024 <.L5>:
  24:   fec42703                lw      a4,-20(s0)
  28:   87ba                    mv      a5,a4
  2a:   078a                    slli    a5,a5,0x2
  2c:   97ba                    add     a5,a5,a4
  2e:   078e                    slli    a5,a5,0x3
  30:   fdc42703                lw      a4,-36(s0)
  34:   97ba                    add     a5,a5,a4
  36:   02000613                li      a2,32

<omitted ...>
```

CKB 会提供工具链，可以将这里的二进制代码直接作为数据生成 Cell，于是可以有如下的 input script:

```c
typedef int *transfer(data_t *, const char*, const char*, int64_t);

int main(int argc, char* argv[]) {
  data_t *input_data = NULL;
  ret = ckb_read_cell(0, CKB_SOURCE_INPUT, (void **) &input_data, NULL);
  if (ret != 0) {
    return ret;
  }

  data_t *output_data = NULL;
  ret = ckb_read_cell(0, CKB_SOURCE_OUTPUT, (void **) &output_data, NULL);
  if (ret != 0) {
    return ret;
  }

  transfer *f = (transfer *) ckb_mmap_cell(function_cell_id, 0, -1, PROT_EXEC);
  ret = f(input_data, from, to, 100);
  if (ret != 0) {
    return ret;
  }

  if (memcmp(input_data, output_data, sizeof(data_t)) != 0) {
    return -1;
  }
  return 0;
}
```

这里通过 mmap 的方式将一个 Cell 中的内容映射为可以调用的方法，然后调用这个方法来完成转账的目的。这样可以保证方法得到重用，同时也可以减小合约的大小。

### 多方法支持

上面的示例中，虽然转账方法放在了 Cell 中，但是这里的验证方法仍然有一个问题：由于方法是直接 mmap 到内存中，在编译期并不知道 mmap 之后方法所处的内存地址，所以方法的内部实现只能使用局部跳转，无法使用全局跳转。同时在一段内存空间内也只能放入一个验证方法，没有办法支持有多个方法的调用库。

这里我们也可以通过动态链接的方式来使用外部 Cell 提供的辅助库。假设在某一个 Cell 中已经提供了 UDT 代币的所有实现:

```c
int udt_initialize(data_t *data, char owner[ADDRESS_LENGTH], int64_t total_supply);
int udt_total_supply(const data_t *data);
int64_t udt_balance_of(data_t *data, const char address[ADDRESS_LENGTH]);
int udt_transfer(data_t *data, const char from[ADDRESS_LENGTH], const char to[ADDRESS_LENGTH], int64_t tokens);
int udt_approve(data_t *data, const char from[ADDRESS_LENGTH], const char spender[ADDRESS_LENGTH], int64_t tokens);
int udt_transfer_from(data_t *data, const char from[ADDRESS_LENGTH], const char spender[ADDRESS_LENGTH], const char to[ADDRESS_LENGTH], int64_t tokens);
```

于是可以在编译期时直接指定链接方式为动态链接，这样便可以有如下的 input script:

```c
int main(int argc, char* argv[])
{
  data_t *input_data = NULL;
  ret = ckb_read_cell(0, CKB_SOURCE_INPUT, (void **) &input_data, NULL);
  if (ret != 0) {
    return ret;
  }

  data_t *output_data = NULL;
  ret = ckb_read_cell(0, CKB_SOURCE_OUTPUT, (void **) &output_data, NULL);
  if (ret != 0) {
    return ret;
  }

  if (strcmp(argv[4], "initialize") == 0) {
    // processing initialize arguments
    ret = udt_initialize(...);
    if (ret != 0) {
      return ret;
    }
  } else if (strcmp(argv[4], "transfer") == 0) {
    // processing transfer arguments
    ret = udt_transfer(input_data, ...);
    if (ret != 0) {
      return ret;
    }
  } else if (strcmp(argv[4], "approve") == 0) {
    // processing approve arguments
    ret = udt_approve(input_data, ...);
    if (ret != 0) {
      return ret;
    }
  }
  // more commands here

  if (memcmp(input_data, output_data, sizeof(data_t)) != 0) {
    return -1;
  }
  return 0;
}
```

这里所有的 UDT 函数均通过动态链接的方式引用其他 Cell 里的内容，不占用当前 Cell 的空间。

### 更新

任何 CKB-VM 的新版本均不会影响旧有交易的执行结果. 我们在 CKB 硬分叉版本中发布了 CKB-VM version 1 [1].

# 参考

* [1]: [CKB-VM version 1][1]

[1]: ../0000-ckb-vm-version-1/0000-ckb-vm-version-1.md
