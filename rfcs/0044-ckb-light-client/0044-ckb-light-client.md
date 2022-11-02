---
Number: "0044"
Category: Standards Track
Status: Proposal
Author: Boyu Yang <yangby@cryptape.com>
Created: 2022-08-18
---

# CKB Light Client Protocol

## Abstract

This RFC describes a light client protocol on CKB which allows clients to
verify that a blockchain is valid with limited resources.

## Motivation

Downloading and verifying all blocks is taking hours and requiring gigabytes
of bandwidth and storage. Hence, clients with limited resources cannot
verify transactions independently without trusting full nodes.
Even some light clients only download all block headers, the storage and
bandwidth requirements of those clients still increase linearly with the
chain length.
We propose a more efficient [FlyClient]-based light client protocol. It uses
a sampling protocol tailored for [NC-Max] difficulty adjustment algorithm.
It requires downloading only a logarithmic number of block headers while
storing only a single block header between executions.

## Background

### Merkle Mountain Range (MMR)

A [Merkle Mountain Range (MMR)][MMR] is a binary hash tree that allows for
efficient appends of new leaves without changing the value of existing
nodes.

In MMR, we use the insertion order to reference leaves and nodes.
We insert a new leaf to MMR as following steps:
- Insert leaf or node to next position.
- If the new inserted leaf or node has a left sibling, we merge the left and
  right nodes to produce a new parent node, then go back to step 1 to insert
  the node.

For example, we insert a leaf to the example MMR which has 11 leaves as
following steps:
- Insert leaf to next position: `19`.
- Then check the left sibling `18` and calculate parent node:
  `merge(mmr[18], mmr[19])`.
- Insert parent node to position `20`.
- Since the node `20` also has a left sibling `17`, calculate parent node:
  `merge(mmr[17], mmr[20])`.
- Insert new node to next position `21`.
- Since the node `21` have no left sibling, complete the insertion.

```
# An MMR with 11 leaves:
          14
       /       \
     6          13
   /   \       /   \
  2     5     9     12     17
 / \   /  \  / \   /  \   /  \
0   1 3   4 7   8 10  11 15  16 18

# After insertion of a new leaf:

          14
       /       \
     6          13            21
   /   \       /   \         /   \
  2     5     9     12     17     20
 / \   /  \  / \   /  \   /  \   /  \
0   1 3   4 7   8 10  11 15  16 18  19
```

#### Merkle Root

An MMR is constructed by one or more sub merkle trees (or mountains). Each
sub merkle tree's root is a peak in MMR, we calculate the MMR root by
bagging these peaks from left to right.

For example:
- In the above 11 leaf MMR we have 3 peaks: `14, 17, 18`, we bag these peaks
  from left to right to get the root:
  `merge(merge(mmr[14], mmr[17]), mmr[18])`.
- In the above 12 leaf MMR we have 2 peaks: `14, 21`, we bag these peaks
  from left to right to get the root: `merge(mmr[14], mmr[21])`.

#### Merkle Proof

The merkle proof is an array of hashes constructed with the following parts:
- A merkle proof from the leaf's sibling to the peak that contains the leaf.
- A hash that bags all right-hand side peaks, skip this part if no
  right-hand peaks.
- Hashes of all left-hand peaks from right to left, skip this part if no
  left-hand peaks.

We can reconstruct a merkle root from leaves and the merkle proof for those
leaves.

### The FlyClient Sampling Protocol Under Variable Difficulty

The client uses $g(x) = \frac{1}{(1-x)\ln{\delta}}$ as the probability
density function (PDF) to sample blocks.

In this probability, $x$ denotes the relative aggregate difficulty weight
and $\delta$ denotes the relative difficulty weight of the blocks which are
sampled with probability $1$.

Concretely, let $\delta = c ^ {k}$, where $c$ denote the fraction of the
adversary's computing power relative to the honest computing power, $p$
denote the probability of catching the adversary with a single sample and
$k = \frac{1}{p}$.

