---
Number: "0047"
Category: Standards Track
Status: Proposal
Author: fefe@magickbase.com
Created: 2023-08-08
---

# WalletConnect Namespaces Protocol

## Abstract

This RFC describes a namespaces protocol which is a standardized object defined by the [Chain Agnostic Improvement Proposal (CAIP)](https://github.com/ChainAgnostic/CAIPs) that ensures a common industry standard for chain agnostic purposes.

## Motivation

WalletConnect is an open-source protocol that enables secure and seamless communication between decentralized applications (dApps) and wallets on various blockchains. By establishing a remote connection using end-to-end encryption, WalletConnect allows users to interact with dApps through their preferred wallet without exposing their private keys.

Users will encounter two namespaces: the proposal namespace and the session namespace when connecting wallets and dApps. Upon approval, the wallet will then send a session namespace that includes all the accounts, chains, methods, and events it has approved.

## Specification

Here is an example of a session approval message passing the namespace.

```
{
  ...
    "namespaces": {
      "ckb": {
        "chains": [ "ckb:mainnet", ... ],
        "accounts": [ "ckb:mainnet:${account_id}" ],
        "methods": [ "ckb_signTransaction", ... ],
        "events": [ "accountChanged", ... ],
      }
    },
    "sessionProperties": {
      "scriptBases": "<script_base a>,<script_base b>",
    },
  ...
}
```

### chains

A general blockchain identification schema has been defined in [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md). Its implementation for the CKB blockchain is as stated below

| Component           | Description                       |
| ------------------- | --------------------------------- |
| caip2-like chain_id | namespace + : + chain_reference   |
| namespace           | ckb                               |
| chain_reference     | One of (mainnet, testnet, devnet) |

### accounts

> CAIP-10 defines a way to identify an account in any blockchain specified by CAIP-2 blockchain id.

For context, see the [CAIP-10](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md) specification.

| Component              | Description                                      |
| ---------------------- | ------------------------------------------------ |
| caip10-like account_id | namespace + : + chain_reference + : + identity   |
| namespace              | ckb                                              |
| chain_id               | One of (mainnet, testnet, devnet)                |
| identity               | The hash obtained by the first pk of the account |

### methods

#### ckb_getAddresses

Get the Address[^1] list by specific lock script base[^2], in the format of `<code_hash>:<hash_type>`.

- Parameters

```ts
{
    [<script_base>] :{
       page: {
         size: number           // the size of address list to return
         before: string         // used as the end point of the returned address list(excluded)
         after: string          // used as the start point of the returned address(excluded)
       },
       type: 'generate' | 'all' // set 'generate' to generate new addresses if necessary; set 'all' to get existent addresses
   }
}
```

- Returns

```ts
{
    '<script_base x>' : Address[],
    '<script_base y>' : Address[],
}
```

#### ckb_signTransaction

Get a Transaction[^3] over the provided instructions.

- Parameters

```ts
{
  data: {
     cell_deps: {
       out_point: {
         tx_hash: string
         index: string
       }
       dep_type: string
     }[]
     header_deps: string[]
     inputs: {
       previous_output: {
         index: string
         tx_hash: string
       }
       since: string
     }[]
     outputs: {
     capacity: string
       lock: {
         args: string
         code_hash: string
         hash_type: 'type' | 'data'
       },
       type: {
         args: string
         code_hash: string
         hash_type: 'type' | 'data'
       }
     }[]
     outputs_data: string[]
  },
  description: string
}
```

- Returns

```ts
{
  transaction: Transaction
}
```

#### ckb_signMessage

Get a signature for the provided message from the specified signer address.

- Parameters

```ts
{
   message: string, // the message to sign
   address: string  // address of which private to sign
}
```

- Returns

```ts
{
  signature: string
}
```

### events

#### accountChanged

Emit the event when the account changed

```ts
{
   name: "accountChanged",
   data: {
       account: string,
       addresses: Address[]
   },
}
```

#### addressesChanged

Emit the event when addresses changed

```ts
{
   name: "addressesChanged",
   data: {
        ...Address,
        changeType: 'add' | 'consume' // add: new addresses created; consume: addresses consumed
    }[]
}
```

#### chainChanged

Emit the event when the chain changed

```ts
{
   name: "chainChanged",
   data: string,
}
```

### compound types

#### Address

```ts
interface Address {
  address: string
  identifier: string
  description: string
  balance: string
  index: number
}
```

#### Transaction

```ts
interface Transaction {
  type: 'send' | 'receive' | 'create' | 'destroy'
  createdAt: string
  updatedAt: string
  timestamp: string
  value: string
  hash: string
  description: string
  blockNumber: string
  status: 'pending' | 'success' | 'failed'
  nervosDao: boolean
  sudtInfo?: {
    sUDT: Record<'tokenID' | 'tokenName' | 'symbol' | 'decimal', string>
    amount: string
  }
  nftInfo?: {
    type: 'send' | 'receive'
    data: string
  }
  assetAccountType?: 'CKB' | 'sUDT' | string
}
```

## Further reading

1. [Reference-level explanation](./Reference-level-explanation.md)
2. Namespaces https://docs.walletconnect.com/2.0/specs/clients/sign/namespaces

## Refs

[^1]: Address: a compound type of CKB address, defined as [Address](#address);
[^2]: Script Base: It's the combination of `code_hash` and `hash_type` of a specific `script` in the format `<code_hash>:<hash_type>`. Without a concrete `args` of the `script`, the `script base` refers to the set of an abstract script. The relation between `script base` and `script` can be considered as `class` and `instance`;
[^3]: Transaction: a compound type of CKB transaction, defined as [Transaction](#transaction).
