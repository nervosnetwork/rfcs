---
Number: "0006"
Category: Standards Track
Status: Proposal
Author: Ke Wang
Organization: Nervos Foundation
Created: 2018-12-01
---

# 静态 Merkle Tree

## Complete Binary Merkle Tree

CKB 使用 ***Complete Binary Merkle Tree(CBMT)*** 来为静态数据生成 *Merkle Root* 及 *Merkle Proof*，目前 CBMT 被用于 *Transactions Root* 的计算中。它是一棵完全二叉树，同时也是一棵满二叉树，相比于其它的 Merkle Tree，***Complete Binary Merkle Tree*** 具有最少的 Hash 计算量及最小的 proof size。

## 节点组织形式

规定 CBMT 中节点的排列顺序为从上到下、从左到右（从零开始标号），在一棵由 *n* 个 item 生成的 CBMT 中，下标为 *0* 的节点为 *Merkle Root*，下标为 *n* 的节点为第 *1* 个 item 的 hash，下标 *n+1* 的节点为第 2 个 item 的 hash，以此类推。之所以采用这种排列方式，是因为从 item 的位置很容易计算出其在 CBMT 中节点对应的位置。

举例来说，6 个 item (假设 item 的 Hash 为 `[T0, T1, T2, T3, T4, T5]`)与 7 个 item (假设 item 的 hash 为 `[T0, T1, T2, T3, T4, T5, T6]`)生成的 Tree 的结构如下所示：

```
        with 6 items                       with 7 items

              B0 -- node 0                       B0 -- node 0
             /  \                               /  \
           /      \                           /      \
         /          \                       /          \
       /              \                   /              \
      B1 -- node 1    B2 -- node 2       B1 -- node 1    B2 -- node 2
     /  \            /  \               /  \            /  \
    /    \          /    \             /    \          /    \
   /      \        /      \           /      \        /      \
  B3(3)   B4(4)  TO(5)    T1(6)      B3(3)   B4(4)   B5(5)   T0(6)
 /  \    /  \                       /  \    /  \    /  \
T2  T3  T4  T5                     T1  T2  T3  T4  T5  T6
(7) (8) (9) (10)                   (7) (8) (9)(10)(11) (12)
```

此外，我们规定对于只有 0 个 item 的情况，生成的 tree 只有 0 个 node，其 root 为 `H256::zero`。

## 数据结构

CBMT 可以用一个数组来表示，节点按照升序存放在数组中，上面的两棵 tree 用数组表示分别为：

```
// 11 个元素的数组，数组第一个位置放 node0, 第二个位置放 node1，以此类推。
[B0, B1, B2, B3, B4, T0, T1, T2, T3, T4, T5]
// 13 个元素的数组，数组第一个位置放 node0, 第二个位置放 node1，以此类推。
[B0, B1, B2, B3, B4, B5, T0, T1, T2, T3, T4, T5, T6]
```

在一个由 n 个 item 生成的 CBMT 中，其数组的大小为 *2n-1*，*item i* 在数组中的下标为（下标从 0 开始）*i+n-1*。对于下标为 *i* 的节点，其父节点下标为 *(i-1)/2*，兄弟节点下标为 *(i+1)^1-1*（^为异或），子节点的下标为 *2i+1*、*2i+2*。

## Merkle Proof

Merkle Proof 能为一个或多个 item 提供存在性证明，Proof 中应只包含从叶子节点到根节点路径中无法直接计算出的节点，并且我们规定这些节点按照降序排列，采用降序排列的原因是这与节点的生成顺序相符且 *proof* 的生成及校验算法也会变得非常简单。此外，计算 root 时还需要知道要证明的 item 的 index，因此这些 index 也应包含在 Proof 中，且为了能够使这些 index 能够正确的对应到 item，因此规定这些 index 按对应的 item 的 hash 升序排列，如在 6 个 item 的 Merkle Tree 中为 `[T1, T4]` 生成的 Proof 中应只包含 `[T5, T0, B3]` 和 `[9,6]`。

### Proof 结构

Proof 结构体的 schema 形式为：

```
table Proof {
  // indexes of items
  indexes: [uint32];
  // nodes on the path which can not be calculated, in descending order by index
  nodes: [H256];
}
```

### Proof 生成算法

```c++
Proof gen_proof(Hash tree[], U32 indexes[]) {
  Hash nodes[];
  U32 tree_indexes[];
  Queue queue;

  int size = len(tree) >> 1 + 1;
  indexes.desending_sort();

  for index in indexes {
    queue.push_back(index + size - 1);
  }

  while(queue is not empty) {
    int index = queue.pop_front();
    int sibling = calculate_sibling(index);

    if(sibling == queue.front()) {
      queue.pop_front();
    } else {
      nodes.push_back(tree[sibling]);
    }

    int parent = calculate_parent(index);
    if(parent != 0) {
      queue.push_back(parent);
    }
  }

  add (size-1) for every index in indexes;
  sort indexes in ascending order by corresponding hash;

  return Proof::new(indexes, nodes);
}
```

### Proof 校验算法

```c++
bool validate_proof(Proof proof, Hash root, Item items[]) {
  Queue queue;
  ascending_sort_by_item_hash(items);

  for (index,item) in (proof.indexes, items) {
    queue.push_back((item.hash(), index));
  }

  descending_sort_by_index(queue);

  int i = 0;
  while(queue is not empty) {
    Hash hash, hash1, hash2;
    int index1, index2;

    (hash1, index1) = queue.pop_front();
    (hash2, index2) = queue.front();
    int sibling = calculate_sibling(index1);

    if(sibling == index2) {
      queue.pop_front();
      hash = merge(hash2, hash1);
    } else {
      hash2 = proof.nodes[i++];

      if(is_left_node(index1)) {
        hash = merge(hash1, hash2);
      } else {
        hash = merge(hash2, hash1);
      }
    }

    int parent = calculate_parent(index);
    if(parent == 0) {
      return root == hash;
    }
    queue.push_back((hash, parent))
  }

  return false;
}
```
