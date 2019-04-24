---
Number: "0010"
Category: Standards Track
Status: Proposal
Author: YaNing Zhang
Organization: Nervos Foundation
Created: 2018-12-20
---

# Cellbase maturity period

There are two kinds of transaction in CKB, "normal" one and cellbase one.

For "normal" transactions, the inputs refer to previous transactions. If a fork were to occur, the blocks become orphaned, their transactions are still valid and able to be confirmed in other blocks. Some blocks confirmations is decent number of confirmations to deter attacks without 51% of the hashrate.

For cellbase transactions, there aren't any inputs there. If the block somehow gets orphaned, all subsequent transactions refer to that cellbase transaction would immediately be invalid as well. This could affect many transactions, as long as they are linked to that cellbase transaction. The more confirmations there are, the harder it is to happen.

## Consensus rule

For each input, if the referenced output transaction is a cellbase transaction, it must have at least CELLBASE_MATURITY confirmations, otherwise the transaction will be rejected.
