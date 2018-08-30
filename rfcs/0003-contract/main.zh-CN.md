# Contract

```
Author: Xuejie Xiao <x@nervos.org>
Category: CKB
Start Date: 2018-08-27
```

## Overview

该 RFC 对现在的合约运行模型作出一些修改，以达到如下目的：

* 定义 Cell 的 validator 执行逻辑
* 定义交易内部的不同合约之间的交互方法

考虑到如下原因，注意本 RFC 中的所有实例代码在未经说明的情况下，均以 Ruby 来编写：

* 已经证明通过直接运行 Ruby 虚拟机的方式，CKB 虚拟机可以运行 Ruby 代码
* 这里主要的目的是说明合约如何运行，而不是达到最小的资源消耗
* Ruby 是一种可读性很高的语言，即使对于没有使用过 Ruby 的开发者，Ruby 也很容易理解

## 回顾

目前交易的执行模型如下：

![](assets/current-flow.png "Current Flow")

1. 目前 Cell 包含一个 data 数据字段，以及 data/owner lock。为了减小 Cell 占用空间，Cell 中只保存 lock 的哈希值。
2. 交易的每个输入会包含对一个 Cell 的引用，实际的 unlock witness 数据，包含 unlock 脚本(这里脚本的哈希值应该与 Cell 中相应 lock 的哈希值相同)，以及 unlock 脚本的输入参数。CKB 通过虚拟机在给定输入参数执行该脚本的时候，脚本应该返回成功的返回值。
3. 交易的每个输出也是一个 Cell 结构（如果有输出的话），这个 Cell 结构也包含 data 数据段以及 data/owner lock（仅包含哈希值）。输出的 Cell 中即可以使用原有输入 Cell 中的 lock，也可以使用全新的 lock。

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

### Validator

Cell 中会增加 Validator 部分。与 unlock 脚本类似，Validator 是一个 RISC-V 指令集下的 ELF 可执行程序。在验证交易的过程中，CKB 会在 Validator 自己的虚拟机中，通过如下输入参数执行合约：

```bash
$ ./validator <number of deps> <dep 1 cell ID> <dep 2 cell ID> ... \
    <number of inputs> <input 1 cell ID> <input 2 cell ID> ... \
    <number of outputs> <output 1 cell ID> <output 2 cell ID> ... \
    <current output cell ID>
```

注意虽然 deps 包含整个交易的所有 deps Cell，但是这里的 inputs 与 outputs 部分只包含当前组中的所有输入与输入部分。这样通过组的作用，可以将有交互需要的 Cell 组合在一起；对于不相关的 Cell 操作，组也可以将他们隔离，保证各自的 Validator 不会相互影响。

在运行期，Validator 合约可以调用 CKB 提供的 API，或是相应的系统调用来载入外部 Cell 提供的辅助工具库，或是直接读取 Cell 内容，或是与其他合约交互（后面会介绍交互方式）。合约执行完毕时，通过返回值来表明 validator 执行是否成功。

Validator 是不可修改的：当一个 Cell 指定了 Validator 之后，便不能通过转化操作修改当前 Cell 的 Validator。唯一的方式就是使用一个销毁操作销毁当前 Cell，再通过创建操作创建一个全新的 Cell，并指定新的 Validator。

Validator 是可选的：对于链外计算的 Cell，完全可以忽略 Validator 部分，CKB 会默认认为 Validator 执行成功，减少交易的开销。但是与此同时，这样就失去了链上的共识作用，CKB 将交易开销与共识作用之间的取舍交给 Cell 创建者来决定。

## 修正后的合约执行模型

有了这些新加入的概念之后，现在的合约执行模型如下：

![](assets/new-flow.png "New Flow")

1. 针对当前合约内的每一个组中的每一个输入，CKB 会查找到输入对应的 Cell。针对输入所处的操作不同，不同的 lock 脚本哈希值会被使用：
   - 输入是转化操作时，使用 data lock 的哈希值
   - 输入是销毁操作时，使用 owner lock 的哈希值
