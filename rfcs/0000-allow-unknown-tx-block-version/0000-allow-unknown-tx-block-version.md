---
Number: "0000"
Category: Consensus (Hard Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-04-26
---

# Allow Unknown Tx and Block Version

## Abstract

Block version and transaction version are fields reserved for future upgrades. But currently, nodes require that they must be 0 so the version field can only be used via a hard fork.

This RPC proposes to allow unknown transaction and block version so the version field can be used in a soft fork.

## Specification

The CKB node allows any block version and transaction version. When the version is larger than the node maximum supported version, it is considered as the same as the largest supported version. For example, when the node supports block version 0 and 1, all the blocks which version is larger than 1 will be verified as the version is 1.

Soft fork can bump the version and ensure that the valid transaction in the new version can also pass the verification in the old clients.

## Security
## Test Vectors
## Rationale
## Deployment
## Backward compatibility
## Acknowledgments