The sampling domain is restricted from $0$ to $1 − \delta$ and the blocks in
the last $\delta$ fraction region should always be checked directly.

Let $n$ denote the number of the blocks in the region which requires
verifying and $L$ denote the number of blocks in the last $\delta$ fraction
region. Obviously, we have $L = \delta \times n = c ^ {k} \times n$.
Accordingly, $k = \log_{c}{(\frac{L}{n})}$.

Define $p_{m} = (1 - \frac{1}{k})^{m}$ as the probability of failure, i.e.,
not catching the optimal adversary after check $m$ blocks. If we want
$p_{m} \le 2^{-\lambda}$, then
$m \ge \frac{\lambda}{\log_{\frac{1}{2}} {(1 - \frac{1}{k})}}$.

## Specification

### MMR Node Specification

We treat all blocks as the leaf nodes of an MMR, and its block number is the
index of leaves in that MMR.

#### MMR Node

Each MMR node is defined as follows:

- `children_hash`
  - For a leaf node, it's an empty hash (`0x0000...0000`).
  - For a non-leaf node, it's the hash of the serialized data that
    concatenate its two children nodes' hashes.
    A node's hash is the hash of its serialized data.

- `total_difficulty`
  - For a leaf node, it's the difficulty it took to mine the current block.
  - For a non-leaf node, it's the sum of `total_difficulty` in its child
    nodes.

- `start_*` and `end_*`
  - For a leaf node, both of them are the data of the current block.
  - For a non-leaf node:
    - `start_*` is the `start_*` of the leftmost node.
    - `end_*` is the `end_*` of the rightmost node.
  - There are 4 pairs of data:
    - `*_number` means a block number.
    - `*_epoch` means an epoch number.
    - `*_timestamp` means a block timestamp.
    - `*_compact_target` means a block compact target.

An MMR node will represent in [Molecule] schema as follows:
```
struct HeaderDigest {
    children_hash:          Byte32,

    total_difficulty:       Uint256,

    start_number:           Uint64,
    end_number:             Uint64,

    start_epoch:            Uint64,
    end_epoch:              Uint64,

    start_timestamp:        Uint64,
    end_timestamp:          Uint64,

    start_compact_target:   Uint32,
    end_compact_target:     Uint32,
}
```

#### Chain Root

A chain root for a block is the merkle root of all blocks on the chain
until that block (include itself).

After the epoch which MMR starts to be enabled in, the first 32 bytes of the
block extension should be the hash of its parent chain root.

#### Verifiable Header

A verifiable header is a header with the fields which are used to do
verification for its extra hash [\[1\]].

It contains a normal header, its uncles' hash, its block extension and the
chain root for its parent block.

### Protocol Messages

