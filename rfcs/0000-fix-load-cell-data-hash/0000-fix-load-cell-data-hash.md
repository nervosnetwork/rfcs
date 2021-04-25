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

When the syscalls `load_cell_data` and `load_cell_data_hash` load cell from a transaction still in the pool, they should load correct data and hash as the transaction is already in the pool.

## Motivation

It's common to send chained transactions to the CKB node that some transactions consume the output cells of other transactions not in the chain yet. A bug makes it impossible if the transaction reference another transaction output cells via `load_cell_data` or `load_cell_data_hash`. 

Because of a bug, the syscalls `load_cell_data` and `load_cell_data_hash` have wrong behaviors when the referenced cell is from a transaction still in the transaction pool.

The syscall `load_cell_data` has bee fixed in [this security advisory](https://github.com/nervosnetwork/ckb/security/advisories/GHSA-29c2-65rj-h343). 

## Specification
## Security
## Test Vectors
## Rationale
## Deployment
## Backward compatibility
## Acknowledgments
