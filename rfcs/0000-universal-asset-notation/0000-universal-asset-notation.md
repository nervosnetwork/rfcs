---
Number: ""
Category: Standards Track
Status: Proposal
Author: Jan Xie, Wenchao Hu, Hanlei Liang
Organization: Nervos Foundation, Cryptape
Created: 2022-04-22
---

# Universal Asset Notation

## Abstract

This document specifies a universal naming method for assets flowing on Nervos Network, including assets on CKB and assets on layer 2 networks such as Godwoken and Axon.

## Motivation

The interoperation between Nervos Network and other crypto or traditional economy networks brings new assets to Nervos Network. The boom of assets create difficulties for developers and users - for example, different assets on different networks may accidentally use the same name, or the same asset may arrive Nervos Network through different cross-chain bridges/routes and eventually appears as different mapping assets. A proper asset notation help incorporate assets origin from multiple networks into one network without causing any confusion, thus lowers the operational risk and facilitates deveoper and user experience.

## Definition

The Universal Asset Notation (UAN) consists of three components: Asset Symbol, Source Chain Symbol and Bridge Symbol.

UAN Definition (in [BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form)):

```
<UAN> ::= <asset-symbol> "|" <route>
<asset-symbol> ::= <upper-char>
<route> ::= <path> | <path> "|" <route>
<path> ::= <source-chain-symbol> | <source-chain-symbol> "." <bridge-symbol>
<source-chain-symbol> ::= <lower-char>
<bridge-symbol> ::= <lower-char>
<upper-char> ::= <upper-case> | <digit>
<lower-char> ::= <lower-case> | <digit>
<upper-case> ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z"
<lower-case> ::= "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
<digit> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
```

- Characters `|` and `.` are chosen in order to avoid confliction with `-` widely used in LP token in DeFi applications.
- `<asset-symbol>` is a upper-case abbreviation of the asset, e.g. `BTC` for bitcoin, `CKB` for CKByte.
- `<route>` is the route through which the asset come to Nervos Network, it may consist of one or many `<path>`. If it's a multi-paths route, all paths are connected by `|`.
	- If the path is coming from the CKB chain through Godwoken bridge (`ckb.gw`) it can be omitted.
- `<path>` is a symbol pair of source chain and bridge, connected by a single dot `.`.
	- If the bridge is Forcebridge (`fb`) it can be omitted.
- `<source-chain-symbol>` is a lower-case abbreviation of the source chain where the asset resided before came through the path, e.g. `eth` for the Ethereum chain, `ckb` for the CKB chain. Note the source chain may be different from the issuance chain of the asset.
- `<bridge-symbol>` is a lower-case abbreviation of the bridge through which the asset came, e.g. `fb` for assets moved by Forcebridge.

Examples:

```
// WBTC crossed from the Ethereum chain to the CKB chain via Forcebridge
WBTC|eth
WBTC|eth.fb

// BNB crossed from the BSC chain to the CKB chain via Forcebridge
BNB|bsc
BNB|bsc.fb

// ETH crossed from the Ethereum chain to the CKB chain via Anotherbridge
ETH|eth.ab

// ETH crossed from the Ethereum chain to the Godwoken chain via Forcebridge and Godwoken bridge
ETH|eth
ETH|eth.fb
ETH|ckb.gw|eth.fb
```

## Display Name

Applications can display UAN directly on user interface, or parse UAN for more user-friendly displays. It is up to each application to determine how to display UAN.

Below is a possible format to display UAN on user interface:

```
<asset-symbol> " (" <bridge-name> " from " <source-chain-symbol-in-upper-case> ")"
```

Where `<bridge-name>` is the full name of bridge.

Examples:

```
// WBTC crossed from the Ethereum chain to the CKB chain via Forcebridge
// UAN
WBTC|eth
// Display Name
WBTC (Forcebridge from ETH)

// BNB crossed from the BSC chain to the CKB chain via Forcebridge
// UAN
BNB|bsc
// Display Name
BNB (Forcebridge from BSC)

// ETH crossed from the Ethereum chain to the CKB chain via Anotherbridge
// UAN
ETH|eth.ab
// Display Name
ETH (Anotherbridge from ETH)

// ETH crossed from the Ethereum chain to the Godwoken chain via Forcebridge and Godwoken bridge
// UAN
ETH|eth
// Display Name
ETH (Forcebridge from ETH)
```

## References

- [Forcebridge Asset List](https://github.com/nervosnetwork/force-bridge/blob/main/configs/all-bridged-tokens.json)
