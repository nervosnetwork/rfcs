---
Number: "0036"
Category: Consensus (Hard Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-02-07
---

# Remove Header Deps Immature Rule

## Abstract

This document proposes removing the loading header immature rule.

In the consensus ckb2019, the header dep must reference the block which is 4 epochs ago. After this RFC is activated, the transaction can use any existing blocks in the chain as the header dep.

## Motivation

Header dep is a useful feature for dApps developers because script can use it to read the header of a block in the chain, or verify that an input cell or dep cell is in a specific block in the chain.

The immature rule prevents the usage of header deps in many scenarios because the script must reference the block about 16 hours ago.

The intention of the immature rule is like the cellbase immature rule, a transaction with header deps and all its descendants can be invalidated after a chain reorganization [^1], because the referenced block may be rollbacked.

[^1]: Chain reorganization happens when the node found a better chain with more accumulated proved work and it has to rollback blocks to switch to the new chain.

## Specification

This RFC must be activated via a hard fork. After activation, the consensus no longer verifies that the referenced block in the header deps has been mined 4 epochs ago.

The transaction producers can choose to postpone the transaction submission when it has a header dep which has been mined recently. It's recommended to wait at least 4 epochs but the app can choose the best value in its scenario, like the transaction confirmation period.
