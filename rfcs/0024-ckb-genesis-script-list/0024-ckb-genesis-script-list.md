---
Number: "0024"
Category: Informational
Status: Final
Author: Dylan Duan
Organization: Nervina Labs
Created: 2020-05-21
---

# CKB Genesis Script List

## Abstract

Genesis scripts are the smart contracts built by the CKB team and set in the CKB genesis block. Genesis scripts provide core functions like (e.g. [SECP256k1/blake160](#secp256k1blake160) and [Nervos DAO](#nervos-dao)). This document presents the information of all Nervos CKB genesis scripts, including a brief introduction and _code_hash_, _hash_type_, _out_point_(_tx_hash_ and _index_), _dep_type_ on mainnet Lina and testnet Aggron.

## Motivation

Genesis scripts are used frequently in dapps, wallets, and other application development. A list of genesis scripts provides a handy reference to developers.

## List of Genesis Scripts

- [Locks](#Locks)

  - [SECP256K1/blake160](#secp256k1blake160)
  - [SECP256K1/multisig](#secp256k1multisig)

- [Types](#Types)

  - [Nervos DAO](#nervos-dao)
  - [Type ID](#type-id)

To construct transactions with genesis scripts, the _code_hash_, _hash_type_, _out_point_ and _dep_type_ of genesis scripts in mainnet Lina and testnet Aggron are needed.

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


### Type ID

[Type ID](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0022-transaction-structure/0022-transaction-structure.md#type-id) ([Source Code](https://github.com/nervosnetwork/ckb/blob/master/script/src/type_id.rs)) is the builtin type script to support unique and immutable reference. The _code_hash_ and _hash_type_ are fixed and the same on mainnet Lina and testnet Aggron and the `dep_type` is no need. 

Type ID script is for **type script**:

- Lina & Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x00000000000000000000000000000000000000000000000000545950455f4944` |
| `hash_type` | `type`                                                               |
