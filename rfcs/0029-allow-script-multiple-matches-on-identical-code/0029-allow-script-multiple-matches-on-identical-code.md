---
Number: "0029"
Category: Standards Track
Status: Proposal
Author: Ian Yang <@doitian>
Created: 2021-02-03
---

# Allow Multiple Cell Dep Matches When There Is No Ambiguity

## Abstract

This document proposes a consensus change for transaction verification. This change allows multiple cell dep matches on type script hash when all the matches are resolved to the same script code.

## Motivation

By using data hash or type script hash, CKB finds the code for lock and type script to execute.

CKB allows multiple matches on a data hash because it causes no problem. Data hash is the cryptographic hash of referenced code, so multiple matches can only mean they refer to the same code. Type script hash does not conform to this rule. Cells with the same type script hash may have different contents.

Currently, CKB does not allow multiple matches on type script hash. However, in many cases, multiple matches on type script hash do not introduce ambiguity if all the matches have the same data hash as well. In most scenarios, the transaction uses two dep groups that contain duplicate cells, so the multiple matches on type script hash actually point to the same cell.

```
# An example that multiple type script hash matches refer to the same cell.
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

Based on the observation above, this RFC proposes to allow multiple matches on type script hash if they all have the same data.

## Specification

The same as before, multiple matches are allowed when the transaction verifier locates the script code in the dep cell via data hash. 

This RFC introduces the following modification to the case where the verifier locates the code via type hash:

- If all the matched cells have the same data, multiple matches are allowed;

- Otherwise, the transaction is invalid and the verification fails.

## Test Vectors

**Multiple matches of data hash**

This works in both the old rule and the new one.

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

**Multiple matches of type hash that all resolved to the same code**

The transaction is invalid under the old rule, but valid under the new rule.

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

In the first stage, the new consensus rule will be activated from a specific epoch. The mainnet and testnet will use different starting epochs. All the development chains initialized with the default settings will use the new rule from epoch 0.

After the fork is activated, the old rule will be replaced by the new rule starting from the genesis block by new CKB node versions.

## Backward Compatibility

The consensus rule proposed in this document is looser, so it must be activated via a hard fork. The blocks accepted by the new version of clients may be rejected by old versions.
