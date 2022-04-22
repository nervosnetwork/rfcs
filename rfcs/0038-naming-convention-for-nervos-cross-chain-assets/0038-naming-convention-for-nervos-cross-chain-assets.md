---
Number: "0038"
Category: Informational
Status: Draft
Author: Hanlei Liang
Organization: Nervos Foundation
Created: 2022-04-22
---

# Naming Convention for Nervos Cross-Chain Assets

## Abstract

This document specifies the naming convention for corresponding shadow assets that cross from other public chains to Nervos through Force Bridge.

> **\*Shadow Assets**
>
> An asset crosses from one chain to another. This asset on the target chain is a **shadow asset** of the original asset.

## Motivation

Force Bridge allows for seamless transactions between Nervos and other public chains. However, some assets are duplicated across these public chains. In order to avoid asset name conflicts, it is important to adopt some naming conventions for the shadow assets on Nervos.

## Naming Convention

A shadow asset must contain the following three types of data: the original asset name, the source chain and the cross-chain bridge.

In this regard, the convention is as follows:

- Use the `<symbol>|<source>|<bridge>(optional)` format to uniformly represent cross-chain assets on Nervos L1/L2, including complete information, readable and easy to parse.
  - `symbol` (the original asset name) : the asset name in its original public chain.
  - `source` (the source chain): the name of the public chain where the assets are originally located.
  - `bridge` (the cross-chain bridge): the bridge used by assets when they cross chains.
- Use `|` instead of `-` as the connector because `-` is already used by the LP symbol.
- If the cross-chain bridge is Force Bridge, `bridge` must be omitted.

[Example](https://explorer.nervos.org/sudt/0x797bfd0b7b883bc9dba43678e285999507c6d0b971a2740c76623f70636f4080)s:

- `USDC|eth` represents the USDC that crosses from Ethereum to Nervos via Force Bridge.
- `USDC|bsc` represents the USDC that crosses from Binance Smart Chain (BSC) to Nervos via Force Bridge.
- `USDC|eth|multichain` represents the USDC that crosses from Ethereum to Nervos via Multichain (Multichain is just an example).

## Specifications for Displays

Applications can use `symbol` directly or parse `symbol` for custom displays. It is up to each application to determine how to display shadow assets.

For the return value of the `name()` method of the Layer1 explorer ([Example](https://explorer.nervos.org/sudt/0x797bfd0b7b883bc9dba43678e285999507c6d0b971a2740c76623f70636f4080)) and the Layer2 ERC20 Proxy contract, the display format can be `Wrapped <symbol> (<bridge> from <source>)`. This display is verbose, but it is user-friendly.

Examples:

- `USDC|eth` : `Wrapped USDC (ForceBridge from Ethereum)` 
- `USDC|bsc|multichain` : `Wrapped USDC (Multichain from BSC)` 

## [Asset List](https://github.com/nervosnetwork/force-bridge/blob/main/configs/all-bridged-tokens.json)

### Ethereum

`<source>` : eth

[Asset List](https://github.com/nervosnetwork/force-bridge/blob/main/configs/all-bridged-tokens.json)

### Binance Smart Chain (BSC)

`<source>` : bsc

[Asset List](https://github.com/nervosnetwork/force-bridge/blob/main/configs/all-bridged-tokens.json)

### Nervos