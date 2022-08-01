---
Number: ""
Category: Standards Track
Status: Proposal
Author: Jan Xie, Jordan Mack, Wenchao Hu
Organization: Nervos Foundation, Cryptape
Created: 2022-04-22
---

# Universal Asset Notation

## Abstract

This document specifies a universal naming method for assets flowing on Nervos Network, including assets on CKB and assets on layer 2 networks such as Godwoken and Axon.

## Motivation

The interoperation between Nervos Network and other crypto or traditional economy networks brings new assets to Nervos Network. The boom of assets create difficulties for developers and users - for example, different assets on different networks may accidentally use the same name, or the same asset may arrive Nervos Network through different cross-chain bridges/routes and eventually appears as different mapping assets. A proper asset notation helps incorporate assets origin from multiple networks into one network without causing any confusion, thus lowers the operational risk and facilitates developer and user experience.

## Definition

The Universal Asset Notation (UAN) consists of asset notation and route notation, which in turn are build upon asset symbol, chain symbol and bridge symbol.

UAN Definition (in [BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form)):

```
<UAN> ::= <asset> | <asset> "|" <route>
<asset> ::= <asset-symbol> "." <chain-symbol>
<route> ::= <path> | <path> "|" <route>
<path> ::= <bridge-symbol> "." <chain-symbol>
<asset-symbol> ::= <upper-char>
<chain-symbol> ::= <lower-char>
<bridge-symbol> ::= <lower-char>
<upper-char> ::= <upper-case> | <digit>
<lower-char> ::= <lower-case> | <digit>
<upper-case> ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z"
<lower-case> ::= "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
```

- Characters `|` and `.` are chosen in order to avoid confliction with `-` widely used in LP token in DeFi applications.
- `<asset>` is the first component of UAN. It is a pair of `<asset-symbol>` and `<chain-symbol>` connected by a dot `.`, e.g. `BTC.ckb` for bitcoin resides on the CKB chain, `CKB.gw` for CKByte resides on the Godwoken chain.
- `<route>` is the route through which the asset come to Nervos Network, it's the second component of UAN. `<route>` is only required when the asset's chain of residence is different from its chain of issuance. `<route>` may consist of one or many `<path>`. If it's a multi-paths route, all paths are connected by `|`.
- `<path>` is a pair of bridge symbol and chain symbol, connected by a single dot `.`.
- `<asset-symbol>` is a upper-case abbreviation of the asset, e.g. `BTC` for bitcoin, `CKB` for CKByte.
- `<chain-symbol>` is a lower-case abbreviation of the source chain where the asset resided before came through the path, e.g. `eth` for the Ethereum chain, `ckb` for the CKB chain. Note the source chain may be different from the issuance chain of the asset.
- `<bridge-symbol>` is a lower-case abbreviation of the bridge through which the asset came, e.g. `fb` for assets moved by Forcebridge.

Examples:

```
// CKByte on the CKB chain
CKB.ckb

// CKByte on the Godwoken chain
CKB.gw

// WBTC crossed from the Ethereum chain to the CKB chain via Forcebridge
WBTC.ckb|fb.eth

// BNB crossed from the BSC chain to the CKB chain via Forcebridge
BNB.ckb|fb.bsc

// ETH crossed from the Ethereum chain to the CKB chain via Anotherbridge
ETH.ckb|ab.eth

// ETH crossed from the Ethereum chain to the Godwoken chain via Force Bridge and Godwoken Bridge
ETH.gw|gb.ckb|fb.eth
```

## Display Name

Applications can display UAN directly on user interface, or parse UAN for more user-friendly displays. It is up to each application to determine how to display UAN.

One way to display UAN is keeping the basic form with some omissions. For example:

- Omit the chain of residence when the context is clear and there's no ambiguity when user interacts with the application, e.g. `CKB` or `WBTC|fb.eth`.
- Omit the intermedia paths to emphasis the chain of origin and reduce interference, e.g. use `ETH|fb.eth` for `ETH` crossed from the Ethereum chain and eventually resides on the Godwoken chain, on the UI of a Godwoken dapp.

Another possible format of UAN display could be:

```
<asset-symbol> " (via " <bridge-name> " from " <chain-symbol-in-upper-case> ")"
```

Where `<bridge-name>` is the full name of the bridge in the rightmost path of route, and `<chain-symbol-in-upper-case>` is the chain symbol of the chain in the rightmost path of route. The chain of residence is omitted in display name because it should be clear in the context of the dapp with which a user interacts. The intermediate paths are omitted to make display name more readable.

Examples:

```
// WBTC crossed from the Ethereum chain to the CKB chain via Forcebridge
// UAN
WBTC.ckb|fb.eth
// Display Name
WBTC (via Forcebridge from ETH)

// BNB crossed from the BSC chain to the CKB chain via Forcebridge
// UAN
BNB.ckb|fb.bsc
// Display Name
BNB (via Forcebridge from BSC)

// ETH crossed from the Ethereum chain to the CKB chain via Anotherbridge
// UAN
ETH.ckb|ab.eth
// Display Name
ETH (via Anotherbridge from ETH)

// ETH crossed from the Ethereum chain to the Godwoken chain via Force Bridge and Godwoken Bridge
// UAN
ETH.gw|gw.ckb|fb.eth
// Display Name
ETH (via Forcebridge from ETH)
```

## References

- UAN is an extension of the convention used in [Forcebridge Asset List](https://github.com/nervosnetwork/force-bridge/blob/fb769301dbc3beddbdeabec23b764305c1b1b937/configs/all-bridged-tokens.json) with modifications.
