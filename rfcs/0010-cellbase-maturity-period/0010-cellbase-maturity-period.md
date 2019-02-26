---
Number: "0010"
Category: Standards Track
Status: Proposal
Author: YaNing Zhang
Organization: Nervos Foundation
Created: 2018-12-20
---

# Cellbase maturity period

There are two kinds of transactions in CKB, "normal" transactions and cellbase transactions.

For "normal" transactions, the inputs are referenced from another transaction. If a fork were to accur, the blocks become orphaned, those transactions are still valid and they may still be confirmed in another block. Some bloks confirmations is decent number of confirmations to deter attacks without 51% of the hashrate.

For cellbase transactions, there isn't referenced inputs for there. If the blocks somehow get orphaned, any subsequent transactions from that cellbase transaction would immediately be invalid as well. This could affect many transactions, as long as they are linked to that cellbase transaction. The more confirmations there is, the harder it is to happen.

## Consensus rule

For each input, if the referenced output transaction is cellbase, it must have at least CELLBASE_MATURITY confirmations; else reject this transaction.
