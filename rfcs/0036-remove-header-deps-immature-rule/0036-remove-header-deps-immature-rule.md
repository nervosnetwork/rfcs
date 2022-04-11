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

This document proposes removing the *[Loading Header Immature Rule]*.

[Loading Header Immature Rule]: ../0009-vm-syscalls/0009-vm-syscalls.md#loading-header-immature-error

In the consensus ckb2019, the header dep must reference the block which is 4 epochs ago. After this RFC is activated, the transaction can use any existing blocks in the chain as the header dep.

## Motivation

Header dep is a useful feature for dApps developers because the script can read the block's header in the chain or verify that an input cell or dep cell is in a specific block in the chain.

The *Loading Header Immature Rule* prevents the usage of header deps in many scenarios because the script must reference the block about 16 hours ago.

The intention of the immature rule is like the cellbase immature rule. A transaction and all its descendants may be invalidated after a chain reorganization [^1], because its header deps referred to stale or orphan blocks. Removing the rule lets dApps developers trade-off between responsive header reference and reliable transaction finality.

[^1]: Chain reorganization happens when the node found a better chain with more accumulated proved work and it has to rollback blocks to switch to the new chain.

## Specification

This RFC must be activated via a hard fork. After activation, the consensus no longer verifies that the referenced block in the header deps is mined 4 epochs ago.

The transaction producers can choose to postpone the transaction submission when it has a header dep that has been mined recently. It suggests waiting for at least 4 epochs, but the app can choose the best value in its scenario, like the transaction confirmation period.
