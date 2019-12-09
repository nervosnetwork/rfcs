---
Number: "0000"
Category: <TBD>
Status: <TBD>
Author: <TBD>
Organization: <TBD>
Created: <TBD>
---

# POA testnet

## Motivation

The original intention of aggron testnet is to provide a development-friendly testnet,
 allow develops to deploy and test contracts, it's supposed to be similar to mainnet and provide stable services.

However, the mining power on aggron is very unstable (shown in [chars](https://explorer.nervos.org/aggron/charts)), obviously for a reasonable miner there is no incitive to mine the testnet coins, and any new miner or mining pool join the testnet will speedup the block produces time temporally, then they leave, the testnet become extremely slow, the avg block time becomes few minutes or even longer.

A POW blockchain only works when the miner has economic incentives. So we propose a new POA consensus testnet to serve contract development purposes.

We expect the new POA testnet to be long term stable, the testnet should be just like the mainnet without using POW. A contract developer should feel no difference when developing on POA testnet and mainnet.

In the purpose we design the POA testnet with the following principles:

* There should be a dynamic group of validators to maintain the POA network, each validator can submit block and vote. With enough votes, the network can allow new validators to join or evict a exists validators.
* The network cannot be halted or concerned by minority malicious validators, malicious validators should be eventually evicted by majority honest validators.
* The other part of the network should be the same as the mainnet(unless block header may need some extract context to do verification).

## POA protocol

For easy to describe the protocol, we define the following variables:

* `VALIDATOR_COUNT` - Number of current validators, this value changed due to new validators join or old validator leaves.
* `ATTEST_INTERVAL` - A validator cannot attest two blocks within `ATTEST_INTERVAL` number. For example, a validator who attest block (6) must wait for at least `ATTEST_INTERVAL` blocks to do next attest: block (6 + `ATTEST_INTERVAL` + 1). Notice when the `VALIDATOR_COUNT` <= `ATTEST_INTERVAL`, the POA testnet will stuck forever due to no validators can attest a new block.
* `BLOCK_INTERVAL` - the interval of blocks, set to 8 seconds.
* `VOTE_LIMIT` - The least votes to make a new validator join or to evict an old validator, should be at least `VALIDATOR_COUNT / 2 + 1`.

## attest a new block

let's pre assuming the validator list already exists. Our protocol is simple enough that the change of validator list will not affect our purpose, we can assume the validator list is fixed for now.

Validators use a round-robin style to attest blocks.
For block `n`, the validator which index equals `n % VALIDATOR_COUNT` suppose to be the attester. However, a validator can fail to produce a block in time due to network congestion or other reasons, in this case, other validators should produce the block `n`.

Validators can use a simple strategy to achieve this:

* If `INDEX == n % VALIDATOR_COUNT`, wait for `BLOCK_INTERVAL` seconds then produce a new block with difficulty set to `2`.
* If `INDEX != n % VALIDATOR_COUNT`, wait for `BLOCK_INTERVAL + rand(VALIDATOR_COUNT) * 0.5` seconds then produce a new block with difficulty set to `1`.
* If the validator is the attester of the last block, wait for `ATTEST_INTERVAL` blocks then continue this strategy.

`ATTEST_INTERVAL` is used for preventing malicious validators to censors the POA network. When malicious validators are less than `ATTEST_INTERVAL + 1` that at least an honest validator have the chance to submit votes and evict malicious validators.

`ATTEST_INTERVAL` can be set to `VALIDATOR_COUNT / 2` the honest validators could eventually evict malicious validators unless the half of validators are corrupted.

## validator list

Validator list can be represented as a list of pubkey hash.

``` txt
pubkey_hash_1 | pubkey_hash_2 | pubkey_hash_3 ...
```

We can use an `M of N` multisig lock to describe the validator list, the `M` is set to `VOTE_LIMIT`, and `N` is `VALIDATORS_COUNT`.

To change the validator list, a validator can collect enough votes(the signatures) and send a tx to spent the old multisig lock and construct a new multisig lock with new pubkey hashes. A validator node can use `type_id` to track this validator list.

The pre-defined [multisig script](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0021-ckb-address-format/0021-ckb-address-format.md#short-payload-format) is satisfied the requirements, one except is the `multisig script` should be public so other nodes can check new validator list. Validators should make sure the entire `multisig script` is stored to cell data, and only one cell is constructed to represent the validator list.

Notice, the process of collect data is not included in the POA protocol for simplifying, a responsible validator should check the vote tx carefully before signing it.

## POA header

Unfortunately, CKB header is fixed-length, the `nonce` field takes 128 bits, we can't just put 256 bits secp256k1 signature into the header.

For easier implementation, instead change the block header structure, we put an extra POA context concatenated after cellbase transaction's first witness. To verify a header attestation, we need both the header and the cellbase transaction.

The structure of `POAContext`:

``` txt
table POAContext {
    signature:              Byte65,
    transactions_count:     Uint32,
    raw_transactions_root:  Byte32, // witness transactions root
    merkle_proof:           Byte32Vec, // merkle proof of cellbase and voting txs
    voting_txs:             TransactionVec,
}
```

The first field `signature` is a secp256k1 signature signed by a validator.

The signature message is supposed to digest the whole block except the signature itself.

Because the signature is put into the cellbase transaction's witness, and the cellbase itself is digested by the `transaction_root` in the header. If we change the cellbase transaction the `transaction_root` and block hash will also be changed.

We use merkle proof to prove the only changes of the header hash is caused by the `signature` field.

* `merkle_proof` - a merkle proof to prove that cellbase transaction belongs to a `witness_transactions_root`.
* `raw_transactions_root` - raw transactions root of current block.
* `transactions_count` - number of transactions.

A node does the following steps to verify the POA header:

1. verify merkle proof is correct.
    1. calculate `witness_transactions_root` from cellbase and merkle proof `merkle_proof.root(cellbase_hash, transactions_count)`
    2. calculate `transactions_root = merkle_root([witness_transactions_root, raw_transactions_root])`
    3. check `transactions_root` equals to `header.transactions_root`
2. zerorize `signature` field of POAContext in cellbase transaction.
    1. extract `POAContext` from cellbase transaction witness
    2. set `signature` field to "0x000...0000(32bytes)"
    3. set `POAContext` back to cellbase transaction witness
3. calculate signing message from zerorized cellbase transaction.
    1. calculate `transactions_root` with zerorized cellbase transaction
    2. replace header's old `transactions_root` then calculate `blake2b_256(header)` as signature message
4. recovery the pubkey from `signature` then check the pubkey hash is belongs to a validator.

Because we have a dynamic validators group, To keep enough information to verify a header, we also put the voting transactions into `voting_txs` field, a validator can verify header and get newest validator groups without download the whole blocks

## changes on CKB

(TODO)

## references

1. [Rinkeby proposal](https://github.com/ethereum/EIPs/issues/225)
