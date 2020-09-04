---
Number: "0026"
Category: Standards Track
Status: Proposal
Author: Xuejie Xiao
Organization: Nervos Foundation
Created: 2020-09-03
---

# Anyone-Can-Pay Lock

This RFC describes a new lock script for CKB that can accept any amount of [Simple UDT](../0025-simple-udt/0025-simple-udt.md) or CKB payment. Previously, one can only transfer to another user at least 61 CKBytes when using the default lock, possibly more when using other lock scripts or type scripts. This is becoming a bigger problem when UDT support lands in CKB: a naive UDT transfer operation will not only require UDTs, but CKByte to keep the UDTs in a cell as well.

Here we try to solve the problem by introducing a new anyone-can-pay lock script, which can be unlocked not only by the validation of a signature, but also by accepting any amount of payment. This way, a user should be able to send any amount of CKBytes or UDTs to a cell using anyone-can-pay lock instead of always creating a new cell. It thus provides a solution to both problems above.

## Script Structure

The anyone-can-pay lock is built upon the default secp256k1-blake2b-sighash-all lock with additions to the script args part. The new anyone-can-pay lock can accept any of the following script args format:

```
<20 byte blake160 public key hash>
<20 byte blake160 public key hash> + <1 byte CKByte minimum>
<20 byte blake160 public key hash> + <1 byte CKByte minimum> + <1 byte UDT minimum>
```

The additions of CKByte & UDT minimums enforce the minimal amount that one can transfer to the anyone-can-pay lock. This provides a mitigation against DDoSing on the cell level: if a cell is setup using the anyone-can-pay lock, an attacker can keep creating transactions that transfer only 1 shannon or 1 UDT to the cell, making it difficult for the cell owner to claim the tokens stored in the cell. By providing a minimal transfer amount, a user can raise the attacking cost, hence protecting his/her own cells against DDoS attacks. This mechanism won't prevent all kinds of DDoS of course, but it serves as a quick solution to mitigate cheaper ones.

The value stored in CKByte & UDT minimum are interpreted in the following way: if `x` is stored in the field, the minimal transfer amount will be `10^x`, for example:

* If 3 is stored in CKByte minimum, it means the minimal amount that can be accepted by the cell is 1000 shannons
* If 4 is stored in UDT base unit minimum, it means the minimal amount that can be accepted by the cell is 10000 UDT base units.

Note the minimum fields are completely optional. If a minimum is not provided, we will treat the minimum value as 0, meaning no minimum is enforced on the transfer operation. It is worth mentioning that different minimums also lead to different lock scripts used by the cell.

## UDT Interpretation

The anyone-can-pay lock assumes that the locked cell follows the [Simple UDT specification](https://talk.nervos.org/t/rfc-simple-udt-draft-spec/4333), thus the cell 1) has a type script; 2) has at least 16 bytes in the cell data part. Its up to the user to ensure one only uses anyone-can-pay lock with a type script implementing Simple UDT specification.

## Unlock Rules

The anyone-can-pay lock will work following the rules below:

1. If a signature is provided, it works exactly as the default secp256k1-blake2b-sighash-all lock, if a signature is provide in witness and can be validated, the lock returns with a success state.

    1.a. If the provided signature fails validation, the lock returns with an error state

2. If a signature is not provided, the lock continues with the added anyone-can-pay logic below:

    2.a. It loops through all input cells using the current anyone-can-pay lock script(notice here the lock script we refer to include public key hash, meaning if a transaction contains 2 cells using the same anyone-can-pay lock code, but different public key hash, they will be treated as different lock script, and each will perform the script unlock rule checking independently), if 2 input cells are using the same type script, or are both missing type scripts, the lock returns with an error state

    2.b. It loops through all output cells using the current anyone-can-pay lock script, if 2 output cells are using the same type script, or are both missing type scripts, the lock returns with an error state

    2.c. It loops through all input cells and output cells using the current anyone-can-pay lock script, if there is a cell that is missing type script, but has cell data set, it returns with an error state.

    2.d. It loops through all input cells and output cells using the current anyone-can-pay lock script, if there is a cell that has type script, but a cell data part with less than 16 bytes of data, it returns with an error state.

    2.e. It then pairs input cells and output cells with matching type scripts(input cell without type script will match with output cell without type script). If there is an input cell without matching output cell, or if there is an output cell without matching input cell, it returns with an error state.

    2.f. It loops through all pairs of input & output cells, if there is a pair in which the input cell has more CKBytes than the output cell; or if the pair of cells both have type script and cell data part, but the input cell has more UDT than the output cell, it returns with an error state.

    2.g. If CKByte minimum or UDT minimum is set, it loops through all pairs of input & output cells. If it could not find a pair of input & output cells in which the output amount is equal to or more than the input amount plus the set minimum, it returns with an error state. Note only one minimum needs to be matched if both CKByte minimum and UDT minimum are set.

The reason of limiting one input cell and one output cell for each lock/type script combination, is that the lock script should prevent attackers from merging or splitting cells:

* Allowing merging anyone-can-pay cells can result in less cells being available, resulting in usability problems. For example, an exchange might create hundreds of anyone-can-pay cells to perform sharding so deposit transactions are less likely to conflict with each other.
* Allowing splitting anyone-can-pay cells has 2 problems: 1) it increases CKByte usage on chain, putting unwanted pressure on miners; 2) it might result in fee increase when later the owner wants to claim tokens in anyone-can-pay cells, since more input cells than expect would result in both transaction size increase, and validation cycle increase

Giving those considerations, anyone-can-pay lock script here forbids merging or splitting anyone-can-pay cells from non-owners, as allowing more than one input/output anyone-can-pay cell in each lock/type combination would only complicate lock validation rules without significant gains.

