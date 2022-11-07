---
Number: "0045"
Category: Standards Track
Status: Proposal
Author: Quake Wang <quake.wang@gmail.com>
Created: 2022-08-23
---

# CKB Client Side Block Filter Protocol

## Abstract

This RFC describes a block filter protocol that could be used together with [RFC 0044](https://github.com/yangby-cryptape/rfcs/blob/pr/light-client/rfcs/0044-ckb-light-client/0044-ckb-light-client.md). It allows clients to obtain compact probabilistic filters of CKB blocks from full nodes and download full blocks if the filter matches relevant data.

## Motivation

Light clients allow applications to read relevant transactions from the blockchain without incurring the full cost of downloading and validating all data. Such applications seek to simultaneously minimize the trust in peers and the amount of bandwidth, storage space, and computation required. They achieve this by sampling headers through the fly-client protocol, verifying the proofs of work, and following the longest proof-of-work chain. Light clients then download only the blockchain data relevant to them directly from peers and validate inclusion in the header chain. Though clients do not check the validity of all blocks in the longest proof-of-work chain, they rely on miner incentives for security.

Full nodes generate deterministic filters on block data that are served to the client. A light client can then download an entire block if the filter matches the data it is watching for. Since filters are deterministic, they only need to be constructed once and stored on disk, whenever a new block is appended to the chain. This keeps the computation required to serve filters minimal.

## Specification

### Protocol Messages

#### GetBlockFilters

`GetBlockFilters` is used to request the compact filters of a particular range of blocks:

```
struct GetBlockFilters {
    start_number:   Uint64, // The height of the first block in the requested range
}
```

#### BlockFilters
`BlockFilters` is sent in response to `GetBlockFilters`, one for each block in the requested range:

```
table BlockFilters {
    start_number:   Uint64,     // The height of the first block in the requested range
    block_hashes:   Byte32Vec,  // The hashes of the blocks in the range
    filters:        BytesVec,   // The filters of the blocks in the range
}
```

1. The `start_number` SHOULD match the field in the GetBlockFilters request.
2. The `block_hashes` field size should not be larger than 1000.
3. The `block_hashes` and `filters` fields size SHOULD match.

#### GetBlockFilterHashes
`GetBlockFilterHashes` is used to request verifiable filter hashes for a particular range of blocks:

```
struct GetBlockFilterHashes {
    start_number:   Uint64,  // The height of the first block in the requested range
}
```

#### BlockFilterHashes
`BlockFilterHashes` is sent in response to `GetBlockFilterHashes`:

```
table BlockFilterHashes {
    start_number:               Uint64,     // The height of the first block in the requested range
    parent_block_filter_hash:   Byte32,     // The hash of the parent block filter
    block_filter_hashes:        Byte32Vec,  // The hashes of the block filters in the range
}
```

1. The `start_number` SHOULD match the field in the GetBlockFilterHashes request.
2. The `block_filter_hashes` field size SHOULD not exceed 2000


#### GetBlockFilterCheckPoints
`GetBlockFilterCheckPoints` is used to request filter hashes at evenly spaced intervals over a range of blocks. Clients may use filter hashes from `GetBlockFilterHashes` to connect these checkpoints, as is described in the
[Client Operation](#client-operation) section below:

```
struct GetBlockFilterCheckPoints {
    start_number:   Uint64,     // The height of the first block in the requested range
}
```

#### BlockFilterCheckPoints
`BlockFilterCheckPoints` is sent in response to `GetBlockFilterCheckPoints`. The filter hashes included are the set of all filter hashes on the requested blocks range where the height is a multiple of the interval 2000:

```
table BlockFilterCheckPoints {
    start_number:           Uint64,
    block_filter_hashes:    Byte32Vec,
}
```

1. The `start_number` SHOULD match the field in the GetBlockFilterCheckPoints request.
2. The `block_filter_hashes` field size should not be larger than 2000.

### Filter Data Generation

We follow the BIP158 for filter data generation and use the same Golomb-Coded Sets parameters P and M values. The only difference is that we only use cell's lock/type script hash as the filter data:

```
filter.add_element(cell.lock.calc_script_hash().as_slice());
if let Some(type_script) = cell.type_().to_opt() {
    filter.add_element(type_script.calc_script_hash().as_slice());
}
```

### Node Operation

Full nodes MAY opt to support this RFC, such nodes SHOULD treat the filters as an additional index of the blockchain. For each new block that is connected to the main chain, nodes SHOULD generate filters and persist them. Nodes that are missing filters and are already synced with the blockchain SHOULD reindex the chain upon start-up, constructing filters for each block from genesis to the current tip.

Nodes SHOULD NOT generate filters dynamically on request, as malicious peers may be able to perform DoS attacks by requesting small filters derived from large blocks. This would require an asymmetrical amount of I/O on the node to compute and serve.

Nodes MAY prune block data after generating and storing all filters for a block.

### Client Operation

This section provides recommendations for light clients to download filters with maximal security.

Clients SHOULD first sync with the full nodes by verifying the best chain tip through the fly-client protocol before downloading any filters or filter hashes. Clients SHOULD disconnect any outbound peers whose best chain has significantly less work than the known longest chain.


Once a client's tip is in sync, it SHOULD download and verify filter hashes for all blocks. The client SHOULD send `GetBlockFilterHashes` messages to full nodes and store the filter hashes for each block. The client MAY first fetch hashes by sending `GetBlockFilterCheckPoints`. The checkpoints allow the client to download filter hashes for different intervals from multiple peers in parallel, verifying each range of 2000 headers against the checkpoints.

Unless securely connected to a trusted peer that is serving filter hashes, the client SHOULD connect to multiple outbound peers to mitigate the risk of downloading incorrect filters. If the client receives conflicting filter hashes from different peers for any block, it SHOULD interrogate them to determine which is faulty. The client SHOULD use `GetBlockFilterHashes` and/or `GetBlockFilterCheckPoints` to first identify the first filter hashes that the peers disagree on. The client then SHOULD download the full block from any peer and derive the correct filter and filter hash. The client SHOULD ban any peers that sent a filter hash that does not match the computed one.

Once the client has downloaded and verified all filter hashes needed, and no outbound peers have sent conflicting headers, the client can download the actual block filters it needs. Starting from the first block in the desired range, the client now MAY download the filters. The client SHOULD test that each filter links to its corresponding filter hash and ban peers that send incorrect filters. The client MAY download multiple filters at once to increase throughput.

Each time a new valid block header is received, the client SHOULD request the corresponding filter hashes from all eligible peers. If two peers send conflicting filter hashes, the client should interrogate them as described above and ban any peers that send an invalid header.

If a client is fetching full blocks from the P2P network, they SHOULD be downloaded from outbound peers at random to mitigate privacy loss due to transaction intersection analysis. Note that blocks may be downloaded from peers that do not support this RFC.
## Deployment

This RFC is deploy identically to CKB Light Client Protocol ([RFC0044](rfcs/0044-ckb-light-client/0044-ckb-light-client.md)).

## Reference

1. BIP157: https://github.com/bitcoin/bips/blob/master/bip-0157.mediawiki
2. BIP158: https://github.com/bitcoin/bips/blob/master/bip-0158.mediawiki
