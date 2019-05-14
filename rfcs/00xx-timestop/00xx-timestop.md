---
Number: "00xx"
Category: Standards Track
Status: Draft
Author: Yaning Zhang
Created: 2019-05-14
---

# Abstract

Allowing the miner to specify whether the current (fee paid) mempool is presently being flooded with transactions.They can enter a "1" value into the timestop of the block header. If the timestop in the block header is "1", then that block will not count towards the relative height maturity for the `since` value and the block is designated as a congested block. There is an uncongested block height (which is always lower than the normal block height. This block height is used for the `since` value, which only counts block maturity (confirmations).

A miner can elect to define the block as a congested block or not. The default code could automatically set the congested block flag as "1" if the mempool is above some size and the average fee for that set size is above some value. However, a miner has full discretion to change the rules on what automatically sets as a congested block, or can select to permanently set the congestion flag to be permanently on or off. It’s expected that most honest miners would use the default behavior defined in their miner and not organize a 51% attack.

For example, if a parent transaction output is spent by a child with a `since` value of 10, one must wait 10 confirmations before the transaction becomes valid. However, if the timestop flag has been set, the counting of confirmations stops, even with new blocks. If 6 confirmations have elapsed (4 more are necessary for the transaction to be valid), and the timestop block has been set on the 7th block, that block does not count towards the `since` requirement of 10 confirmations; the child is still at 6 blocks for the relative confirmation value. Functionally, this will be stored as some kind of auxiliary timestop block height which is used only for tracking the timestop value. When the timestop is set, all transactions using an `since` value will stop counting until the timestop bit has been unset. This gives sufficient time and block-space for transactions at the current auxiliary timestop block height to enter into the blockchain, which can prevent systemic attackers from successfully attacking the system.

# Motivation

The timestop turns the security risk into more hold-up delay in the event of a DoS attack, this mitigates a flood of transactions by a malicious attacker. This could migrate the "mass exit" problem in [plasma](https://plasma.io) and the DoS attack during the challenge period of various off-chains.

# Specification

## Timestop in header

Block header add a new `bool` field `timestop`:

* `true` represents the block is congested.
* `false` represents the block is uncongested.

Before filling the block with transactions, the miner should always set the `timestop` firstly since this `timestop` would effect the validity of the transaction. If the miner fills some transactions and changed the `timestop` later, this may lead to a valid block.

If the node receive the block from others, it should check the block transaction validity according the block `timestop`.

## Miner config

And add two new fileds in miner config:

* `u32` type `congested_size`, if the transaction set size in mempool is more than or equal to `congested_size`, the block mined by the miner will be set as congested and the `timestop` will be set as `true`; otherwise `false`. The miner can config any valid `u32`, if `0` it means the mined block is always congested. If the `congested_size` set as the MAX value of `u32` (2 ** 32 - 1 = 4294967295), it means that mined block is always uncongested. The CKB should provide a default value for it.
* `u256` type `congested_fee`, if the transaction average fee in mempool is more than or equal to `congested_fee`, the block mined by the miner will be set as congested and the `timestop` will be set as `true`; otherwise `false`. The miner can config any valid `u256`, if `0` it means the mined block is always congested. If the `congested_fee` set as the MAX value of `u256` (2 ** 256 - 1 = 115792089237316195423570985008687907853269984665640564039457584007913129639935), it means that mined block is always uncongested. The CKB should provide a default value for it.

## Work with transaction valid since

The `timestop` could work with transaction valid since when it's a **relative block based lock-time**. If a transaction input has `since` field and it represents 10 blocks relative block based lock-time. One must wait 10 confirmations before the transaction becomes valid. If 6 confirmations have elapsed (4 more are necessary for the transaction to be valid), and the timestop block has been set on the 7th block, that block does not count towards the `since` requirement of 10 confirmations; the child is still at 6 blocks for the relative confirmation value. The pseudocode is as blow:

```
if input.since is relative block based lock-time
    timestop_height = 0
    for block in (from input.previous_output.block to input.block)
        if block.header.timestop == 0
            timestop_height = timestop_height + 1

    if input.since <= timestop_height
        valid
    else
        invalid
```

CKB could use some spare bitmap struct to cache the blockchain `timestop` block numbers, this would accelerate the counting timestop block.

## VM Syscalls

The CKB VM should add some syscall to fetch the `timestop_height`. 

# References
- [Transaction valid since](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0017-tx-valid-since/0017-tx-valid-since.md)
- [The Bitcoin Lightning Network](http://lightning.network/lightning-network-paper.pdf)
