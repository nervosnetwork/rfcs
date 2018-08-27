# Contract

```
Author: Xuejie Xiao <x@nervos.org>
Category: CKB
Start Date: 2018-08-27
```

## Overview

该 RFC 对现在的合约运行模型作出一些修改，以达到如下目的：

* 定义 Cell 类型的 schema 以及 validator 执行逻辑
* 定义交易内部的不同合约之间的交互方法

考虑到如下原因，注意本 RFC 中的所有实例代码在未经说明的情况下，均以 Ruby 来编写：

* 已经证明通过直接运行 Ruby 虚拟机的方式，CKB 虚拟机可以运行 Ruby 代码
* 这里主要的目的是说明合约如何运行，而不是达到最小的资源消耗
* 目前绝大部分的团队成员已经会 Ruby，同时对于不懂 Ruby 的人员来说，Ruby 也容易阅读说明问题

## 回顾

目前交易的执行模型如下：

![](assets/current-flow.png "Current Flow")

1. 目前的 UTXO (在 CKB 中也叫做 `Cell`)，包含一个 data 数据字段，以及 data/owner lock。为了减小 UTXO 占用空间，UTXO 中只保存 lock 的哈希值。
2. 交易的每个输入会包含对一个 UTXO 的引用，实际的 unlock 脚本(这里脚本的哈希值应该与 UTXO 中相应 lock 的哈希值相同)，以及 unlock 脚本的输入参数。CKB 通过虚拟机在给定输入参数执行该脚本的时候，脚本应该返回成功的返回值。
3. 交易的每个输出也是一个 UTXO 结构（如果有输出的话），这个 UTXO 结构也包含 data 数据段以及 data/owner lock（仅包含哈希值）。输出的 UTXO 中即可以使用原有输入 UTXO 中的 lock，也可以使用全新的 lock。

## 概念

这里针对现有的合约执行模型添加了几个新概念。

### 组

首先，交易中添加了"组"：每个交易被分为若干个组，每个组中可以有若干个 cell 操作：

* 创建操作：创建一个新的 cell
* 转化操作：现有 cell 转化为新的 cell
* 销毁：销毁现有的 cell，不生成任何的新 cell

一个交易只能全部成功，或者全部失败。只有部分的组成功，而其他的组失败是非法的。后面会介绍组在合约执行模型中的实际用处

![](assets/iogroup.png "IO Group")

除 coinbase 交易外，所有的交易应该满足 output cell 的 capacity 总和不大于 input cell 的 capacity 总和的条件。

### Cell 类型

![](assets/cell.png "Cell")

白皮书中提到了 Cell 的类型系统，类型系统包括了 schema 和 validator 两个部分。但是目前为止，他们的实际结构还没有定义。这里会定义 schema 与 validator 的结构。

#### Schema

Schema 提供了访问制定的 Cell 中的数据的方法。CKB 中，schema 以 CKB 虚拟机可以使用的动态链接库提供。它可以在加载之后为虚拟机提供一系列解析和读取 Cell 中存储内容的工具函数。针对一个包含天气信息的 Oracle Cell，可以提供以下的工具函数读取天气信息：

```c
int temperature(int city_index, int year, int month, int day);
int wind(int city_index, int year, int month, int day);
```

注意这里使用 C 语言来定义函数原型仅仅是一个可能的例子。Schema 仅需要保证是 RISC-V 架构的 ELF 格式动态链接库既可以。实际上完全可以定义一个只能被载入到 CKB 上运行的 mruby 虚拟机上，只能被 Ruby 语言调用的 Schema：

```ruby
module Weather
  def self.temperature(city_index, year, month, day)
    # calling actual library
  end

  def self.wind(city_index, year, month, day)
    # calling actual library
  end
end
```

在这里例子中，动态链接库还需要制定一个初始化函数用于把相应的 Ruby 模块载入 mruby 虚拟机中，但是这里想指出的点是是否提供 C 语言的 API 完全取决于 Cell 的维护者。

同时 Schema 也是可选的：简单的 Cell 完全可以直接读取 Cell 的部分数据来获取需要的信息，无需载入一个完整的动态链接库。但是对于复杂的 Cell，schema 可能会更加有用。

