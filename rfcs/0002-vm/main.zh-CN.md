# VM

```
Author: Xuejie Xiao <x@nervos.org>
Category: CKB
Start Date: 2018-08-01
```

## 概述

CKB 的 VM 层用于在给定 transction 的 inputs 与 outputs 的情况下，执行一系列验证条件，以判断 transaction 是否合法并返回结果。

CKB 使用 [RISC-V](https://riscv.org/) 指令集来实现虚拟机层。更精确的说，CKB 使用 rv32imc 指令集架构：基于 [RV32I](https://riscv.org/specifications/) 核心指令集，并添加 RV3
2M 整型乘除法扩展，以及 RVC 指令压缩功能。注意目前 CKB 并不支持浮点数运算以及原子性内存操作，如有需要将在未来版本中考虑引入。

CKB 通过动态链接库的方式，依赖 syscall 来实现链上运算所需的其他功能，比如读取 Cell 的内容，或是其他与 block 相关的普通运算及加密运算。任何支持 RV32I 的编译器 (如 [riscv-gcc](https://github.com/riscv/riscv-gcc), [riscv-llvm](https://github.com/lowRISC/riscv-llvm), [Rust](https://github.com/riscv-rust/rust)) 生成的可执行文件均可以作为 CKB VM 中的 script 来运行。

## RISC-V 运行模型

CKB 中使用 32 位的 RISC-V 虚拟机作为 VM 来执行合约。VM 运行在 32 位地址空间下，提供了 RV32I 核心的 38 条指令，以及 RV32M 扩展中的 4 条整型乘除法的扩展。为减小生成的合约大小，CKB 还支持 RVC 指令压缩功能，尽可能减小指令的存储开销。合约会直接使用 Linux 的 ELF 可执行文件格式，以方便对接开源社区的工具及离线调试。

每个合约在 gzip 后最大提供 1MB 的存储空间，解压后的原始合约最大限制为 10 MB。合约运行时，CKB 虚拟机会为合约提供 128 MB 的运行空间，其中包含合约可执行文件映射到虚拟机上的代码页，合约运行时需要的栈空间，堆空间以及外部的 Cell 通过 mmap 映射后的地址页。

为保证合约运行的唯一性及安全性，CKB 虚拟机中的内存及所有寄存器在未被访问之前，均全部写入 0。

合约的运行等同于 Linux 环境下一个可执行文件在单核 CPU 下的运行：

```c
int main(int argc, char* argv[]) {
  if (argc != 7) {
    return -1;
  }

  const char *input_signature = (const char *) argv[0];
  int input_cell_number = (int) argv[1];
  int *input_cell_lengths = (int *) argv[2];
  void **input_cells = (void **) argv[3];
  int output_cell_number = (int) argv[4];
  int *output_cell_lengths = (int *) argv[5];
  void **output_cells = (void **) argv[6];

  // processing and validating data

  return 0;
}
```

合约运行从合约 ELF 文件中的 main 函数开始执行，通过 argc 与 argv 提供输入参数进行合约的执行，当 main 函数返回值为 0 时，认为合约执行成功，否则合约执行失败。注意这里的 argc 与 argv 并不保存完整的 inputs 以及 outputs 数据，而是只保留相应的 metadata，对 inputs 与 outputs 的读取则通过单独定义的 IO syscall 与 mmap syscall 来实现，以便减少不必要的开销。同时 CKB VM 仅为单线程模型，合约文件可以自行提供 coroutine 实现，但是在 VM 层不提供 threading。

目前基于简化实现的考虑，CKB 并不提供浮点数运算。同时由于 CKB 为单线程模型，并不需要 RISC-V 的原子性内存操作。在将来版本如有需要，可能会考虑引入浮点数运算以及 V 向量扩展方便加密库的高性能实现。

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

TBD

## 示例

### 银行模型

这里以一个最简单的银行模型为例，Cell 中保存所有人的账户信息，Cell 之间维护的不变量为账户总余额不变。为简化模型，目前先不考虑发行与销毁代币数。

假设账户信息保存在如下的 struct 内：

```c
typedef struct {
  char account_id[256];
  int64_t amount;
} Account;

typedef struct Bank {
  int account_number;
  Account *accounts;
} Bank;
```

可以实现如下的验证脚本：

```c
// Should be loaded from provided function
extern int ckb_check_signature(const char* sig);
extern void* ckb_mmap_cell(int cell_id, size_t offset, size_t length, uint32_t flags);

int64_t check_and_sum_amount(Bank *bank) {
  int64_t total_amount = 0;
  if (bank->account_number > 1024) {
    // Too many accounts!!
    return -3;
  }
  for (int i = 0; i < bank->account_number; i++) {
    if (bank->accounts[i].amount < 0) {
      // Invalid account amount
      return -4;
    }
    int64_t t = total_amount + bank->accounts[i].amount;
    if (t < total_amount) {
      // Overflow issue
      return -5;
    }
    total_amount = t;
  }
  return total_amount;
}

int main(int argc, char* argv[]) {
  if (argc != 5) {
    return -1;
  }

  if (ckb_check_signature(argv[0] != 0)) {
    return -2;
  }

  if (((int) argv[1]) != 1) {
    return -1;
  }
  Bank *input = (Bank *) ckb_mmap_cell((int) argv[2][0], 0, -1, 0);
  if (((int) argv[3]) != 1) {
    return -1;
  }
  Bank *output = (Bank *) ckb_mmap_cell((int) argv[4][0], 0, -1, 0);

  int64_t input_total_amount = check_and_sum_amount(input);
  if (input_total_amount < 0) {
    return input_total_amount;
  }

  int64_t output_total_amount = check_and_sum_amount(output);
  if (output_total_amount < 0) {
    return output_total_amount;
  }

  if (input_total_amount != output_total_amount) {
    return -6;
  }
  return 0;
}
```

这里依次验证了如下数据：

* 签名检查，这里使用动态链接的外部库来实现
* Transaction 中只有 1 个 input cell，以及 1 个 output cell
* Cell 中保存的账户总数不能超过 1024 个
* 每一个账户中的余额不能为负
* 账户余额的总和不能超过 64 位有符号整数的最大值
* 输入 cell 与输出 cell 中的余额相等

另外需要指出的一点是，这里为了简化说明，直接利用了 C struct 的 memory layout 格式来保存输入输出数据。在实际环境中，根据需求的不同，也可以使用其他的序列化工具来保存数据。

上述合约代码在未链接 libc 的情况下，编译后为 1112 字节，gzip 后为 714 字节。

### 众筹

在上述银行模型中，验证 Cell 的脚本保存在了 input script 之中，这里考虑一个把 Cell 验证代码放入 Cell type 的例子。

考虑一个最简单的众筹应用：发起人可以设定目标，当达到目标，发起人可以获得所有 Cell 的 Capacity，投资人可以取消众筹。

首先定义如下的数据结构:

```c
typedef enum {
  UNFULFILLED,
  FULFILLED
} Status;

typedef struct {
  char account_id[256];
  char digest[1024];
  int64_t amount;
} Investment;

typedef struct {
  char account_id[256];
  char digest[1024];
  Status status;
  int64_t total_fund;
  int investment_number;
  Investment *investments;
} Crowdfunding;
```

于是众筹当前的 Cell 自身可以有如下的验证函数：

```c
int validate_crowdfunding(const Crowdfunding* crowdfunding) {
  if (crowdfunding->investment_number > 10000) {
    return -10;
  }
  int64_t current_fund = 0;
  for (int i = 0; i < crowdfunding->investment_number; i++) {
    if (crowdfunding->investments[i].amount < 0) {
      return -11;
    }
    int t = current_fund + crowdfunding->investments[i].amount;
    if (t < current_fund) {
      return -12;
    }
    current_fund = t;
  }
  Status target_status = UNFULFILLED;
  if (current_fund > crowdfunding->total_fund) {
    target_status = FULFILLED;
  }
  if (crowdfunding->status != target_status) {
    return -13;
  }
  return 0;
}
```

编译后，在得到的 .o 文件中包含如下的二进制代码：

```c
00000000 <validate_crowdfunding>:                                                                                                                                        [84/1782]
   0:   7139                    addi    sp,sp,-64
   2:   de22                    sw      s0,60(sp)
   4:   0080                    addi    s0,sp,64
   6:   fca42623                sw      a0,-52(s0)
   a:   fcc42703                lw      a4,-52(s0)
   e:   4b14                    lw      a3,16(a4)
  10:   6709                    lui     a4,0x2
  12:   71070713                addi    a4,a4,1808 # 2710 <.L3+0x2600>
  16:   00d75463                ble     a3,a4,1e <.L2>
  1a:   57d9                    li      a5,-10
  1c:   a8d5                    j       110 <.L3>

0000001e <.L2>:
  1e:   4681                    li      a3,0
  20:   4701                    li      a4,0
  22:   fed42423                sw      a3,-24(s0)
  26:   fee42623                sw      a4,-20(s0)
  2a:   fe042223                sw      zero,-28(s0)
  2e:   a841                    j       be <.L4>

00000030 <.L9>:
  30:   fcc42703                lw      a4,-52(s0)
  34:   4b54                    lw      a3,20(a4)
  36:   fe442603                lw      a2,-28(s0)

<omitted ...>
```

在众筹 Cell 中，可以约定每个 Cell 的前 1K 数据包含用于验证的代码。CKB 可以在工具链中提供从 `.o` 文件中抓取必要的二进制部分，并执行相应检查的工具（比如保证代码中只有相对跳转，没有绝对跳转）。然后在构造 Cell 的数据的时候，保证前 1K 部分只包含这里的验证代码。

于是可以有如下的 input script：

```c
// Should be loaded from provided function
extern int ckb_check_signature(const char* sig);

typedef enum {
  CREATE;
  FUND;
  UNFUND;
} CommandType;

typedef struct {
  CommandType command_type;
  char account_id[256];
  char digest[1024];
  int64_t amount;
} Command;

typedef int (*ValidateFunction)(const Crowdfunding*);

int main(int argc, char* argv[]) {
  if (argc != 6) {
    return -1;
  }

  if (ckb_check_signature(argv[0] != 0)) {
    return -2;
  }

  if (((int) argv[3]) < 1) {
    return -1;
  }
  Crowdfunding *output = (Bank *) ckb_mmap_cell((int) argv[4][0], 0x400, -1, 0);

  Command *command = (Command *) argv[5];

  ValidateFunction *f = (ValidateFunction *) ckb_mmap_cell((int) argv[4][0], 0, 0x400, PROT_EXEC);

  switch (command->command_type) {
    case CREATE:
      {
        if(f(output) != 0) {
          return -1;
        }
      }
      break;
    case FUND:
      {
        Crowdfunding *input = (Bank *) ckb_mmap_cell((int) argv[2][0], 0x400, -1, 0);
        if (output->investment_number != input->investment_number + 1) {
          return -1;
        }
        if (memcmp(output->investments[output->investment_number - 1].account_id,
                   command->account_id) != 0) {
          return -1;
        }
        if (memcmp(output->investments[output->investment_number - 1].digest,
                   command->digest) != 0) {
          return -1;
        }
        if(f(output) != 0) {
          return -1;
        }
      }
      break;
    case UNFUND:
      {
        Crowdfunding *input = (Bank *) ckb_mmap_cell((int) argv[2][0], 0x400, -1, 0);
        if (output->investment_number != input->investment_number - 1) {
          return -1;
        }
        int found = 0;
        for (int i = 0; i < input->investment_number; i++) {
          if (memcmp(input->investments[i].account_id, command->account_id) == 0) {
            found = 1;
            break;
          }
        }
        if (!found) {
          return -1;
        }
        found = 0;
        for (int i = 0; i < output->investment_number; i++) {
          if (memcmp(output->investments[i].account_id, command->account_id) == 0) {
            found = 1;
            break;
          }
        }
        if (found) {
          return -1;
        }
        if(f(output) != 0) {
          return -1;
        }
      }
      break;
  }

  return 0;
}

```

### 投票

上面的众筹示例中，虽然将众筹数据的验证方法放在了 Cell 中，但是这里的验证方法仍然有一个问题：由于方法是直接 mmap 到内存中，在编译期并不知道 mmap 之后方法所处的内存地址，所以只能使用局部跳转，无法使用全局跳转。同时在一段内存空间内也只能放入一个验证方法，没有办法支持有多个方法的调用库。

接下来这里通过投票的例子来展示 CKB 中如何使用外部调用库。注意这里的例子同样适用 CKB 虚拟机中加载 libc，以及其他 Cell 提供的辅助库，如密码学相关函数等。

首先假设这里使用了一个外部 Cell 提供的 hashmap 数据结构来存储投票信息：

```c
typedef void* hashmap_t;
hashmap_t *hashmap_open(char* buf);
hashmap_t *hashmap_insert(hashmap_t *h, char* key, int value);
int hashmap_get(const hashmap_t *h, char* key);
char* hashmap_dump(const hashmap_t *h);
```

input script 如下：

```c
// Should be loaded from provided function
extern int ckb_check_signature(const char *sig);
extern void* ckb_dlopen(int cell_id);
extern void* ckb_dlsym(void* handle, const char *name);

typedef void* (*OpenFunction)(char*);
typedef void* (*InsertFunction)(void*, char*, int);
typedef char* (*DumpFunction)(const void*);

int main(int argc, char* argv[]) {
  if (argc != 6) {
    return -1;
  }

  if (ckb_check_signature(argv[0] != 0)) {
    return -2;
  }

  void* hash_library_handle = ckb_dlopen(argv[1]);
  OpenFunction *open = ckb_dlsym(hash_library_handle, "hashmap_open");
  InsertFunction *insert = ckb_dlsym(hash_library_handle, "hashmap_insert");
  DumpFunction *dump = ckb_dlsym(hash_library_handle, "hashmap_dump");

  void* hashmap = open(argv[2]);
  insert(hashmap, argv[3], (int), argv[4]);

  if (memcmp(dump(hashmap), argv[5]) != 0) {
    return -1;
  }

  return 0;
}
```