## Examples

Here we describe useful transaction examples involving anyone-can-pay lock.

### Create an Anyone-can-pay Cell

```
Inputs:
    Normal Cell:
        Capacity: 1000 CKBytes
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash A>
Outputs:
    Anyone-can-pay Cell:
        Capacity: 999.99 CKBytes
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash B> <CKByte minimum: 9> <UDT minimum: 5>
        Data:
            Amount: 0 UDT
Witnesses:
    <valid signature for public key hash A>
```

Note here we assume 0.01 CKByte is paid as the transaction fee, in production one should calculate the fee based on factors including transaction size, running cycles as well as network status. 0.01 CKByte will be used in all examples as fees for simplicity. The new anyone-can-pay cell created by this transaction impose a minimum transfer value of 10^9 shannons (10 CKBytes) and 10^5 UDT base units respectively.

### Unlock via Signature

```
Inputs:
    Anyone-can-pay Cell:
        Capacity: 1000 CKBytes
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash A> <CKB minimum: 2>
Outputs:
    Normal Cell:
        Capacity: 999.99 CKBytes
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash B>
Witnesses:
    <valid signature for public key hash A>
```

When a signature is provided, the cell can be unlocked in anyway the owner wants, anyone-can-pay lock here just behaves as a normal cell. In this example an anyone-can-pay cell is converted back to a normal cell.

### Unlock via CKB Payment on Cells with No Type Script

```
Inputs:
    Deposit Normal Cell:
        Capacity: 500 CKBytes
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash B>
    Anyone-can-pay Cell:
        Capacity: 1000 CKBytes
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash A> <CKBytes minimum: 2>
Outputs:
    Deposit Change Cell:
        Capacity: 479.99 CKBytes
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash B>
    Anyone-can-pay Cell:
        Capacity: 1020 CKBytes
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash A>
Witnesses:
    <valid signature for public key hash B>
```

Here the transaction doesnt contain signature for the anyone-can-pay cell, yet the anyone-can-pay lock succeeds the validation when it detects that someone deposits 20 CKBytes into itself. Note this use case does not involve in UDT at all, anyone-can-pay lock is used to overcome the 61 CKBytes requirement of plain transfer.

### Unlock via UDT Payment

```
Inputs:
    Deposit Normal Cell:
        Capacity: 500 CKBytes
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash B>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 200000 UDT
    Anyone-can-pay Cell:
        Capacity: 1000 CKBytes
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash A>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 3000 UDT
Outputs:
    Deposit Change Cell:
        Capacity: 499.99 CKB
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash B>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 199999 UDT
    Anyone-can-pay Cell:
        Capacity: 1000 CKBytes
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash A>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 3001 UDT
Witnesses:
    <valid signature for public key hash B>
```

Here we are depositing 1 UDT to the anyone-can-pay cell. Because theres no extra arguments in the anyone-can-pay lock script except a public key hash, the cell enforces no minimum on the CKByte or UDT one can transfer, a transfer of 1 UDT will be accepted here.

### Unlock via CKByte Payment With Minimums

```
Inputs:
    Deposit Normal Cell:
        Capacity: 500 CKBytes
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash B>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 200000 UDT
    Anyone-can-pay Cell:
        Capacity: 1000 CKBytes
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash A> <CKBytes minimum: 9> <UDT minimum: 5>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 3000 UDT
Outputs:
    Deposit Change Cell:
        Capacity: 489.99 CKBytes
        Lock:
            code_hash: secp256k1_blake2b lock
            args: <public key hash B>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 200000 UDT
    Anyone-can-pay Cell:
        Capacity: 1010 CKBytes
        Lock:
            code_hash: anyone-can-pay lock
            args: <public key hash A>
        Type:
            code_hash: simple udt lock
            args: <owner lock C>
        Data:
            Amount: 3000 UDT
Witnesses:
    <valid signature for public key hash B>
```

Here CKByte minimum is set to 9, which means in each transaction, one must at least transfers `10^9` shannons, or 10 CKBytes into the anyone-can-pay cell. Note that even though UDT minimum is set to 5, meaning one should at least transfer 100000 UDT base units to the anyone-can-pay cell, satisfying the CKByte minimal transfer minimum alone already satisfy the validation rules, allowing CKB to accept the transaction. Likewise, a different transaction might only send 100000 UDT base units to the anyone-can-pay cell without sending any CKBytes, this will also satisfy the validation rules of anyone-can-pay cell here.

## Notes

An implementation of the anyone-can-pay lock spec above has been deployed to Lina CKB mainnet at [here](https://explorer.nervos.org/transaction/0xd032647ee7b5e7e28e73688d80ffc5fba306ee216ca43be4a762ec7e989a3daa). A cell in the dep group format containing both the anyone-can-pay lock, and the required secp256k1 data cell, is also deployed at [here](https://explorer.nervos.org/transaction/0xa05f28c9b867f8c5682039c10d8e864cf661685252aa74a008d255c33813bb81).

Reproducible build is supported to verify the deploy script. To bulid the deployed anyone-can-pay lock script above, one can use the following steps:

```bash
$ git clone https://github.com/nervosnetwork/ckb-anyone-can-pay
$ cd ckb-anyone-can-pay
$ git checkout deac6801a95596d74e2da8f2f1a6727309d36100
$ git submodule update --init
$ make all-via-docker
```

Now you can compare the simple udt script generated at `spec/cells/anyone_can_pay` with the one deployed to CKB, they should be identical.

A draft of this specification has already been released, reviewed, and discussed in the community at [here](https://talk.nervos.org/t/rfc-anyone-can-pay-lock/4438) for quite some time.
