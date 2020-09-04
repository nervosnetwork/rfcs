---
Number: "0024"
Category: Informational
Status: Draft
Author: Dylan Duan
Organization: Nervos Foundation
Created: 2020-05-21
---

# CKB System Script List

## Abstract

System scripts are the smart contracts built and deployed by the CKB core team. System scripts complement the function of CKB in a flexible way. System scripts can provide core functions (e.g. [SECP256k1/blake160](#secp256k1blake160) and [Nervos DAO](#nervos-dao)), shared standard implementations (e.g. [Simple UDT](#simple-udt)) or other auxiliary infrastructure components. This document presents the information of all Nervos CKB system scripts, including a brief introduction and _code_hash_, _hash_type_, _out_point_(_tx_hash_ and _index_), _dep_type_ on mainnet Lina and testnet Aggron.

## Motivation

System scripts are used frequently in dapps, wallets, and other application development. A list of system scripts provides a handy reference to developers.

## List of System Scripts

- [Locks](#Locks)

  - [SECP256K1/blake160](#secp256k1blake160)
  - [SECP256K1/multisig](#secp256k1multisig)
  - [anyone_can_pay](#anyone_can_pay)

- [Types](#Types)

  - [Nervos DAO](#nervos-dao)

- [Standards](#Standards)

  - [Simple UDT](#simple-udt)

To construct transactions with system scripts, the _code_hash_, _hash_type_, _out_point_ and _dep_type_ of system scripts in mainnet Lina and testnet Aggron are needed.

## Locks

### SECP256K1/blake160

[SECP256K1/blake160](https://github.com/nervosnetwork/ckb-system-scripts/wiki/How-to-sign-transaction#p2ph) ([Source Code](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/secp256k1_blake160_sighash_all.c)) is the default lock script to verify CKB transaction signature.

SECP256K1/blake160 script is for **lock script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

### SECP256K1/multisig

[SECP256K1/multisig](https://github.com/nervosnetwork/ckb-system-scripts/wiki/How-to-sign-transaction#multisig) ([Source Code](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/secp256k1_blake160_multisig_all.c)) is a script which allows a group of users to sign a single transaction.

SECP256K1/multisig script is for **lock script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x5c5069eb0857efc65e1bca0c07df34c31663b3622fd3876c876320fc9634e2a8` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x71a7ba8fc96349fea0ed3a5c47992e3b4084b031a42264a018e0072e8172e46c` |
| `index`     | `0x1`                                                                |
| `dep_type`  | `dep_group`                                                          |

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x5c5069eb0857efc65e1bca0c07df34c31663b3622fd3876c876320fc9634e2a8` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37` |
| `index`     | `0x1`                                                                |
| `dep_type`  | `dep_group`                                                          |

### anyone_can_pay

[anyone_can_pay](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0026-anyone-can-pay/0026-anyone-can-pay.md) ([Source Code](https://github.com/nervosnetwork/ckb-anyone-can-pay/tree/deac6801a95596d74e2da8f2f1a6727309d36100)) allows a recipient to provide cell capacity in asset transfer.

anyone_can_pay script is for **lock script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x0fb343953ee78c9986b091defb6252154e0bb51044fd2879fde5b27314506111` |
| `hash_type` | `data`                                                               |
| `tx_hash`   | `0xa05f28c9b867f8c5682039c10d8e864cf661685252aa74a008d255c33813bb81` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

**Note:**

The `dep_type` of `anyone_can_pay` in Lina is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `anyone_can_pay` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c,
  index: 0x3
}
```

and the `out_point` of `anyone_can_pay` whose `dep_type` is `code` is

```
{
  tx_hash: 0xd032647ee7b5e7e28e73688d80ffc5fba306ee216ca43be4a762ec7e989a3daa,
  index: 0x0
}
```

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x86a1c6987a4acbe1a887cca4c9dd2ac9fcb07405bbeda51b861b18bbf7492c4b` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x4f32b3e39bd1b6350d326fdfafdfe05e5221865c3098ae323096f0bfc69e0a8c` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

## Types

### Nervos DAO

[Nervos DAO](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0023-dao-deposit-withdraw/0023-dao-deposit-withdraw.md) ([Source Code](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/dao.c)) is the script implements Nervos DAO.

Nervos DAO script is for **type script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c` |
| `index`     | `0x2`                                                                |
| `dep_type`  | `code`                                                               |

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x82d76d1b75fe2fd9a27dfbaa65a039221a380d76c926f378d3f81cf3e7e13f2e` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f` |
| `index`     | `0x2`                                                                |
| `dep_type`  | `code`                                                               |

## Standards

### Simple UDT

[Simple UDT](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0025-simple-udt/0025-simple-udt.md) ([Source Code](https://github.com/nervosnetwork/ckb-miscellaneous-scripts/blob/175b8b0933340f9a7b41d34106869473d575b17a/c/simple_udt.c)) implements the minimum standard for user defined tokens on Nervos CKB.

Simple UDT script is for **type script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x5e7a36a77e68eecc013dfa2fe6a23f3b6c344b04005808694ae6dd45eea4cfd5` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0xc7813f6a415144643970c2e88e0bb6ca6a8edc5dd7c1022746f628284a9936d5` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `code`                                                               |

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x48dbf59b4c7ee1547238021b4869bceedf4eea6b43772e5d66ef8865b6ae7212` |
| `hash_type` | `data`                                                               |
| `tx_hash`   | `0xc1b2ae129fad7465aaa9acc9785f842ba3e6e8b8051d899defa89f5508a77958` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `code`                                                               |
