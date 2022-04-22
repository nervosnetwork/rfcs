---
Number: "0036"
Category: Standards Track
Status: Proposal
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-02-07
---

# Remove Header Deps Immature Rule

## Abstract

This document proposes to remove *[Loading Header Immature Rule]*.

[Loading Header Immature Rule]: ../0009-vm-syscalls/0009-vm-syscalls.md#loading-header-immature-error

According to the CKB2019 consensus, a header dep must refer to a block which is four epochs old. After this RFC is activated, transactions can use any existing block in the chain as the header dep.

## Motivation

Header dep is a useful feature for DApp developers because the script can read a block's header in the chain or verify that an input cell or dep cell is in a specific block in the chain.

*Loading Header Immature Rule* requires scripts to reference blocks about 16 hours old, which prevents the use of header deps in many scenarios

The intention of the immature rule is similar to the cellbase immature rule. A transaction and all its descendants may be invalidated after a chain reorganization [^1], because its header deps referred to stale or orphan blocks. Removing the rule lets DApp developers trade-off between responsive header reference and reliable transaction finality.

[^1]: A chain reorganization happens when a node finds a better chain with more accumulated proven work and has to rollback blocks to switch to the new chain.

## Specification

This RFC must be activated via a hard fork. After the activation, the consensus no longer verifies the referenced block in the header deps mined four epochs ago.

Transaction producers can postpone submission of a transaction if its header dep has recently been mined. There is a recommendation to wait at least four epochs. However, an application can decide what works best in its particular situation, such as a timeframe for confirmation of a transaction.
