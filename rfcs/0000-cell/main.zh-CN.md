# Cell

```
Author: ian <ian@nervos.org>
Category: CKB
Start Date: 2018-02-26
```

## Cell 基础属性

| 属性        | 类型            | 说明                  |
| --------- | ------------- | ------------------- |
| module    | u32           | Cell 所属模块           |
| capacity  | u32           | 存储空间上限              |
| data      | binary        | 存储数据                |
| lock      | binary        | 验证 Cell 所有者的密码学挑战   |
| recipient | (u32, binary) | 接收者模块 + 验证接收者的密码学挑战 |

#### Module

相同 Module 中的 Cell 可以自由通信，跨 Module 必须通过 `recipient` 指定接收者模块。Module 使用 32 位无符号整数作为标识符。

#### Capacity

Capacity 需要保证不小于整个 Cell 的存储占用空间，包含所有基础属性，以及之后可能添加的扩展属性。

#### Data

Cell 存储的数据，通过 Module 定义的 Schema 可以解释数据的含义。

#### Lock

验证 Cell 所有者的密码学挑战。绝大部分 Cell 的操作都需要提供相应证明是 Cell 所有者授权的。

#### Recipient

Recipient 是复合类型，由 `recipient_module` 和 `recipient_lock` 两部分组成。Recipient 用于跨模块通信，详见[交易规则][1]中相关说明和[模块相关 RFC][2] 的说明。

## Cell 链

Cell 创建之后是不可变的，但是可以转换成新的 Cell，直到最终被销毁。通过创建 (create)，转换 (transform)，销毁 (destroy) 可以组成一个 Cell 链。每个 Cell 都唯一属于一个 Cell 链。

![][image-1]

Cell 被创建时，其所在的 Cell 链也被同时创建，并把新创建的 Cell 作为链头 (Chain Head)。

Cell 转换时，新的 Cell 被添加到 Cell 链中并作为新的链头。

Cell 被销毁，其所在的 Cell 链也被销毁。

在某个时间点，所有未销毁 Cell 链的链头称为 Head Cell。所有 Head Cell 集合就是该时间点的 CKB 快照。

![][image-2]

上图中，t0, t1, t2, t3 为 4 个时间点，相邻时间点之间会发生 Create, Transform 和 Destroy 操作，从上到下依次是 A, B, C, D 四个 Cell 链。

- 在 t1 时刻，有 3 个新创建的 Cells，该时刻的 Head Cells 有 A1, B1, C1
- 在 t2 时刻，A1 被销毁，B1 不变，C1 转换成 C2，同时新创建了 D2，所以此时 Head Cells 有 B1, C2, D2
- 在 t3 时刻，B1 转化成 B3, C2 不变，D2 转换成 D3，所以 Head Cells 有 B3, C2, D3

如果把 ti 时间点时的 Head Cells 集合计为 `H[i]`。在 ti 到 tj 时间点所有发生的 Transform 操作的输入 Cell 集合计为 `I[i, j]`，输出计为 `O[i, j]`，所有 Destroy 操作的输入 Cell 集合计为 `D[i, j]`，所有 Create 操作的输出 Cell 集合计为 `C[i, j]`，容易得到:

```
H[j] = H[i] + O[i, j] + C[i, j] - I[i, j] - D[i, j]
```

其中，`+` 表示集合并，`-` 表示集合减。

## 交易结构

一个交易包含多个组，每个组可以包含多个操作。操作可以时创建 (create), 转换 (transform) 或者销毁 (destroy)。交易保证原子性，交易中的所有操作要么都被接受，要么都被拒绝。

![][image-3]

多个交易组成一个 Block。所以 Block 包含的是两个时间点间所有发生的 Cell 操作的集合。划分为交易是保证原子性，划分为组是方便以 Module 为单位进行交易验证。

把 Block 结合到 Head Cell 图中可以得到

![][image-4]

## 交易规则 {#tx-rules}

## TODO
- Cell Capacity 不增发
- Cell Module 不可变性
- 操作 Group 的单一 Module 限制
- Module Checker

[1]:	#tx-rules
[2]:	TODO

[image-1]:	rfc-cell-assets/cell-chain.jpg "Cell Chain"
[image-2]:	rfc-cell-assets/head-cell.jpg "Head Cell"
[image-3]:	rfc-cell-assets/tx-struct.jpg "Transaction Struct"
[image-4]:	rfc-cell-assets/blockchain.jpg "Blockchain"
