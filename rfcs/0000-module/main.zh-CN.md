# Module

```
Author: ian <ian@nervos.org>
Category: CKB
Start Date: 2018-03-07
```

## 简介

在 RFC Cell 中每个 Cell 都属于一个模块，而在交易中操作被分成组，每个组也唯一属于某个模块，并且由模块的 Checker 函数来检查操作组是否是被允许的。

模块本身的创建，修改都是在 Module 这个系统模块中进行的，也就是说模块自己也是一个模块。Module 模块是在创世块中初始化创建的。

本 RFC 定义了如何通过 Cell 注册模块，定义和修改 Checker，以及一种 Checker 的实现方案。

## Checker

Checker 是一个函数，接收 Cell 操作列表，如果这个操作列表构成的组是允许的就返回 true，否则返回 false。

在生成 Block 时，所有交易中的所有组都必须通过 Checker 的验证。

Checker 函数本身也是存放在某个 Cell 的 data 中的，为了能正确允许，节点必须对 Checker 的 data 格式有共识。

未来 Cell 的 data 如何解释需要有一套 data schema 系统，本 RFC 先制定一些简单的 data schema 用于 PoC 版本的 CKB。

## Module 模块

本章会定义 Module 模块中会有什么样的 Cell，如何通过 Module 模块查询模块 Checker 函数，以及如何执行 Checker 函数。

Module 模块分配的模块 ID 为 0。

### Module 模块类型

Module 模块会有几种不同类型的 Cell 参与，类型系统会作为 data schema 的一部分在未来进行完善，这里提出一种简单的类型编码方式来定义 Module 模块。

Module 模块 Cell 的 data 的第一个字节会作为类型 tag。之后字节作为该类型数据的 payload，是按照类型连续排放的类型属性二进制编码。

![][image-1]

因为类型不多，所以会挑选 ASCII 字母来作为 tag，下表是使用到类型和对应的 tag。每种类型的用途以及 data 编码方式会依次说明。

| 类型        | Tag |
| --------- | --- |
| Root      | R   |
| Allocator | A   |
| Module    | M   |
| Token | T |
| Checker   | C   |

#### R = Root

Root 的作用是通过其 lock 来授权创建和修改系统预留模块。

![][image-2]

- `next_id`  大端序编码的 32 位无符号整数，表示下一个可用的系统模块 ID。 

#### A = Allocator

Allocator 用于 Module 32位无符号整数的分配。

![][image-3]

- `next_id`  大端序编码的 32 位无符号整数，表示下一个可用的非系统模块 ID。

#### M= Module

每个模块都有对应的一个 Module 类型的 Cell。Module Cell 的主要作用是通过创建 Token 影响到模块内的操作，比如行使管理员的职责。

![][image-4]

#### T = Token

Token 类型是 Volatile Cell，一般由 Module Cell 授权创建，通过 Consume 操作参与到模块的操作组中。

![][image-5]

- `payload` Token 的 payload 可以是任意长度的二进制数据。

#### C = Checker

Checker Cell 存储模块的 Checker 函数。

![][image-6]

- `module_id` Checker 函数所属的模块 ID
- `code` 任意二进制

### Module Checker

Module 模块的 Checker 以白名单的方式允许下列的操作组，拒绝所有不在白名单中的操作组。

#### 系统模块注册

系统模块是 ID 0 \~ 127 （暂定）的模块。通过 Root Cell 获得下一个可用模块 ID，更新 Root Cell 并创建 Module Cell 和 Checker Cell。

![][image-7]

额外条件：

- n \< 127

Root Cell 单例在创世块中创建，初始 `next_id` 根据创世块中已经创建的系统模块数量确定。

#### 非系统模块注册

和系统模块一致，只是用 Allocator Cell 替代。

![][image-8]

额外条件：

- n != 2^32

Allocator 同样在创世块中创建，初始 `next_id` 等于 128

#### Checker 更新

Checker 更新只允许更新 code 部分。

![][image-9]

#### 创建 Token

Token 的创建需要 Module Cell 授权

![][image-10]

额外条件：

- 创建的 Token Cell 的 receipt type 必须等于 Module Cell 中的模块 ID

#### 销毁

Token 可以被销毁

![][image-11]

### Lua Checker Code

Checker 是函数，节点需要运行需要将数据解释成指令然后在允许。在本 RFC 中，使用 Lua VM 来执行函数，Checker Cell 中 code 存储的 UTF-8 编码的 Lua 代码。

Code 存储的 Lua 代码需要返回一个 Lua 函数，该函数接受操作列表，并返回布尔值。比如下面的代码是允许任何操作组的 Checker code

``` lua
return function()
  return true
end
```

#### 操作列表 Lua 表示

操作列表在 Lua 中表示为一个 list，每个成员包含两个属性

- `input` Input Cell，对于 Create 操作是 `nil`
- `output` Output Cell，对于 Destroy 操作是 `nil`

比如:

```
{ { input = i1 }, { output = o2 }, { input = i3, output = o3 } }
```

是一个包含三个操作的组，依次是输入为 i1 的 Destroy，输出为 o2 的 Create，和 i3 到 o3 的 Transform。

Input Cell 是 table 或者 `nil`，当为 table 时包含属性：

- `cell` Lua table, Cell 结构体
- `unlock` Lua string, Unlock 证明的二进制，类型是 Lua string
- `height` Lua number, Input Cell 作为输出的 Create/Transform 操作所在区块的高度

Output Cell 同样是 table 或者 `nil`，当为 table 时包含属性：

- `cell` Cell 结构体

Cell 结构体的属性如下：

- `module_id` Lua number, 模块 ID
- `capacity` Lua number, Cell 空间上限
- `data` Lua string, Cell 存储的二进制数据
- `lock` Lua string, 二进制编码的 lock public key hash，可能为 `nil`
- `recipient` Lua table，可能为 `nil`

Recipient 结构体的属性如下：

- `module_id` Recipient 模块 ID
- `lock` Recipient lock，可能为 `nil`

### 系统模块初始化

最基础的系统模块在创世块中创建，除了 0 Module 模块，还有 1 Space 模块。

Space 模块的 Checker 允许任何的操作组，可以用在扩容交易 (Enlarge Transaction) 中。

[image-1]:	rfc-module-assets/type.jpg "Type"
[image-2]:	rfc-module-assets/root-cell.jpg "Root Cell"
[image-3]:	rfc-module-assets/allocator-cell.jpg "Allocator Cell"
[image-4]:	rfc-module-assets/module-cell.jpg "Module Cell"
[image-5]:	rfc-module-assets/token-cell.jpg "Token Cell"
[image-6]:	rfc-module-assets/checker-cell.jpg "Checker Cell"
[image-7]:	rfc-module-assets/register-system-module.jpg "Register System Module"
[image-8]:	rfc-module-assets/register-normal-module.jpg "Register Normal Module"
[image-9]:	rfc-module-assets/update-checker.jpg "Update Checker"
[image-10]:	rfc-module-assets/emit-token.jpg "Emit Token"
[image-11]:	rfc-module-assets/destroy-token.jpg "Destroy Token"