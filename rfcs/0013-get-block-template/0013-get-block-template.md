---
Number: 13
Category: Standards Track
Status: Draft
Author: Dingwei Zhang
Organization: Nervos Foundation
Created: 2019-01-02
---

# get_block_template

## Abstract

This RFC describes the decentralized CKB mining protocol.


## Motivation

The original `get_work` [[btc][0] [eth][1]] mining protocol simply issues block headers for a miner to solve, the miner is kept in the dark, and has no influence over block creation. `get_block_template` moves block creation to the miner, the entire block structure is sent, and left to the miner to (optionally) customize and assemble, miner are enabled to audit and possibly modify the block before hashing it,  this improves the security of the CKB network by making blocks decentralized.

## Specification

### Block Template Request

A JSON-RPC method is defined, called `get_block_template`. It accepts exactly three argument:

| Key          | Required | Type   | Description                                         |
| ------------ | -------- | ------ | --------------------------------------------------- |
| cycles_limit | No       | Number | maximum number of cycles to include in template     |
| size_limit   | No       | Number | maximum number of bytes to use for the entire block |
| max_version  | No       | Number | highest block version number supported              |

For `cycles_limit`, `size_limit` and `max_version`, if omitted, the default limit is used.
Servers SHOULD respect these desired maximums, but are NOT required to, clients SHOULD check that the returned template satisfies their requirements appropriately.

`get_block_template` MUST return a JSON Object containing the following keys:

| Key                   | Required | Type             | Description                                                                  |
| --------------------- | -------- | ---------------- | ---------------------------------------------------------------------------- |
| version               | Yes      | Number           | block version                                                                |
| difficulty            | Yes      | String           | difficulty in hex-encoded string                                             |
| current_time          | Yes      | Number           | the current time as seen by the server (recommended for block time)          |
| number                | Yes      | Number           | the number of the block we are looking for                                   |
| parent_hash           | Yes      | String           | the hash of the parent block, in hex-encoded string                          |
| cycles_limit          | No       | Number           | maximum number of cycles allowed in blocks                                   |
| size_limit            | No       | Number           | maximum number of bytes allowed in blocks                                    |
| commit_transactions   | Should   | Array of Objects | objects containing information for CKB transactions (excluding cellbase)     |
| proposal_transactions | Should   | Array of String  | array of hex-encoded transaction proposal_short_id                           |
| cellbase              | Yes      | Object           | information for cellbase transaction                                         |
| work_id               | No       | String           | if provided, this value must be returned with results (see Block Submission) |

#### Transaction Object

The Objects listed in the response's "transactions" key contains these keys:

| Key      | Required | Type             | Description                                                                                                                                                                                                                       |
| -------- | -------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| hash     | Yes      | String           | the hash of the transaction                                                                                                                                                                                                       |
| required | No       | Boolean          | if provided and true, this transaction must be in the final block                                                                                                                                                                 |
| cycles   | No       | Number           | total number of cycles, if key is not present, cycles is unknown and clients MUST NOT assume there aren't any                                                                                                                     |
| depends  | No       | Array of Numbers | other transactions before this one (by 1-based index in "transactions" list) that must be present in the final block if this one is; if key is not present, dependencies are unknown and clients MUST NOT assume there aren't any |
| data     | Yes      | String           | transaction [CFB][cfb] bytes in  hex-encoded string                                                                                                                                                                               |

### Block Submission

A JSON-RPC method is defined, called `submit_block`. to submit potential blocks (or shares). It accepts two arguments: the first is always a String of the hex-encoded block [CFB][cfb] bytes to submit; the second is String of work_id.

| Key     | Required | Type   | Description                                                           |
| ------- | -------- | ------ | --------------------------------------------------------------------- |
| data    | Yes      | String | block [CFB][cfb] bytes in  hex-encoded string                         |
| work_id | No       | String | if the server provided a workid, it MUST be included with submissions |



[0]: https://en.bitcoin.it/wiki/Getwork
[1]: https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getwork
[cfb]: https://github.com/nervosnetwork/rfcs/pull/47