2. 针对每一个输入 unlock 脚本，CKB 会创建一个独立的虚拟机来执行。如果任何一个虚拟机中的脚本执行失败，当前合约既可以认为是失败的。注意这里所有的合约没有依赖关系，可以假定全部并行执行。
3. 所有的输入全部验证过之后，CKB 会继续检查 Cell 的 validator：针对每一个输出 cell 中的每一个 validator（如果存在的话），CKB 会单独启动一个不同的虚拟机来运行 validator 脚本。每一个组中的所有合约可以认为是并行执行，脚本运行时会有如下的参数：
   - 合约中所有的 deps Cell 作为 deps 部分提供
   - 当前组中的所有输入 Cell 作为 inputs 部分提供
   - 当前组中的所有输出 Cell 作为 outputs 部分提供
   - 为方便计算，当前输出 cell 的 ID 也会被提供
4. 当所有的虚拟机均返回成功的结果是，可以认为当前的交易执行成功

这里要指出的是，与交易用来提供原子性不同，组的作用是隔离开不相关的 cell：可以认为在同一个组中，不同的 cell 是有相顾依赖关系，需要一起来进行处理的。

注意这里只包含合约在虚拟机上执行部分的逻辑。除此之外，CKB 还可能会在交易执行的前后做其他的检查，比如 capacity 检查等。

### 合约交互

每一个组中的 Validator 合约运行时，可能需要与组内的其他合约进行交互以实现某种需求。这里主要有两种交互方式：

首先，因为每个组内的 Validator 合约在运行时，会收到本组内的所有输入与输入 Cells，所以合约可以通过直接读取其他合约对应的输入输出 Cell 来获取属于其他合约的数据，完成交互。

其次，CKB 会提供单独的 API 用于在同一个组的不同 Validator 合约虚拟机之间创建交互的 channel：

```c
int ckb_create_channel(int cell_id);
```

这里生成的 channel 类似 Linux 中的通道 (pipes)，channel 的两端均可以支持读写操作，channel 内传输的为二进制数据，channel 本身不对传输数据的格式做出限定，而是交由实际的合约来制定格式。

基于上述的 C 语言 API，可以封装在 Ruby 语言中可以使用的 API：

```c
module Channel
  def self.create(cell_id)
    // create a channel
  end

  def send(data)
    // send data through current channel
  end
```

这样组内的合约便可以在需要的情况下完成相互间的通信，实现更多的功能。

## 例子

这里会提供相关的例子来展示如何利用添加的功能更加便利的实现某些需求。处于简洁性的考虑，这里的例子只包含 validator 逻辑。在绝大多数情况下 unlock 脚本可以只包含类似于比特币脚本所做的签名验证逻辑。

### 货币兑换

在第一个例子中，两个 Cell 会保存各自 Cell 所对应货币的余额，这两个 Cell 可以参与货币兑换交易。在交易中，每个 Cell 会各自检查自身的余额，同时与对方交互达成在汇率及交易数额上的一致。显然这两个 Cell 会处于交易的同一个组中。

假设有一个 Oracle 可以提供最新的货币汇率，可以使用 deps Cell 来指向 Oracle：

```ruby
module Currency
  def self.current_rate(type)
    # fetching current currency rate
  end
end
```

注意使用 Oracle Cell 只是提供汇率信息的一种方法，也可以直接将汇率信息包含在 unlock witness 数据中来实现相同目的。

就像上面提到的，Oracle Cell 会在 deps Cell 中提供引用，每一个货币兑换 validator 会通过加载动态链接库的方式载入该 Oracle 的 schema 部分。相应的 Ruby 代码会被加载到 Ruby 虚拟机中。

每一个 Cell 会包含如下格式的 JSON 数据：

```javascript
{
  "amount": 12300,
  "type": "USD"
}
```

`amount` 是一个整型数据，其中 1 代表 1 分，这样我们便可以省去使用浮点数的麻烦。`type` 包含当前 Cell 对应的货币币种。

在交易中，一个组会包含两个有着如下 validator 脚本的转化操作：

```ruby
deps = ARGV.slice(1, ARGV[0].to_i)
input_start = deps.length + 1
inputs = ARGV.slice(input_start + 1, ARGV[input_start].to_i)
output_start = input_start + inputs.length + 1
outputs = ARGV.slice(output_start + 1, ARGV[output_start].to_i)
current_cell_id = ARGV[output_start + outputs.length + 1].to_i

# load deps[0] as a shared library, so we will have Currency module at our finger tips

# calculate current cell index
index = (current_cell_id == outputs[0].id) ? 0 : 1
other_index = index == 0 ? 1 : 0
# Parse input and output data
input_data = JSON.parse(inputs[index].data)
output_data = JSON.parse(outputs[index].data)
exit(false) if input_data["type"] != output_data["type"]
# calculate the amount transferred
amount = output_data["amount"] - input_data["amount"]
type = output_data["type"]

channel = CKB::create_channel(other_index)
channel.send(amount)
channel.send(type)
# fetch the amount from the other end
other_amount = channel.receive
other_type = channel.receive

# amount and other_amount must have different sign since one must be deposit, the other
# must be withdraw
exit(false) if amount * other_amount > 0

actual_rate = amount.abs / other_amount.abs
# Rate is determined by the 2 currency types
current_rate = Currency.current_rate("#{type}/#{other_type}")
exit(actual_rate == current_rate)
```

