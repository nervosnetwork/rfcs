---
Number: 0000
Category: <TBD>
Status: Proposal
Author: Cipher Wang
Organization: Cryptape Ltd
Created: 2019-01-20
---

# Address Format

## Abstract

CKB Address Format is an application level [cell lock][cell-lock] display recommendation. In the consideration of user experience, it is necessary to put the raw H256 (may be variable in the future) cell lock into a verifiable and extensible format.

## Solution

CKB Address Format follows [Bitcoin base32 address format (BIP-173)][bip173] rules, which add a version prefix to the payload (such as cell lock and private key), and wrap them in **Bech32** encoding and a [BCH checksum][bch].

A Bech32 string is at most 90 characters long and consists of the **human-readable part**, the **separator**, and the **data part**.

The human-readable part is "ckb" for CKB mainnet, and "tcb" for CKB testnet. The separator is always "1". The data part is consist of version prefix and payload.

![](images/ckb-address.png)

## Version Prefix Convention
|           Type           | Version prefix |       Payload          | Base32 prefix |
|--------------------------|----------------|------------------------|---------------|
|  default                 | 0x00           | lock hash              |        q      |
|  private key             | 0x10           | private key            |        z      |
|  private key (encrypted) | 0x18           | encrypted private key  |        r      |

[cell-lock]:https://github.com/nervosnetwork/ckb/blob/develop/core/src/transaction.rs#L126

[bip173]: https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki

[bch]: https://en.wikipedia.org/wiki/BCH_code