Schema 同时也是非常灵活的：CKB 本身并不制定构成 Cell 数据的基本结构（比如整型或是字符串）。与此相反，CKB 完全依赖于 Cell 的维护者来选择合适的数据结构来表示数据，他/她们可以按照需要提供任何函数来操作数据。

#### Validator

Schema 提供了便捷的访问已有 Cell 的格式化数据的方式，validator 则提供了确保新生成的 Cell 满足预先定义好的数据格式。与 unlock 脚本类似，Validator 实际上就是一个 RISC-V 架构下的可以执行合约。CKB 会在 Validator 自己的虚拟机中，通过如下输入参数执行合约：

```bash
$ ./validator <number of deps> <dep 1 cell ID> <dep 2 cell ID> ... \
    <number of inputs> <input 1 cell ID> <input 2 cell ID> ... \
    <number of outputs> <output 1 cell ID> <output 2 cell ID> ... \
    <current output cell ID>
```

在运行期，合约可以调用 CKB 提供的 API，或是相应的系统调用来载入 Cell 的 Schema 操作库，或是直接读取 Cell 内容，或是与其他合约交互（后面会介绍交互方式）。合约执行完毕时，通过返回值来表明 validator 执行是否成功。

#### Cell 类型的属性

Cell 的类型部分（包含 schema 和 validator）既可以直接包含在当前 Cell 内，也可以指向外部的 Cell。换句话说，可以设计一个只包含 Cell 类型数据（schema 以及 validator）的 Cell，同时以该 Cell 为类型创建很多同样类型的 Cell。

Cell 的类型也是不可以修改的：当一个 Cell 制定了类型之后，便不能通过转化操作修改当前 Cell 的类型。唯一的方式就是使用一个销毁操作销毁当前 Cell，再通过创建操作创建一个全新的 Cell，并制定新 Cell 的类型。

## 修正后的合约执行模型

有了这些新加入的概念之后，现在的合约执行模型如下：

![](assets/new-flow.png "New Flow")

1. 针对当前合约内的每一个组中的每一个输入，CKB 会查找到输入对应的 UTXO。针对输入所处的操作不同，不同的 lock 脚本哈希值会被使用：
   - 输入是转化操作时，使用 data lock 的哈希值
   - 输入是销毁操作时，使用 owner lock 的哈希值
2. 针对每一个输入 unlock 脚本，CKB 会创建一个独立的虚拟机来执行。如果任何一个虚拟机中的脚本执行失败，当前合约既可以认为是失败的。注意这里所有的合约没有依赖关系，可以假定全部并行执行。
3. 所有的输入全部验证过之后，CKB 会继续检查 Cell 类型的 validator：针对每一个输出 cell 中的每一个 validator（如果存在的话），CKB 会单独启动一个不同的虚拟机来运行 validator 脚本。脚本运行时会有如下的参数：
   - 合约中所有的 deps Cell 作为 deps 部分提供
   - 当前组中的所有输入 Cell 作为 inputs 部分提供
   - 当前组中的所有输出 Cell 作为 outputs 部分提供
   - 为方便计算，当前输出 cell 的 ID 也会被提供
4. 每一个组中的所有合约可以认为是并行执行，同时每一个组中的合约在运行时也可以以如下的方式进行交互：
   - 他们可以通过直接读取对方的 Cell 中的内容来交互；
   - CKB 也会提供一个特殊的系统调用，该系统调用可以用来在同一个组的不同 VM 之间创建 channel，2 个同一个组中的不同的虚拟机也可以通过这个 channel 来收发数据进行交互
5. 当所有的虚拟机均返回成功的结果是，可以认为当前的交易执行成功

这里要指出的是，与交易用来提供原子性不同，组的作用是隔离开不相关的 cell：可以认为在同一个组中，不同的 cell 是有相顾依赖关系，需要一起来进行处理的。

注意这里只包含合约在虚拟机上执行部分的逻辑。除此之外，CKB 还可能会在交易执行的前后做其他的检查，比如 capacity 检查等。

## 例子

这里会提供相关的例子来展示如何利用添加的功能更加便利的实现某些需求。

### 货币兑换

### Plasma
