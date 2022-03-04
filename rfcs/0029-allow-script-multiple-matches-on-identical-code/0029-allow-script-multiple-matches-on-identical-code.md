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

CKB locates the code for lock and type script to execute via data hash or type script hash.

CKB allows multiple matches on data hash because it is safe. Data hash is the hash on the code, thus multiple matches must have the same code. This does not hold for type hash. Two cells with the same type script hash may have different contents.

Currently, CKB does not allow multiple matches on type script hash. But in many cases, multiple matches on type script hash do not introduce ambiguity if all the matches have the same data hash as well. Because in the most scenarios, the cause is that the transaction uses two dep groups which contain duplicated cells, the multiple matches on type script hash really point to the same cell.

```
# An example that multiple matches on the type script hash really are the same cell.
cell_deps:
  - out_point: ...
    # Expands to
    # - out_point: Cell A
    dep_group: DepGroup

  - out_point: ...
    # Expands to
    # - out_point: Cell A
    dep_group: DepGroup

inputs:
  - out_point: ...
    lock: ...
    type:
      code_hash: hash(Cell A.type)
      hash_type: Type
```

Based on the observation above, this RFC proposes to allow the multiple matches on the type script hash if they all have the same data.

## Specification

When the transaction verifier locates script code in dep cell via data hash, multiple matches are allowed. This is the same as before.

When the verifier locates code via type hash, multiple matches are allowed if all the matched cells have the same data, otherwise, the transaction is invalid and the verification fails. This is the modification introduced by this RFC.

## Test Vectors

Multiple matches of data hash. This works in both the old rule and the new one.

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

Multiple matches of type hash which all resolve to the same code. This transaction is invalid using the old rule but valid using the new rule.

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

The first stage will activate the new consensus rule starting from a specific epoch. The mainnet and testnet will use different starting epochs and all the development chains initialized via the default settings in this stage will use the new rule from epoch 0.

After the fork is activated, the old rule will be replaced by the new rule starting from the genesis block by new CKB node versions.

## Backward compatibility

The consensus rule proposed in this document is looser, so it must be activated via a hard fork. The blocks accepted by new version clients may be rejected by the old versions.
