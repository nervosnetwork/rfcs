---
Number: "0021"
Category: Standards Track
Status: Proposal
Author: Cipher Wang
Organization: Nervos Foundation
Created: 2019-01-20
---

# CKB Address Format

## Abstract

*CKB Address Format* is recommended to handle the encodings for both **lock script** and **type script** in application level. CKB address can package a script into a single line format, which is verifiable and human-readable.

## Data Structure

Both **lock script** and **type script** consist of three key properties, including *code_hash*, *hash_type* and *args*. Following the payload formatting rules outlined below, a script data structure can be encoded as a CKB address, which can be parsed for its original script reversely.

### Lock script
#### Payload Format Types

To generate a CKB address, we firstly encode lock script to bytes array, name *payload*. And secondly, we wrap the payload into final address format.

There are several methods to convert lock script into payload bytes array. We use 1 byte to identify the payload format.

| format type |                   description                  |
|:-----------:|------------------------------------------------|
|  0x01       | short version for locks with popular code_hash |
|  0x02       | full version with hash_type = "Data"           |
|  0x04       | full version with hash_type = "Type"           |

#### Short Payload Format

Short payload format is a compact format which identifies common used code_hash by 1 byte code_hash_index instead of 32 bytes code_hash.

```c
payload = 0x01 | code_hash_index | args
```

To translate payload to lock script, one can convert code_hash_index to code_hash and hash_type with the following *popular code_hash table*. And args as the args.

| code_hash_index |        code_hash     |   hash_type  |          args           |
|:---------------:|----------------------|:------------:|-------------------------|
|      0x00       | SECP256K1 + blake160 |     Type     |  blake160(PK)*          |
|      0x01       | SECP256K1 + multisig |     Type     |  multisig script hash** |
|      0x02       | anyone_can_pay       |     Type     |  blake160(PK)           |

\* The blake160 here means the leading 20 bytes truncation of Blake2b hash result.

\*\* The *multisig script hash* is the 20 bytes blake160 hash of multisig script. The multisig script should be assembled in the following format:

```
S | R | M | N | blake160(Pubkey1) | blake160(Pubkey2) | ...
```

Where S/R/M/N are four single byte unsigned integers, ranging from 0 to 255, and blake160(Pubkey1) it the first 160bit blake2b hash of SECP256K1 compressed public keys. S is format version, currently fixed to 0. M/N means the user must provide M of N signatures to unlock the cell. And R means the provided signatures at least match the first R items of the Pubkey list.

For example, Alice, Bob, and Cipher collectively control a multisig locked cell. They define the unlock rule like "any two of us can unlock the cell, but Cipher must approve". The corresponding multisig script is:

```
0 | 1 | 2 | 3 | Pk_Cipher_h | Pk_Alice_h | Pk_Bob_h
```

#### Full Payload Format

Full payload format directly encodes all data fields of lock script.

```c
payload = 0x02/0x04 | code_hash | args
```

The first byte identifies the lock script's hash_type, 0x02 for "Data", 0x04 for "Type". 

### Type script
#### Payload Format Types

The rule of CKB address generation for type script is almost the same as lock script. The encoding only needs to take care of the full address formatting, as `Short Payload Format` is not applicable for type script at the moment.

In the encoding rule, similarly we use 1 byte to identify the payload format but based from `0x80`. Since both lock script and type script have the same enum values for `hash_type`, which are "Data" and "Type", it is intended for the last hex character to reflect the same `hash_type` mapping for type script as lock script does.

| format type |                   description                  |
|:-----------:|------------------------------------------------|
|  0x82       | full version with hash_type = "Data"           |
|  0x84       | full version with hash_type = "Type"           |

#### Full Payload Format

Full payload format encodes all data fields of type script.

```c
payload = 0x82/0x84 | code_hash | args
```

### Format Types Allocation

As detailed in the `Payload Format Types` sections, so far the format type flags `0x0#` are reserved for lock script, while the flags `0x8#` are for type script. This allocation rule of format types can be referenced to derive either a lock script or type script from a CKB address. 

For example, if the byte value for format type is smaller than `0x80`, then it should follow the format rule of lock script to decode the payload. Otherwise, the CKB address represents a type script.

## Wrap to Address

We follow [Bitcoin base32 address format (BIP-173)][bip173] rules to wrap payload into address, which uses Bech32 encoding and a [BCH checksum][bch].

The original version of Bech32 allows at most 90 characters long. Similar with [BOLT][BOLT_url], we simply remove the length limit. The error correction function is disabled when the Bech32 string is longer than 90. We don't intent to use this function anyway, because there is a risk to get wrong correction result.

A Bech32 string consists of the **human-readable part**, the **separator**, and the **data part**. The last 6 characters of data part is checksum. The data part is base32 encoded. Here is the readable translation of base32 encoding table.

|       |0|1|2|3|4|5|6|7|
|-------|-|-|-|-|-|-|-|-|
|**+0** |q|p|z|r|y|9|x|8|
|**+8** |g|f|2|t|v|d|w|0|
|**+16**|s|3|j|n|5|4|k|h|
|**+24**|c|e|6|m|u|a|7|l|

The human-readable part is "**ckb**" for CKB mainnet, and "**ckt**" for the testnet. The separator is always "1".

![](images/ckb-address.png)

## Examples and Demo Code

```yml
== short address (code_hash_index = 0x00) test ==
args to encode:          b39bbc0b3673c7d36450bc14cfcdad2d559c6c64
address generated:       ckb1qyqt8xaupvm8837nv3gtc9x0ekkj64vud3jqfwyw5v

== short address (code_hash_index = 0x01) test ==
multi sign script:       00 | 01 | 02 | 03 | bd07d9f32bce34d27152a6a0391d324f79aab854 | 094ee28566dff02a012a66505822a2fd67d668fb | 4643c241e59e81b7876527ebff23dfb24cf16482
args to encode:          4fb2be2e5d0c1a3b8694f832350a33c1685d477a
address generated:       ckb1qyq5lv479ewscx3ms620sv34pgeuz6zagaaqklhtgg

== full address test ==
code_hash to encode:     9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8
with args to encode:     b39bbc0b3673c7d36450bc14cfcdad2d559c6c64
full address generated:  ckb1qjda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xw3vumhs9nvu786dj9p0q5elx66t24n3kxgj53qks
```

Demo code: https://github.com/CipherWang/ckb-address-demo 

[bip173]: https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki

[bch]: https://en.wikipedia.org/wiki/BCH_code

[BOLT_url]: https://github.com/lightningnetwork/lightning-rfc/blob/master/11-payment-encoding.md

[multisig_code]: https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/secp256k1_blake160_multisig_all.c
