---
Number: "0000"
Category: Consensus (Hard Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-02-07
---

# Add a variable length field in the block header

## Abstract

This document proposes adding an optional variable length field to the block header.

## Motivation

Currently, the block header is a fixed length structure. Each header consists of 208 bytes.

Many extensions require adding new fields into the block. For example, PoA for testnet requires a 64 bytes signature, and flyclient also needs to add a 64 bytes hash.

There's no enough reserved bits in the header for these extensions. There's a workaround to store these data in the cellbase transaction, but this solution has a big overhead for clients which wants to quickly verify the data using PoW only. If the data are stored in the cellbase transaction, the client has to download the cellbase transaction and the merkle tree proof of the cellbase transaction, which can be larger than the block header itself.

This document proposes a solution to add a variable length field to the block header. How the new field is interpreted is beyond the scope of this document and must be defined and deployed via a future soft fork.

## Design

The block header is encoded as a molecule struct, which consists of fixed length fields. The header binary is just the concatenation of all the fields in sequence.

There are many different ways to add the variable length field to the block header. I have listed some options below for discussion.

1. [Appending the Field At the End](./1-appending-the-field-at-the-end.md)
2. [Using Molecule Table in New Block Headers](./2-using-molecule-table-in-new-block-headers.md)
3. [Appending a Hash At the End](./3-appending-a-hash-at-the-end.md)
4. [Reusing `uncles_hash` in the Header](./4-reusing-uncles-hash-in-the-header.md)

----

TODO

## Specification
## Security
## Test Vectors
## Rationale
## Deployment
## Backward compatibility
## Acknowledgments