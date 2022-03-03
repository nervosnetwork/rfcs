---
Number: "0004"
Category: Standards Track
Status: Proposal
Author: Ian Yang <@doitian>
Created: 2018-07-25
---

# CKB Block Synchronization Protocol

Glossary of Terms

- Chain: a list of blocks starting with genesis block and consisted of successive blocks.
- Best Chain: a chain with the most accumulated PoW, and starting with a common genesis block which nodes agree with the consensus.
- Best Header Chain: a chain with the most PoW and consisted only of blocks in the status of Connected, Downloaded or Accepted. Please refer to block status part for more details.
- Tip: the latest block of a chain and Tip can be used to determine a specific chain.
- Best Chain Tip: the tip of Best Chain.

## Abstract

Block synchronization **must** be performed in stages with [Bitcoin Headers First](https://bitcoin.org/en/glossary/headers-first-sync) style. Blocks are downloaded in parts in each stage and are validated using the obtained parts.

1. Connecting Header: Get block header, and validate format and PoW.
2. Downloading Block: Get and validate the complete block. Transactions in ancestor blocks are not required.
3. Accepting Block: Validate the block in the context of the chain.

The purpose of stage execution is trying to preclude most of the attacks with the least cost. For example, in the first step, header connecting only accounts for 5% workload while there would be 95% possibility to say the block is valid.

According to the execution stages, there are 5 statuses of blocks:

1. Unknown: the status of a block is unknown before header connecting.
2. Invalid: A block and all of its descendant blocks are marked as 'Invalid' if any above steps failed.
3. Connected: A block succeeds in stage Connecting Header, and all its ancestor blocks are in a status of Connected, Downloaded or Accepted.
4. Downloaded: A block succeeds in stage Downloading Block, and all its ancestor blocks are in a status of Downloaded or Accepted.
5. Accepted: A block succeeds in stage Accepting Block, and all its ancestor blocks are in the status of Accepted.

Block status is propagated from the previous block to the later ones. Using the list index number above, the status number of a block is always less than or equal to its parent block. Here are conditions, if a block is invalid, all of its descendant blocks must be invalid. The cost of every step for synchronization is higher than the previous one and every step may fail. In this scenario, work will be wasted if a child block enters a later status before its parent block, and parent block is approved to be Invalid later.

Initially, Genesis block is in status Accepted and the rest is in status Unknown.

Below figures are used to indicate blocks in different status later on.

![](images/block-status.jpg "Block Status")

Genesis block of the nodes synchronizing **must be** the same, and all blocks can be constructed as a tree with the genesis block being the root. Blocks will be removed if they cannot connect to the root eventually.

Every participating node forms its local status tree where the chain consisting of Accepted blocks with the most PoW is considered as Best Chain. The chain that consists of blocks in the status of connected, downloaded or accepted with the most PoW is Best Header Chain.

The graph below is an example of Status Tree formed by Alice and blocks signed with name Alice is this node's current Best Chain Tip.

![](images/status-tree.jpg "Status Tree by Alice")

## Connecting Header

Headers first synchronization helps to validate PoW with the least cost. Since it costs the same work to construct PoW whether the included transactions are valid or not, attackers may use other more efficient ways. It means it's highly possible to regard the whole block as valid when the PoW is valid. This is why headers first synchronization would avoid resource-wasting on invalid blocks.

Because of the low cost, Headers synchronization can be processed in parallel with all peers and construct a highly reliable global graph. In this way, block downloading can be scheduled in the most efficient way to avoid wasting resource on lower PoW branch.

The goal of connecting header is demonstrated using the following example. When Alice connects to Bob, Alice asks Bob to send all block headers in Bob's Best Chain but not in Alice's **Best Header Chain** and then validate them to decide the blocks status are either Connected or Invalid.

When Alice connects header, keeping Best Header Chain Tip updated could help to decrease numbers of receiving headers already existed.

![](images/seq-connect-headers.jpg)

The graph above instructs the process of connecting headers. After a round of connecting headers, nodes are supposed to keep up-to-date using new block notification.

Take Alice and Bob above as an example, firstly Alice samples blocks from her Best Header Chain and sent the hashes to Bob. The basic principle of sampling is that later blocks are more possible to be selected than early blocks. For example, choose latest 10 blocks from the chain, then sample other blocks backward with 2's exponential increased intervals, a.k.a, 2, 4, 8, and etc. The list of hashes of the sampled blocks is called a Locator. In the following figure, the undimmed blocks are sampled. The genesis block should be always in the Locator.

![](images/locator.jpg)

Bob can get the latest common block between these two chains according to Locator and his own Best Chain. Because the genesis block is identical, there must be such kind of block. Bob will send all block headers from the common block to his Best Chain Tip to Alice.

![](images/connect-header-conditions.jpg)

In the figure above, blocks with undimmed color should be sent from Bob to Alice, and golden bordered one is the latest common block. There are three possible cases in the process:

1. If Bob's Best Chain Tip is in Alice's Best Header Chain, the latest common block will be Bob's Best Chain Tip and there are no block headers for Bob to send.
2. If Alice's Best Header Chain Tip is in Bob's Best Chain but is not the Tip, the latest common block will be Alice's Best Header Chain Tip.
3. If Alice's Best Header Chain and Bob's Best Chain fork, the latest common block will be the one before the fork occurs.

If there are too many blocks to send, pagination is required. Bob sends the first page, Alice will ask Bob for the next page if she finds out that there are more block headers. A simple pagination solution is to limit the maximum number of block headers returned each time, 2000 for example. If the number of block headers returned is equal to 2000, it means there may be more block headers could be returned. If the last block of a certain page is the ancestor of Best Chain Tip or Best Header Chain Tip, it can be optimized to get next page starting with the corresponding tip.

Alice could observe Bob's present Best Chain Tip, which is the last block received during each round of synchronization. If Alice's Best Header Chain Tip is exactly Bob's Best Chain Tip, Alice couldn't observe Bob's present Best Chain because Bob has no block headers to send. Therefore, it should start building from the parent block of Best Header Chain Tip when sending the first request in each round.

In the following cases, a new round of connection block header synchronization must be performed.

- Received a new block notification from the others, but the parent block status of the new block is Unknown.

The following exceptions may occur when connecting a block header:

- Alice observed that Bob's Best Chain Tip has not been updated for a long time, or its timestamp is old. In this case, Bob does not provide valuable data. When the number of connections reaches a limit, Bob could be disconnected first.
- Alice observed that the status of Bob's Best Chain Tip is Invalid. This can be found in any page without waiting for the end of a round of Connect Head. There, Bob is on an invalid branch, Alice can stop synchronizing with Bob and add Bob to the blacklist.
- There are two possibilities if the block headers Alice received are all on her own Best Header Chain. One is that Bob sends them deliberately. The other is that Best Chain changes when Alice wants to Connect Head. In this case, those block headers can only be ignored because they are difficult to distinguish. However, the proportion of received blocks already in Best Header Chain would be recorded. If the proportion is above a certain threshold value, Bob may be added to the blacklist.

Upon receiving the block header message, the format should be verified first.

- The blocks in the message are continuous.
- The status of all blocks and the parent block of the first block are not Invalid in the local Status Tree.
- The status of the parent block of the first block is not Unknown in the local Status Tree, which means Orphan Block will not be processed in synchronizing.

In this stage, verification includes checking if block header satisfies the consensus rules and if Pow is valid or not. Since Orphan Blocks are not processed, difficulty adjustment can be verified as well.

![](images/connect-header-status.jpg)

The figure above is the Status Tree of Alice after synchronized with Bob, Charlie, Davis, Elsa. The observed Best Chain Tip of each peer is also annotated in the figure.

If the Unknown status block is considered not on the Status Tree, new blocks in the status of Connected or Invalid will be extended to the leaves of the Status Tree during Connecting Header. As a result, Connecting Header stage explores and extends the status tree.

## Downloading Block

After Connecting Header is completed, the branch of some observed Best Chain Tip ends with one or more Connected block, a.k.a., Connected Chain. Downloading Block stage should start to request complete blocks from peers and perform verification.

With the status tree, synchronization can be scheduled to avoid useless work. An effective optimization is to download the block only if the Best Chain of the observed peer is better than the local Best Chain's. And priority can be ordered that the connected chain with more accumulated PoW should be processed first. The branch with lower PoW can only be attempted if a branch is confirmed to be invalid or if the download times out.

When downloading a branch, earlier blocks should be downloaded firstly due to the dependency of blocks, and should be downloaded concurrently from different peers to utilize full bandwidth. A sliding window can be applied to solve the problem.

Assume that the number of the first Connected status block to be downloaded is M and the length of the sliding window is N, then only the blocks numbered M to M+N-1 can be downloaded. After the block M is downloaded and verified, the sliding window moves to the next Connected block. If verification of block M fails, then the remaining blocks of this branch are all Invalid, and there is no need to continue downloading. If the window does not move towards the right for a long time, it is considered as time out. The node should try again later, or waits until the branch has new connected blocks.

![](images/sliding-window.jpg)

The figure above is an example of an 8 length sliding window. In the beginning, the downloadable block range from 3 to 10. After block 3 is downloaded, the window will move to block 5 because block 4 has already been downloaded in advance (as the figure above illustrated).

The Best Chains of peers are already known in stage Connecting Header, it is assumed that the peer has a block if it is in the peer's Best Chain and that peer is a full node. During the downloading, blocks in the sliding window can be split into several small stripes and those stripes could be scheduled among peers who have the blocks.

The downloaded transactions in a block may be mismatched with the Merkle Hash Root in the header, or the list contains duplicated txid. It doesn't mean that the block is invalid since it can only approve the downloaded block is incorrect. The block content provider could be added to the blacklist, but the block status should not be marked as invalid. Otherwise, the malicious nodes may pollute the nodes' Status Tree by sending the wrong block contents.

Verification of transaction lists and block header matching is required in this stage, but any validation that relies on the transaction contents in the ancestor block is not required, which will be placed in the next stage.

Several validations can be checked in this phase, for example, Merkle Hash validation, transaction txid cannot be repeated, transaction list cannot be empty, inputs and outputs cannot be blank at the same time, or only the first transaction can be generation transaction, etc.

Downloading Block will update the status of blocks in the best Connected Chain, from Connected to Downloaded or Invalid.

## Accepting Block

In the previous stage, there will be some chains which ended with one or more Downloaded status, hereinafter referred to as Downloaded Chain. If those chains' cumulative work is more than Best Chain Tip's, the complete validation in the chain context should be performed in this stage. If there are more than one chains satisfied, the chain with the most work should be performed first.

All the verification must be completed in this stage, including all rules that depend on historical transactions.

Because it involves UTXO (unspent transaction outputs) indexes, the cost of verification is huge in this phase. One set of UTXO indexes is sufficient in this simple solution. First rollback local Best Chain Tip necessarily. After that, verify blocks in the candidate best Downloaded Chain and add them to Best Chain one by one. If there is an invalid block during verification, the remain blocks in Downloaded Chain are also considered as Invalid. If so, Best Chain Tip would even have lower work than the previous Tip. It can be resolved in several different ways:

- If the work of Best Chain before rollback is more than present Tip, then restore the previous Best Chain.
- If the work of other Downloaded Chains is more than Best Chain that before rollback, try rollback and relocate to that chain.

The process of Accepting Block will change the status of blocks in the Downloaded chain, from Downloaded to Accepted or Invalid. The verified Downloaded Chain which has the most work will become the new local Best Chain.

## New block announcement

When the local Best Chain Tip changes, the node should push an announcement to peers. The best header with most cumulative work sent to each peer should be recorded, to avoid sending duplicate blocks in the announcement and sending blocks only peer doesn't know. This does not only record headers sent for new blocks, but also the ones sent as the responses in stage Connecting Header.

It is assumed that the peers already know the Best Sent Header and its ancestors, so these blocks can be excluded when sending new block announcements.

![](images/best-sent-header.jpg "Best Sent Header")

From the above example, Alice's Best Chain Tip is annotated with her name. The best header sent to Bob is annotated as "Best Sent To Bob". The undimmed blocks are the ones Alice should send to Bob as new blocks announcement. Following is the detailed description for each step:

1. In the beginning, Alice only has Best Chain Tip to send
2. Another new block is added to the best chain before Alice has a chance to send the headers. In this case, the last two blocks of Best Chain need to be sent.
3. Alice sends the last two blocks to Bob and updates Best Sent to Bob.
4. Alice's Best Chain relocates to another fork. Only blocks after the last common block should be sent to Bob.

How to send the announcement is determined by connection negotiated parameters and the number of new blocks to be announced:

- If there is only one block and the peer prefers Compact Block [^1], then use Compact Block.
- In other cases, just send block header list with an upper limit on the number of blocks to send. For example, if the limit is 8 and there are 8 or more blocks need to be announced, only the latest 7 blocks will be announced.

When receiving a new block announcement, there may be a situation the parent block's status is Unknown, also called Orphan Block. If so, a new round of Connecting Header is required immediately. When a Compact Block is received, and its parent block is the local Best Chain Tip, then the full block may be recovered from the transaction pool. If the recovery succeeds, the work of these three stages can be compacted into one. Otherwise, it falls back to a header-only announcement.

## Synchronization Status

### Configuration
- `GENESIS_HASH`: hash of genesis block
- `MAX_HEADERS_RESULTS`: the max number of block headers can be sent in a single message
- `MAX_BLOCKS_TO_ANNOUNCE`: the max number of new blocks to be announced
- `BLOCK_DOWNLOAD_WINDOW`: the size of the download window

### Storage
- Block Status Tree
- Best Chain Tip, decide whether to download blocks and accept blocks
- Best Header Chain Tip, used in Connecting Header to construct the Locator of the first request in each round.

Each connection peer should store:
- Observed Best Chain Tip
- The block header hash with the most work sent last time —— Best Sent Header

### Message Definition

Only related message and fields are listed here. See completed definition and documentation in the reference implementation.

The message passing is completely asynchronous. For example, sending `GetHeaders` does not block other requests. Also, there is no need to guarantee the order relationship between the requests and the responses. For example, node A sends `GetHeaders` and `GetBlocks` to B, and B can replies `SendBlock` firstly, and then `SendHeaders` to A.

Compact Block [^1] messages will be described in related Compact Block documentation.

### GetHeaders

It is used to request a block header from a peer in stage Connecting Header. The first-page request, and subsequent pages request can share the same GetHeaders message format. The difference between them is that the first page requests generate a Locator from the parent block of the local Best Header Chain Tip, and the subsequent page request generates the Locator using the last block in the last received page.

- `hash_stop`: tells peer to early return when building `SendHeaders` response.
- `block_locator_hashes`: Sampled hashes of the already known blocks

### SendHeaders

It is used to reply `GetHeaders`. It returns a headers list containing the headers of blocks starting right after the last common hash via the Locator, up to `hash_stop` or `MAX_BLOCKS_TO_ANNOUNCE` blocks, whichever comes first.

- `headers`：block headers list

### GetBlocks

It is used in Downloading Block stage.

- `block_hashes`:  list of block hashes to download.

### SendBlock

It is used to reply block downloading request of `GetBlocks`

- `block`: the requested block content

[^1]: Compact Block is a technique for compressing and transferring complete blocks. It is based on the fact that when a new block is propagated, the transactions should already be in the pool of other nodes. Under this circumstances, Compact Block only contains the list of transaction txid list and complete transactions which are predicated unknown to the peers. The receiver can recover the complete block using the transaction pool. Please refer to [Block and Compact Block Structure](../0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md#block-and-compact-block-structure) and related Bitcoin [BIP](https://github.com/bitcoin/bips/blob/master/bip-0152.mediawiki) for details.
