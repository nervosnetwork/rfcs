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

**Note:**

The `dep_type` of `SECP256K1/blake160` in Lina is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `secp256k1_blake160_sighash_all` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c,
  index: 0x3
}
```

and the `out_point` of `secp256k1_blake160_sighash_all` is

```
{
  tx_hash: 0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c,
  index: 0x1
}
```

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

**Note:**

The `dep_type` of `SECP256K1/blake160` in Aggron is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `secp256k1_blake160_sighash_all` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f,
  index: 0x3
}
```

and the `out_point` of `secp256k1_blake160_sighash_all` is

```
{
  tx_hash: 0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f,
  index: 0x1
}
```

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

**Note:**

The `dep_type` of `SECP256K1/multisig` in Lina is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `secp256k1_blake160_multisig_all` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c,
  index: 0x3
}
```

and the `out_point` of `secp256k1_blake160_multisig_all` is

```
{
  tx_hash: 0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c,
  index: 0x4
}
```

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x5c5069eb0857efc65e1bca0c07df34c31663b3622fd3876c876320fc9634e2a8` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0xf8de3bb47d055cdf460d93a2a6e1b05f7432f9777c8c474abf4eec1d4aee5d37` |
| `index`     | `0x1`                                                                |
| `dep_type`  | `dep_group`                                                          |

**Note:**

The `dep_type` of `SECP256K1/blake160` in Aggron is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `secp256k1_blake160_multisig_all` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f,
  index: 0x3
}
```

and the `out_point` of `secp256k1_blake160_multisig_all` is

```
{
  tx_hash: 0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f,
  index: 0x4
}
```

### anyone_can_pay

[anyone_can_pay](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0026-anyone-can-pay/0026-anyone-can-pay.md) ([Source Code](https://github.com/nervosnetwork/ckb-production-scripts/blob/c4ed39df33a14d7a2e612ad058b5297ba4272265/c/anyone_can_pay.c)) allows a recipient to provide cell capacity in asset transfer.

anyone_can_pay script is for **lock script**:

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0xd369597ff47f29fbc0d47d2e3775370d1250b85140c670e4718af712983a2354` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x4153a2014952d7cac45f285ce9a7c5c0c0e1b21f2d378b82ac1433cb11c25c4d` |
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
  tx_hash: 0x58eb58e2e3dd9852099a19424cf6e63b5238afe92e3085561b8feafced6d6876,
  index: 0x0
}
```

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x3419a1c09eb2567f6552ee7a8ecffd64155cffe0f1796e6e61ec088d740c1356` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0xec26b0f85ed839ece5f11c4c4e837ec359f5adc4420410f6453b1f6b60fb96a6` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

**Note:**

The `dep_type` of `anyone_can_pay` in Aggron is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `anyone_can_pay` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f,
  index: 0x3
}
```

and the `out_point` of `anyone_can_pay` is

```
{
  tx_hash: 0xce29e27734b3eb6f8b6a814cef217753ac2ccb4e4762ecc8b07d05634d8ba374,
  index: 0x0
}
```

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
