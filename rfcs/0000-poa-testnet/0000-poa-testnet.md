---
Number: "0000"
Category: <TBD>
Status: <TBD>
Author: <TBD>
Organization: <TBD>
Created: 2019-12-9
---

# POA testnet

## Motivation

The original intention of the aggron testnet is to provide a stable environment for contract development.

However, the mining power on aggron is volatile (shown in [charts](https://explorer.nervos.org/aggron/charts)), since a rational miner has no incentive to mine the testnet coins continuously. If any new miner or mining pool joins, the mining difficulty rises fast. Once they leave, the testnet block produce becomes extremely slow due to a sudden drop of hashrate, and the average block time would require minutes or even longer.

A POW blockchain only works when the miner has economic incentives, it's not adapted for the testnet, so we propose a new POA consensus testnet to serve the contract development purpose.

We expect the new POA testnet to be long term stable, and the testnet should be just like the mainnet without using POW. A contract developer should feel no difference when developing on POA testnet and mainnet.

In the purpose we design the POA testnet with the following principles:

* There should be a dynamic group of validators to maintain the POA network, each validator can submit block and vote. With enough votes, the network can allow new validators to join or evict a exists validators.
* The network cannot be halted or concerned by minority malicious validators, malicious validators should be eventually evicted by majority honest validators.
* The other part of the network should be the same as the mainnet(unless block header may need some extract context to do verification).

## POA protocol

We define the following variables:

* `VALIDATOR_COUNT` - Number of current validators, this value changed due to new validators join or old validator leaves.
* `ATTEST_INTERVAL` - A validator cannot attest two blocks within `ATTEST_INTERVAL` number. For example, a validator who attest block (6) must wait for at least `ATTEST_INTERVAL` blocks to do next attest: block (6 + `ATTEST_INTERVAL` + 1). Notice when the `VALIDATOR_COUNT` <= `ATTEST_INTERVAL`, the POA testnet will stuck forever due to no validators can attest a new block.
* `BLOCK_INTERVAL` - the interval of blocks, set to 8 seconds.
* `VOTE_LIMIT` - The least votes to make a new validator join or to evict an old validator, should be at least `VALIDATOR_COUNT / 2 + 1`.

### attest a new block

Instead of POW mining, a list of validators plays the role of producing blocks in POA testnet. Validators work in a round-robin style; in each block height, there exists a corresponded validator that attests to the new block by sign the block with its private key. For convenient, we call the validator who attest a block an **attester** to distinguish it from other validators.

The community chooses the initial validator list of the POA network by some off-chain governance mechanism, which does not cover in this proposal. At this moment, we can ignore the possible updating of the validator list; our protocol is simple enough works for both dynamic and fixed validators.

The protocol uses `n % VALIDATOR_COUNT` as the index to choose the attester from validators; each validator checks the index and decides whether to attest a new block itself or wait for another attester to produce a new block.

However, an in-turned attester may fail to produce a block due to network error or other reasons; in this case, other validators must produce the new block to make the POA testnet continue.

Validators can use a simple strategy:

1. For block height `n` a validator checks `n % VALIDAROR_COUNT`.
2. If `INDEX == n % VALIDATOR_COUNT`, which means the validator is in it's turn to attests block `n`. The validator should wait for `BLOCK_INTERVAL` seconds then attests the block `n` with difficulty set to `2`.
3. If `INDEX != n % VALIDATOR_COUNT`, which means the validator is not in it's turn to attests block `n`. The validator should wait for `BLOCK_INTERVAL + rand(VALIDATOR_COUNT) * 0.5` seconds to wait for another attester to produce a new block. If there are no new block produced during the time, the validator should attest a new block with difficulty set to `1`.
4. If the validator is the attester of the last block, wait for `ATTEST_INTERVAL` blocks then continue this strategy.

Notice the difficulty set to `2` when an in-turn attester produces a block and set to `1` when a not in-turn attester produces a block. This makes the in-turn attester's block total difficulty higher than the not in-turn attester's block; once two validators attest at the same height due to the network error, the other nodes still chooses the higher total difficulty block as the main chain.

`ATTEST_INTERVAL` is used to preventing malicious validators censor the POA network. A validator cannot attest two blocks within the `ATTEST_INTERVAL` number.  Consider the situation that malicious validators try to control the whole network: 

The first malicious validator must wait for `ATTEST_INTERVAL + 1` blocks to produce a block again. When the number of malicious validators is less than `ATTEST_INTERVAL + 1`, there must exist an honest validator who has the chance to submit a block includes majority voting to evict malicious validators.

`ATTEST_INTERVAL` can be set to `VALIDATOR_COUNT / 2` the honest validators could eventually evict malicious validators unless the half of validators corrupted.

### validator list and on-chain governance

As previously described, the POA testnet maintained by a group of validators. We have a build-in on-chain governance mechanism to allows updating the exists validator list. The on-chain governance mechanism designed to be loose; it allows several validators that greater than `VOTE_LIMIT` to sign a transaction together that updating the exists validators to a list of new validators.

As a natural thought, we can use a CKB cell to store the validator list, and the validator list can represent in a list of pubkey hash.

``` txt
pubkey_hash_1 | pubkey_hash_2 | pubkey_hash_3 ...
```

The `pubkey_hash` calculate from the secp256k1 pubkey: `blake160(Pubkey)`.

The pre-defined [multisig script] satisfies our on-chain governance requirements except that `multisig script` should be revealed so other nodes can check the new validator list.

So we choose to use a cell to represent the POA validator list. The cell contains the following `multisig script` in its data field, and with a multisig lock to lock the cell, the `multisig script` in data must corresponding to the lock's `multisig script`.

``` txt
0 | 0 | VOTE_LIMIT | VALIDATOR_COUNT | blake160(Pubkey1) | blake160(Pubkey2) | ...
```

We use a cell with `M of N` multisig lock to describe the validator list, the`M` set to `VOTE_LIMIT`, and `N` set to `VALIDATORS_COUNT`, we need an extra parameter to represent `ATTEST_INTERVAL`, so the final data is a 4 bytes little-endian number to represent `ATTEST_INTERVAL` plus a `multisig script`:

``` txt
ATTEST_INTERVAL(4 bytes little-endian) | 0 | 0 | VOTE_LIMIT | VALIDATOR_COUNT | blake160(Pubkey1) | blake160(Pubkey2) | ...
```

To change the validator list, anyone that collects enough votes(the signatures) can send a transaction to update the old validator list cell and construct a new validator list cell.

For simplify to track this cell, we assign a `type_id` on it; validators or anyone who wants to verify POA blocks must track this cell to keep validator list fresh.

Before sign a vote transaction, validators must make sure the `multisig script`  in the cell is valid and corresponding to the lock, and only one cell constructed to represent the validator list; otherwise, the POA consensus wound broken.

To simplify, the process of collecting votes do not include in the POA protocol.

### off-chain governance

The main intention of this document is to describe the POA testnet protocol. However, to better explain how the POA testnet validator works, we add this section as a suggestion to the off-chain governance, notice this section is more like a suggestion than a specification.

The intention of on-chain governance and dynamic validators design is to decentralize the POA testnet. Instead of the foundation itself, the community should finally maintain the POA testnet validators.

In the initial stage of the POA testnet, there may be just a small group validator that invited by the Nervos foundation. The validators together should governance the testnet and invite more validators from the community. A candidate validator may be a company or organization that influences the community. 

A possible way to elect candidate validators: 

The exists validators deploy a permissionless voting DAPP on the mainnet allows any company and organization can register them as a candidate. 
Anyone can deposit mainnet coins to vote on the candidates. 
The POA testnet validators obey the result of the DApp to invites the candidate to become the testnet validator.

Such an election should periodically host.

## POA header

CKB header encoded in fixed-length, the size of the `nonce` field is 128 bits, we can't put 256 bits secp256k1 signature into the header directly.

For the ease of implementation, instead of changing the block header structure, we put an extra POA payload `POAContext` in the cellbase transaction's first witness. To verify a header, we need both the header and the cellbase transaction.

Since  CKB constraint the first witness of cellbase to use the `CellbaseWitness` structure, we append the `POAContext` after the content of the first witness: `CellbaseWitness | POAContext`.

The structure of `POAContext`:

```txt
table POAContext {
    signature:              Byte65,
    transactions_count:     Uint32,
    raw_transactions_root:  Byte32, // witness transactions root
    merkle_proof:           Byte32Vec, // merkle proof of cellbase and voting txs
    voting_txs:             TransactionVec,
}
```

The first field `signature` is a secp256k1 signature signed by a validator. The signature's message is supposed to digest the whole block except the signature self, so the block hash is chosen to be the signature's message.

Since we put the signature into the cellbase transaction's witness, and the cellbase itself is digested by the `transaction_root` in the header. If we directly update the signature, the `transaction_root` and block hash also changed.

To solve this issue, an attester needs to zero the signature field of `POAContext`, then re-compute the block hash as signature's message, after signing replace the zero signature with actually signature.

An attester also needs to provide `cellbase transaction` and merkle proof to convince other validators in the [header-first synchronize]. So we also defined the following fields in the `POAContext`:

* `merkle_proof` - a merkle proof to prove that cellbase transaction is the first leaf of `witness_transactions_root`.
* `raw_transactions_root` - raw transactions root of current block, since CKB use `merkle_root(raw_transactions_root | witness_transactions_root)` to calculate `transactions_root`.
* `transactions_count` - the number of transactions.

A node does the following steps to verify a POA header:

1. verify merkle proof of cellbase transaction:
    1. calculate `witness_transactions_root = merkle_proof.root(cellbase.hash(), transactions_count)`
    2. calculate `transactions_root = merkle_root([raw_transactions_root, witness_transactions_root])`
    3. check `transactions_root` equals to `header.transactions_root`
2. zero `signature` field of POAContext:
    1. extract `POAContext` from cellbase transaction
    2. set `signature` field to "0x000...0000"
    3. set `POAContext` back to cellbase transaction witness
3. re-comute the block's `transaction_root` and block hash. 
4. recovery the pubkey, then check the pubkey hash is belongs to a validator.

Now we can verify a POAHeader with fixed validators. However, when validator list updated, the header-first synchronization may couldn't handle it correctly, think the following situation:
The initial validators list is `[A, B, C, D]`.
Since block `N`, the validator list updated to `[A, B, D, E]`.
A header-first synchronization from `N - 1` to `N + 4` wound fails to sync due to the unknown validator `E`.
To solve this issue, we require `POAContext` also provides the updated information of validators to verifiers.

So the `voting_txs` field of `POAContext` is introduced. When a block contains voting transactions, the attester must put voting transactions into `POAContext`, and the `merkle_proof` must prove both cellbase transaction and voting transactions are leaves of the `witness_transactions_root`.

A POA block header verifier should update its validator list according to the `voting_txs` field. With this design, we can verify headers and update the validator list without downloading the whole blocks.

### Header verification

We need to do some additional verification which slightly differs from the mainnet:

* `nonce` must set to all zero bytes.
* `compact_target` must set to `553648127`(difficulty 1) or `545259520`(difficulty 2) according to the attester index is whether equals to `N % VALIDATOR_COUNT` or not.

The other fields keep using mainnet verification rules.

## references

1. [Rinkeby proposal](https://github.com/ethereum/EIPs/issues/225)
2. [header-first synchronize]
3. [multisig script]

[header-first synchronize]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0004-ckb-block-sync/0004-ckb-block-sync.md "Header first synchronize."
[multisig script]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0021-ckb-address-format/0021-ckb-address-format.md#short-payload-format "multisig script."