All protocol messages will represent in [Molecule] schema as follows:
```
union LightClientMessage {
    // A client asks the server for the last state of the chain.
    GetLastState,
    SendLastState,
    // A client asks the server for the proof of the last state which the
    // client known.
    GetLastStateProof,
    SendLastStateProof,
    // A client asks the server for the proof of some blocks.
    GetBlocksProof,
    SendBlocksProof,
    // A client asks the server for the proof of some transactions.
    GetTransactionsProof,
    SendTransactionsProof,
}

table GetLastState {
    // Whether the server is requested to push the state automatically.
    subscribe:                  Bool,
}

table SendLastState {
    // The verifiable header for the tip block in the server.
    last_header:                VerifiableHeader,
}

table GetLastStateProof {
    // The last block hash known by the client.
    // It could be different with the tip hash in the server.
    last_hash:                  Byte32,

    // The hash of the last proved block.
    start_hash:                 Byte32,
    // The block number of the last proved block.
    start_number:               Uint64,

    // How many continuous blocks before the tip block should be included at
    // least, if possible?
    last_n_blocks:              Uint64,
    // All blocks, whose total difficulty is not less than this difficulty
    // boundary, should be included in the proof.
    difficulty_boundary:        Uint256,
    // The sampled difficulties.
    difficulties:               Uint256Vec,
}

table SendLastStateProof {
    // If the block whose hash is sent from the client is on the chain, then
    // returns its verifiable header; otherwise, returns the verifiable
    // header for the tip block in the server.
    last_header:                VerifiableHeader,
    // The MMR proof for the chain root whose hash is in the last header.
    // Be empty if the block hash sent from the client isn't on the chain.
    proof:                      HeaderDigestVec,

    // Verifiable headers for all sampled blocks.
    headers:                    VerifiableHeaderVec,
}

table GetBlocksProof {
    // Refer to `GetLastStateProof.last_hash`.
    last_hash:                  Byte32,

    // Block hashes for the blocks which require verifying.
    block_hashes:               Byte32Vec,
}

table SendBlocksProof {
    // Refer to `SendLastStateProof.last_header`.
    last_header:                VerifiableHeader,
    // Refer to `SendLastStateProof.proof`.
    proof:                      HeaderDigestVec,

    // Block headers for the blocks which require verifying.
    headers:                    HeaderVec,

    // Block hashes for the blocks which were not found.
    missing_block_hashes:       Byte32Vec,
}

table GetTransactionsProof {
    // Refer to `GetLastStateProof.last_hash`.
    last_hash:                  Byte32,

    // Transaction hashes for the transactions which require verifying.
    tx_hashes:                  Byte32Vec,
}

table SendTransactionsProof {
    // Refer to `SendLastStateProof.last_header`.
    last_header:                VerifiableHeader,
    // Refer to `SendLastStateProof.proof`.
    proof:                      HeaderDigestVec,

    // A collection of filtered blocks, which include all requested
    // transactions, and be verified in the proof.
    filtered_blocks:            FilteredBlockVec,

    // Transaction hashes for the blocks which were not found.
    missing_tx_hashes:          Byte32Vec,
}
```

### Client-Server Interaction

We can divide the typical client-server interaction into 3 phases.

#### Phase 1: Client synchronizes to the latest tip block.

- At start, the client sends `GetLastState` messages to all discovered
  servers.

- All servers will reply `SendLastState` which includes their verifiable tip
  header and the total difficulty of the chain.

- The client will send `GetLastStateProof` to all servers which have replied
  their last state. The `GetLastStateProof` messages are different for
  different chain states, they are generated base on the sampling strategy
  which the light client used.

  _The sampling strategy is not a part of CKB. Each light client could
  choose their own sampling strategy._

  _In [CKB light client implementation], a sampling strategy based on the
  [FlyClient] sampling protocol under variable difficulty is used._

- The servers which received `GetLastStateProof` should reply
  `SendLastStateProof` to the client.

  If the last block that the client known is in the server's current chain,
  then the server should return the verifiable header of the last block that
  the client known, the proof for the sampled blocks and their verifiable
  headers.

  Otherwise, the server should only return its current verifiable tip
  header.

- Then the client will choose the best chain from all `SendLastStateProof`
  messages.

##### How a Server Choose Blocks from Sampled Difficulties?

