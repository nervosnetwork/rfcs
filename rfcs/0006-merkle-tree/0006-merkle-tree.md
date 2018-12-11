---
Number: 0006
Category: Standards Track
Status: Proposal
Author: Ke Wang
Organization: Nervos Foundation
Created: 2018-12-01
---

# Merkle Tree for Static Data

## Complete Binary Merkle Tree

CKB uses Complete Binary Merkle Tree(CBMT) to generate `Merkle Root` and `Merkle Proof` for a static list of items. Currently, CBMT is used to calculate `Transactions Root`. Basically, CBMT is a ***complete binary tree***, in which every level, except possibly the last, is completely filled, and all nodes are as far left as possible. And it is also a ***full binary tree***, in which every node other than the leaves has two children. Compare with other Merkle trees, the hash computation of CBMT is minimal, as well as the proof size.

## Node Orginazation

For the sake of illustration, we order the tree nodes from ***top to bottom*** and ***left to right*** starting at zero. In CBMT with `n` items, root is the `first` node, and the first item's hash is `node 0`, second is `node n+1`, etc. We choose this nodes orginazation because it is easy to caculate the node order for an item.

For example, CBMT with 6 items(suppose the hashes are `[T0, T1, T2, T3, T4, T5]`) and CBMT with 7 items(suppose the hashes are `[T0, T1, T2, T3, T4, T5, T6]`) is shown below:

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

Specially, the tree with 0 item is empty(0 node) and its root is `H256::zero`.

## Tree Struct

CBMT can be represented in a very space-efficient way, using an array alone. Nodes in the array are presented in ascending order.

For example, the two trees above can be represented as:

```
// an array with 11 elements, the first element is `node 0`(`BO`), second is `node 1`, etc.
[B0, B1, B2, B3, B4, T0, T1, T2, T3, T4, T5]

// an array with 13 elements, the first element is `node 0`(`BO`), second is `node 1`, etc.
[B0, B1, B2, B3, B4, B5, T0, T1, T2, T3, T4, T5, T6]
```

Suppose a CBMT with `n` items, the size of the array would be `2n-1`, the index of item i(start at 0) is `i+n-1`. For node at `i`, the index of its parent is `(i-1)/2`, the index of its sibling is `(i+1)^1-1`(`^` is xor) and the indexes of its children are `[2i+1, 2i+2]`.

## Merkle Proof

Merkle Proof can provide a proof for existence of one or more items. Only sibling of the nodes along the path that form leaves to root, excluding the nodes already in the path, should be included in the proof. We also specify that ***the nodes in the proof is presented in descending order***(with this, algorithms of proof's generation and verification could be much simple). For example, if we want to show that `[T1, T4]` is in the list of 6 items above, only nodes `[T5, T0, B3]` should be included in the proof.

### Proof Sturct

The schema of proof struct is:

```
table Proof {
  // size of items in the tree
  size: uint32;
  // nodes on the path which can not be calculated, in descending order by index
  nodes: [H256];
}
```

### Algorithm of proof generation

```c++
Proof gen_proof(Hash tree[], int indexes[]) {
  Hash nodes[];
  Queue queue;
  
  int size = len(tree) >> 1 + 1;
  desending_sort(indexes);

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

  return Proof::new(size, nodes);
}
```

### Algorithm of validation

```c++
bool validate_proof(Proof proof, Hash root, Item items[]) {
  if(proof.size = 0) {
    return root == H256::zero;
  }
  
  Queue queue;
  desending_sort_by_item_index(items);
  
  for item in items {
    queue.push_back((item.hash(), item.index() + Proof.size - 1));
  }
  
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
