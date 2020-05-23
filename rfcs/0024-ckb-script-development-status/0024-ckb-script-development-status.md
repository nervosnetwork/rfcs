---
Number: "0024"
Category: Standards Track
Status: Proposal
Author: Dylan Duan
Organization: Nervos Foundation
Created: 2020-05-21
---

# CKB Script Development Status

## Abstract

This document shows a series of Nervos CKB system scripts information, including a brief introduction and _code_hash_, _out_point_(_tx_hash_ and _index_) in mainnet Lina and testnet Aggron so far.

## Motivation

Nervos Foundation providers a series of Nervos CKB system scripts, including:

- [Default Locks](#default-Locks):

  - [_SECP256K1/blake160_](#secp256k1blake160)
  - [_SECP256K1/multisig_](#secp256k1multisig)
  - [_anyone_can_pay_](#anyone_can_pay)

- [System Scripts](#system-scripts)

  - [_Nervos DAO_](#nervos-dao)

- [Fundamental Apps](#fundamental-apps)

  - [_Simple UDT_](#simple-udt)

To construct transactions with system scripts, the _code_hash_ and _out_point_ of system scripts in mainnet Lina and testnet Aggron are needed.

## Default Locks

### SECP256K1/blake160

[SECP256K1/blake160](https://github.com/nervosnetwork/ckb-system-scripts/wiki/How-to-sign-transaction#p2ph) [Source Code](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/secp256k1_blake160_sighash_all.c) is a popular script to signature and validate transaction in CKB.

SECP256K1/blake160 script is for **lock script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8` |
| `tx_hash`   | `0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c` |
| `index`     | `0`                                                                  |

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8` |
| `tx_hash`   | `0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37` |
| `index`     | `0`                                                                  |

### SECP256K1/multisig

[SECP256K1/multisig](https://github.com/nervosnetwork/ckb-system-scripts/wiki/How-to-sign-transaction#multisig) [Source Code](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/secp256k1_blake160_multisig_all.c) is a script which allows a group of users to sign a single transaction.

SECP256K1/multisig script is for **lock script**:

- Lina

| parameter   | value                                                                 |
| ----------- | --------------------------------------------------------------------- |
| `code_hash` | `0x5c5069eb0857efc65e1bca0c07df34c31663b3622fd3876c876320fc9634e2a8`  |
| `tx_hash`   | `0x71a7ba8fc963 49fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c` |
| `index`     | `1`                                                                   |

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x5c5069eb0857efc65e1bca0c07df34c31663b3622fd3876c876320fc9634e2a8` |
| `tx_hash`   | `0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37` |
| `index`     | `1`                                                                  |

### anyone_can_pay

[anyone_can_pay](https://talk.nervos.org/t/rfc-anyone-can-pay-lock/4438) [Source Code](https://github.com/nervosnetwork/ckb-anyone-can-pay) is is a script that can accept any amount of payment.

anyone_can_pay script is for **lock script**:

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x6a3982f9d018be7e7228f9e0b765f28ceff6d36e634490856d2b186acf78e79b` |
| `tx_hash`   | `0x69c70d65832cdfd97fe78d32eb25f840232f6b8cb6445464f11dad891b11fd83` |
| `index`     | `0`                                                                  |

## System Scripts

### Nervos DAO

[Nervos DAO](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0023-dao-deposit-withdraw/0023-dao-deposit-withdraw.md) [Source Code](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/dao.c) is a script and One function of Nervos DAO is to provide an dilution counter-measure for CKByte holders. By deposit in Nervos DAO, holders get proportional secondary rewards, which guarantee their holding are only affected by hardcapped primary issuance as in Bitcoin.

Nervos DAO script is for **type script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e` |
| `tx_hash`   | `0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c` |
| `index`     | `2`                                                                  |

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e` |
| `tx_hash`   | `0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f` |
| `index`     | `2`                                                                  |

## Fundamental Apps

### Simple UDT

[Simple UDT](https://talk.nervos.org/t/rfc-simple-udt-draft-spec/4333) [Source Code](https://github.com/nervosnetwork/ckb-miscellaneous-scripts/blob/master/c/simple_udt.c) provides a way to issue custom tokens on Nervos CKB.

Simple UDT script is for **type script**:

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x48dbf59b4c7ee1547238021b4869bceedf4eea6b43772e5d66ef8865b6ae7212` |
| `tx_hash`   | `0x0e7153f243ba4c980bfd7cd77a90568bb70fd393cb572b211a2f884de63d103d` |
| `index`     | `0`                                                                  |