Notice: Some variables in this section are defined in
[the "Background" section](#the-flyclient-sampling-protocol-under-variable-difficulty).

The server performs the following steps to decide which block should be
included in the proof:

- Construct a collection of blocks which is denoted as `reorg_n_blocks`.

  Check if the start block, which is sent from the client, is an ancestor
  block of the tip block.

  - If true, then left `reorg_n_blocks` to be empty.

  - Otherwise:

    - Find the block which is an ancestor block of the tip block and its
    number is the same as the start block.

    - Add the last $L$ blocks before the block, which is found in the
    previous step, into `reorg_n_blocks`.

- Construct a collection of blocks which is denoted as `last_n_blocks`.

  - Find the first block whose total difficulty is not less than
  $D_{\mathrm{boundary}}$.

  - If the number of blocks between the block, which is found in the
  previous step, and the tip block (excluded), is greater than $L$, then
  `last_n_blocks` includes all these blocks; otherwise, `last_n_blocks`
  includes the last $L$ blocks before the tip block.

- Construct a collection of blocks which is denoted as `sampled_blocks`.

  - Let $D_{\mathrm{boundary}}^{'}$ denote the total difficulty of the first
  block in `last_n_blocks`.

  - For each difficulty in the sampled difficulties, try to find the first
  block whose total difficulty is not less than it; if the total difficulty
  of this block is less than $D_{\mathrm{boundary}}^{'}$ and it's not a
  duplicate block, then add it into `sampled_blocks`.

  The sampled difficulties should be sorted.

- The proof should include all blocks in `reorg_n_blocks`, `last_n_blocks`,
  and `sampled_blocks`.

  And, the set of block headers should be sorted by theirs block numbers.

##### The Sampling Strategy used in the Official CKB Light Client

Notice: Some variables in this section are defined in
[the "Background" section](#the-flyclient-sampling-protocol-under-variable-difficulty).

In the official implementation of CKB light client, the sampling strategy is
based on the [FlyClient] sampling protocol under variable difficulty.

At first, the client should have a tip block header which requires
verification, and its parent chain root whose hash stored in that block, and
the total difficulty until that block (included that block).

Moreover, the client chooses the latest verified block as the start block.
If there are no verified blocks, the client should choose the genesis block
as the start block.

Then the client performs the following steps to samples blocks:
- Let region $R_{\mathrm{full}}$ denote the region between the start block
  and the tip block (excluded).
- Calculate $n$, which is the number of blocks in the region $R_{\mathrm{full}}$.
- Let $c = 0.5$ and $L = 100$, then calculate $k$ with the formula
  $k = \log_{c}{(\frac{L}{n})}$.
- Compare $n$ with $L$:
  - If $n \le L$, skip the sampling.
  - Otherwise:
    - Let $\lambda = 50$, then calculate $m$ with the formula
      $m = \lceil \frac{\lambda}{\log_{\frac{1}{2}} {(1 - \frac{1}{k})}} \rceil$.
    - Let $D_{\mathrm{start}}$ denote the total difficulty of the start
      block and $D_{\mathrm{end}}$ denote the total difficulty of the tip
      block.
    - Calculate the difficulty boundary $D_{\mathrm{boundary}}$, which is
      the start boundary of last $\delta$ fraction region, with formula
      $D_{\mathrm{boundary}} = D_{\mathrm{start}} + (1 - \delta)(D_{\mathrm{end}} - D_{\mathrm{start}})$.
    - Calculate $\delta = c ^ {k}$.
    - Use the PDF $g(x)$ to random $m - L$ difficulties, which are satisfied
      $d_{i} \in \left[ D_{\mathrm{start}}, D_{\mathrm{boundary}} \right), i \in \left[ 0, m-L-1 \right]$
      as the samples.

After sampling, the client sends a request to the server, namely, a CKB full
node, with following data:
- The blocks hash of the tip block that client knows.
- The blocks hash of the start block.
- The blocks number of the start block.
- The number $L$.
- The difficulty boundary $D_{\mathrm{boundary}}$.
- The difficulty samples. If there are no difficulties sampled in the
  previous step, leave them to be empty.

At last, the server replies the proof of the sampled blocks.

Accordingly, the client can treat that tip block as a valid tip block after
checking the returned proof.

#### Phase 2: Client asks a proof for some blocks.

After [phase 1], the client gets a trusted chain based on a proved tip block.

Then the client can use this phase to check blocks whether they are on that
trusted chain or not.

- At the start, the client sends the `GetBlocksProof` message, which
  contains the last block hash it knows, and hashes of the blocks which
  require verifying, to the server which has the best chain.

- Then, the server should reply a `SendBlocksProof` message.

  If the last block that the client known is in the server's current chain,
  then the server should return
  - the verifiable header of the last block that the client knows,
  - a proof for blocks which are from the provided block hashes and in the
    current chain,
  - the headers of those proved blocks,
  - hashes of blocks which are from the provided block hashes but not in the
    current chain.

  Otherwise, the server should only return its current verifiable tip
  header.

#### Phase 3: Client asks a proof for some transactions.

After [phase 1], the client gets a trusted chain based on a proved tip block.

Then the client can use this phase to check transactions whether they are on
that trusted chain or not.

- At the start, the client sends the `GetTransactionsProof` message, which
  contains the last block hash it knows, and hashes of the transactions
  which require verifying, to the server which has the best chain.

- Then, the server should reply a `SendTransactionsProof` message.

  If the last block that the client known is in the server's current chain,
  then the server should return
  - the verifiable header of the last block that the client knows,
  - a proof for blocks which contain valid transactions from the provided
    transaction hashes,
  - the proofs that proving those valid transactions are in those blocks,
  - hashes of transactions which are from the provided transaction hashes
    but not in the current chain.

  Otherwise, the server should only return its current verifiable tip
  header.

## Limitations

To avoid attacks by malicious clients, there are few limitations in server
side.
- In `GetLastStateProof` messages, the sum of the size of difficulties and 2
  times of the `last_n_blocks` should NOT greater than 1000.
- In `GetBlocksProof` messages, the size of block hashes should NOT greater
  than 1000.
- In `GetTransactionsProof` messages, the size of transactions hashes should
  NOT greater than 1000.

There are also few limitations in messages to improvement performance.
- In `GetLastStateProof` messages, the difficulties should be sorted.
- In `SendLastStateProof` messages, the headers should be sorted.

##### How a Server Choose Blocks from Sampled Difficulties?

## Deployment

Since CKB doesn't record the hashes of chain roots into headers at the start,
so it requires a soft fork to extend the relevant consensus rules.

Hence, this feature should be deployed concurrently with
[RFC-0043 CKB softfork activation].

In fact, it uses a modified version of [RFC-0043 CKB softfork activation],
which uses the cellbase witness field instead of the block header version
for signaling.

The parameters[\[2\]] to activate this feature are:
| Parameters | For CKB Testnet | For CKB Mainnet |
|-------|---------------|---------------|
| `name` | LightClient | LightClient |
| `bit` | 1 | 1 |
| `start_epoch` | 5346 (approx. 2022-10-31 15:00:00 UTC) | TBD |
| `timeout_epoch` | 5616 (approx. 2022-12-14 15:00:00 UTC) | TBD |
| `period` | 42 | TBD |
| `threshold` | 75% | TBD |
| `min_activation_epoch` | 5676 (approx. 2022-12-24 15:00:00 UTC) | TBD |

> Some parameters for CKB mainnet are to be determined.

And we also have to create all MMR nodes for blocks before that epoch to
make sure that the indexes of the MMR leaves are equal to the block numbers.

If users have data which generated by the previous version of CKB, they have
to do data migration before enable this feature.
And once the migration started, the data will no longer be compatible with
all older versions of CKB.

## References

- [FlyClient: Super-Light Clients for Cryptocurrencies][FlyClient]
- [Merkle Mountain Ranges][MMR]

[\[1\]]: ../0031-variable-length-header-field/0031-variable-length-header-field.md#specification
[\[2\]]: ../0043-ckb-softfork-activation/0043-ckb-softfork-activation.md#parameters
[phase 1]: #phase-1-client-synchronizes-to-the-latest-tip-block
[FlyClient]: https://eprint.iacr.org/2019/226.pdf
[NC-Max]: ../0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md
[MMR]: https://github.com/opentimestamps/opentimestamps-server/blob/master/doc/merkle-mountain-range.md
[Molecule]: ../0008-serialization/0008-serialization.md#molecule
[RFC-0043 CKB softfork activation]: ../0043-ckb-softfork-activation/0043-ckb-softfork-activation.md
[CKB light client implementation]: https://github.com/nervosnetwork/ckb-light-client