这个合约可以保证如下的不变量：

* 每个 Cell 在交易前后的货币类型不变
* 每个交易保证使用 Oracle 中提供的最新汇率
* 交易中收入和支出部分的金额相匹配

这样就完成了一个货币交易合约。

### Plasma

接下来会介绍一个简化的 Plasma 实例。由于 CKB 是 layer 1 实现， 它只需要包含 Plasma 实例中在以太坊上部署的智能合约部分，真正的 Plasma 链则可以在 layer 2 上部署。

基本的数据结构如下：

```javascript
{
  "headers": {
    "10032": {
      "blockNumber": "10032",
      // ...
    },
    // ...
  },
  "depositRecords": {
    "bcf84dbc6d40d209afed26ca947bd98c47cf28f73afea6fb7e161ab1ed5dfe56": [
      {
        "blockNumber": "10032",
        "txIndex": "725bee66519a6567fabbb9b15128828af344960aa6a82e27e1fd255f61faee38",
        // ...
      },
      // ...
    ]
  },
  // ...
}
```

这里实际上包含了跟 [这个合约](https://github.com/ethereum-plasma/plasma/blob/8b84007cc0a5a0f0e1439bd2299d381bf7d8ce28/contracts/PlasmaChainManager.sol#L46-L53) 同样的数据，但是以 JSON 格式序列化存储。

与货币交易模型不同，Plasma 合约是可以执行不同的转化操作的，所以除输入输出外，还需要方式来提供输入 Cell 所进行的转化操作。

一种实现方式（当然，这里可能还有其他方式）是在 unlock 脚本的参数中，在所有跟签名相关的参数后面添加一个新的参与，用来保存当前 Plasma 合约进行的转化操作。Unlock 脚本编写时可以完全忽略这些额外的参数：

```ruby
# assuming signature validation requires 3 parameters
exit(false) if ARGV.length < 3

args = ARGV.slice(0, 3)

# validating signature using args
# ...
```

考虑到 validator 函数可以访问输入 Cell，自然也就可以访问这里提供的额外参数：

```ruby
deps = ARGV.slice(1, ARGV[0].to_i)
input_start = deps.length + 1
inputs = ARGV.slice(input_start + 1, ARGV[input_start].to_i)
output_start = input_start + inputs.length + 1
outputs = ARGV.slice(output_start + 1, ARGV[output_start].to_i)
current_cell_id = ARGV[output_start + outputs.length + 1].to_i

command = JSON.parse(inputs[0].arguments.last)
response = case command
when "submitBlockHeader"
  submitBlockHeader(...)
when "deposit"
  deposit(...)
# more actions can be included here
else
  false
end
exit(response)
```

因此，验证逻辑可以转化为针对每一个 Plasma 转化命令的分别验证：

```ruby
def submitBlockHeader(input_data, output_data, block)
  input_data["headers"][block["blockNumber"]] = block
  input_data == output_data
end
```

其他的验证逻辑也可以以同样的方式提供：

1. 首先把输入和输出 Cell 反序列化成输入输出数据
2. 根据不同类型的 Plasma 转化命令，我们针对输入数据做不同的转化操作
3. 然后将转化后的输入数据与输出数据做对比，如果她们相同，即可认为当前组验证成功

注意链上执行多少计算操作完全由执行的程序来决定，这里实际上有一个取舍关系：

* 链上执行更多的计算更能保证 Cell 的数据永远是合法的，并可以被信任的
* 链上执行更少的计算更能节约 Cell 数据转化时所需的开销

在一个极端情况下，validator 可以完全被忽略，这样所有的计算与验证逻辑均外链外执行；另一个极端是链上执行尽可能多的逻辑保证数据是正确的，例如上面提到的 Plasma 实例。
