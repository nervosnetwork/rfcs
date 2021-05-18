---
Number: "0000"
Category: Network Protocol (Soft Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-04-25
---

# Allow Syscall `load_cell_data_hash` on cell in the tx pool

## Abstract

When the syscalls `load_cell_data` and `load_cell_data_hash` load cell from a transaction still in the pool, they should load correct data and hash as the transaction is already in the chain.

## Motivation

It's common to send chained transactions to the CKB node that some transactions consume the output cells of other transactions not in the chain yet. A bug makes it impossible if the transaction reference another transaction output cells via `load_cell_data` or `load_cell_data_hash`. 

Because of a bug, the syscalls `load_cell_data` and `load_cell_data_hash` have wrong behaviors when the referenced cell is from a transaction still in the transaction pool.

The syscall `load_cell_data` has bee fixed in [this security advisory](https://github.com/nervosnetwork/ckb/security/advisories/GHSA-29c2-65rj-h343). It now can load data of the cell that is in the pool.

But the syscall `load_cell_data_hash` will fail if it tries to load the hash of a cell not in the chain. The fixing is easy but it will lead to nodes running new version blocked by nodes running the old version.

## Specification

The syscall `load_cell_data_hash` must succeed to load the cell data hash when the cell is alive in the chain or in the transaction memory pool.

This is a transaction relay verification rule, it does not affect the consensus rules. However it must be activated after the fork to avoid network partition.

## Security
## Test Vectors
## Rationale
## Deployment
## Backward compatibility
## Acknowledgments
