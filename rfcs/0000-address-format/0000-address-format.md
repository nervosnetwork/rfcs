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

CKB Address Format is an application level [lock script][script-define] display recommendation. The lock script consists of three key parameters, including version, args, and binary_hash. In the consideration of user experience, it is necessary to wrap the raw data structure into a verifiable and extensible format.

## Solution

CKB Address Format follows [Bitcoin base32 address format (BIP-173)][bip173] rules, which add a version prefix to the payload (such as binary_hash and private key), and wrap them in **Bech32** encoding and a [BCH checksum][bch].

A Bech32 string is at most 90 characters long and consists of the **human-readable part**, the **separator**, and the **data part**.

The human-readable part is "ckb" for CKB mainnet, and "cbt" for the testnet. The separator is always "1". The data part is consist of version prefix and payload. The version part means the address format version, and currently fixed to 0x00. The payload part encodes lock script by three data fields, payload = type | binary_ref | args.

![](images/ckb-address.png)

## Payload Part
|      type      |    binary_ref    |    args     |
|----------------|------------------|-------------|
|      0x00      | ref-id (Byte[4]) |  PK/PKHash  |
|      0x01      | ref-hash (H256)  |  PK/PKHash  |

* Note that current address format only support 1 parameter in args field. *

### ref-id

Binary_ref field in payload part could be either ref-id or ref-hash. Ref-hash is the simple H256 format binary_hash. Ref-id is a simplified binary_hash index, which stored in application level. Different ref-id means different binary_hash but much shorter length.

|     ref-id     | binary_hash meaning | args |
|----------------|---------------------|------|
|      SP2K      | SECP256K1 algorithm |  PK  |
|      SP2R      | SECP256R1 algorithm |  PK  |
|      P2PH      | SECP256K1 + hash160 | hash160(pk)  |
|      P2PK      | Alias of SP2K       |  PK  |

[script-define]:https://github.com/nervosnetwork/ckb/blob/develop/core/src/script.rs#L17

[bip173]: https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki

[bch]: https://en.wikipedia.org/wiki/BCH_code
