---
Number: "0029"
Category: Consensus (Hard Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-02-03
---

# Allow Multiple Cell Dep Matches When There Is No Ambiguity

## Abstract

This document proposes a transaction verification consensus change to allow multiple cell dep matches on type script hash when all the matches are resolved to the same script code.

## Motivation

Currently, CKB does not allow multiple matches when resolving the script by type script hash in dep cells.

However, in many cases, multiple matches do not introduce ambiguity.

There are two different ways to reference the script, via data hash or type hash.

* When the script is referenced by data hash, all the matches are resolved to the identical code.
* When the script is referenced by type hash, it is possible that the matches can be resolved to different code binaries. The consensus rule can only reject the transaction when this happens.

## Specification

When the transaction verifier resolves script code in dep cell via data hash, multiple matches are allowed. This is the same as before.

When the verifier resolves code via type hash, multiple matches are allowed if all the matched cells have the same data, otherwise, the transaction is invalid and the verification fails. This is the modification introduced by this RFC.

## Test Vectors

Examples that fail using the old rule but pass using the new rule.

Multiple matches of data hash.

```
#  hash(Cell B.data) equals to hash(Cell A.data)
cell_deps:
  - out_point: ...
    # Expands to
    # - out_point: Cell A
    dep_group: DepGroup

  - out_point: ...
    # Expands to
    # - out_point: Cell B
    dep_group: DepGroup

inputs:
  - out_point: ...
    lock:
      code_hash: hash(Cell A.data)
      hash_type: Data
```

Multiple matches of type hash which all resolve to the same code.

```
#  hash(Cell B.data) equals to hash(Cell A.data)
# and hash(Cell B.type) equals to hash(Cell A.type)
cell_deps:
  - out_point: ...
    # Expands to
    # - out_point: Cell A
    dep_group: DepGroup

  - out_point: ...
    # Expands to
    # - out_point: Cell B
    dep_group: DepGroup

inputs:
  - out_point: ...
    lock: ...
    type:
      code_hash: hash(Cell A.type)
      hash_type: Type
```

## Deployment

The deployment can be performed in two stages.

The first stage will activate the new consensus rule starting from a specific epoch. The mainnet and testnet will use different starting epochs and all other chains will use the new rule from epoch 0.

After the fork is activated, the old rule will be replaced by the new rule starting from the genesis block in all chains.

## Backward compatibility

The consensus rule proposed in this document is looser, so it must be activated via a hard fork. The blocks accepted by new version clients may be rejected by the old versions.
