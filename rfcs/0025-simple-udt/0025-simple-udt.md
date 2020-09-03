---
Number: "0025"
Category: Standards Track
Status: Proposal
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2020-09-03
---

# Simple UDT

This RFC defines the Simple User Defined Tokens(Simple UDT or SUDT) specification. Simple UDT provides a way for dapp developers to issue custom tokens on Nervos CKB. The simple part in Simple UDT means we are defining a minimal standard that contains whats absolutely needed, more sophisticated actions are left to CKBs flexibility to achieve.

## Data Structure

### SUDT Cell

A SUDT cell in Simple UDT specification looks like following:

```
data:
    amount: uint128
type:
    code_hash: simple_udt type script
    args: owner lock script hash (...)
lock:
    <user_defined>
```

The following rules should be met in a SUDT Cell:

* **Simple UDT Rule 1**: a SUDT cell must store SUDT amount in the first 16 bytes of cell data segment, the amount should be stored as little endian, 128-bit unsigned integer format. In the case of composable scripts, the SUDT amount must still be located at the initial 16 bytes in the data segment which corresponds to the composed SUDT script
* **Simple UDT Rule 2**: the first 32 bytes of the SUDT cells type script args must store the lock script hash of *owner lock*. Owner lock will be explained below
* **Simple UDT Rule 3**: each SUDT must have unique type script, in other words, 2 SUDT cells using the same type script are considered to be the same SUDT.

User shall use any lock script as they wish in the SUDT Cell.

### Owner lock script

Owner lock shall be used for governance purposes, such as issurance, mint, burn as well as other operations. The SUDT specification does not enforce specific rules on the behavior of owner lock script. It is expected that owner lock script should at least provide enough security to ensure only token owners can perform governance operations.

## Operations

This section describes operations that must be supported in Simple UDT implementation

### Transfer

Transfer operation transfers SUDTs from one or more SUDT holders to other SUDT holders.

```
// Transfer
Inputs:
    <vec> SUDT_Cell
        Data:
            amount: uint128
        Type:
            code_hash: simple_udt type script
            args: owner lock script hash (...)
        Lock:
            <user defined>
    <...>
Outputs:
    <vec> SUDT_Cell
        Data:
            amount: uint128
        Type:
            code_hash: simple_udt type script
            args: owner lock script hash (...)
        Lock:
            <user defined>
    <...>
```

Transfer operation must satisfy the following rule:

* **Simple UDT Rule 4**: in a transfer transaction, the sum of all SUDT tokens from all input cells must be larger or equal to the sum of all SUDT tokens from all output cells. Allowing more input SUDTs than output SUDTs enables burning tokens.

## Governance Operations

This section describes governance operations that should be supported by Simple UDT Implementation. All goverance operations must satisfy the following rule:

* **Simple UDT Rule 5**: in a governance operation, at least one input cell in the transaction should use owner lock specified by the SUDT as its cell lock.

### Issue/Mint SUDT

This operation enables issuing new SUDTs.

```
// Issue new SUDT
Inputs:
    <... one of the input cell must have owner lock script as lock>
Outputs:
    SUDT_Cell:
        Data:
            amount: uint128
        Type:
            code_hash: simple_udt type script
            args: owner lock script hash (...)
        Lock:
            <user defined>
```

## Notes

An implementation of the Simple UDT spec above has been deployed to Lina CKB mainnet at [here](https://explorer.nervos.org/transaction/0xc7813f6a415144643970c2e88e0bb6ca6a8edc5dd7c1022746f628284a9936d5).

Reproducible build is supported to verify the deploy script. To bulid the deployed Simple UDT script above, one can use the following steps:

```bash
$ git clone https://github.com/nervosnetwork/ckb-miscellaneous-scripts
$ cd ckb-miscellaneous-scripts
$ git checkout 175b8b0933340f9a7b41d34106869473d575b17a
$ git submodule update --init
$ make all-via-docker
```

Now you can compare the simple udt script generated at `build/simple_udt` with the one deployed to CKB, they should be identical.

A draft of this specification has already been released, reviewed, and discussed in the community at [here](https://talk.nervos.org/t/rfc-simple-udt-draft-spec/4333) for quite some time.
