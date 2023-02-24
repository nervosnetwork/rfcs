---
Number: "0039"
Category: Standards Track
Status: Proposal
Author: Dylan Duan <duanyytop@gmail.com>
Created: 2022-01-27
---

# Cheque Lock

## Abstract

This RFC describes a lock script that can be used to transfer assets, such as SUDT ([Simple UDT](../0025-simple-udt/0025-simple-udt.md)) and mNFT ([Multi-purpose NFT](https://talk.nervos.org/t/rfc-multi-purpose-nft-draft-spec/5434)), from one user to another user that does not have an ACP ([Anyone-Can-Pay](../0026-anyone-can-pay/0026-anyone-can-pay.md)) cell available, and without the sender having to provide CKBytes to create the destination cell for the receiver. 

## Summary

The most basic method of transferring an asset from one user to another is to have the sender provide the CKBytes to create a destination cell for the receiver that holds the asset. However, when using this method the required CKBytes must be sent with the asset, and this can become a significant additional cost to the sender.

When ACP is used to transfer an asset, the sender no longer has to provide CKBytes for the receiver. However, the receiver must first create an ACP cell to hold the asset that will be sent to them in the future. This requires that the receiver knows in advance what is being sent. There is no automatic method to do this, which makes it a significant UX burden.

The Cheque Lock attempts to solve this problem by allowing the sender to lock an asset they want to transfer into a Cheque cell (a cell uses the Cheque Lock) with the receiver's address indicated. Only the receiver can claim the asset, and to do so they must provide the CKBytes required to create a destination cell that they own to move the asset into.

The sender must provide the CKBytes to create the Cheque cell that holds the asset while waiting to be claimed by the receiver. When the receiver claims their asset, the CKBytes from the Cheque cell are returned to the sender. This process allows a sender to transfer an asset without sending CKBytes, and without requiring the receiver to first create an ACP cell to receive the asset. 

When the asset is put into the Cheque cell, it is locked for a period of 6 epochs which is approximately 24 hours. During this period, the receiver can freely claim at their convenience. If the asset is not claimed after 6 epochs have passed, the sender has the option to cancel the process and withdraw the asset.

## Specification

The Cheque Lock is designed to work with the [secp256k1-blake2b-sighash-all](https://github.com/nervosnetwork/ckb-system-scripts/wiki/How-to-sign-transaction#p2pkh) lock, also known as the default lock. This is the only fully supported lock that is used for both the sender and receiver. Attempting to use other locks with the Cheque Lock is not recommended.

The Cheque Lock will work with many types of custom assets, but those which require non-standard functionality may not be compatible. The Cheque Lock should only be used with asset types that are known to be compatible to reduce the risk of lost assets or funds. We will use SUDT tokens for all examples below since they are known to be fully compatible.

### Cheque Lock Script Structure

A Cheque cell is a cell that uses the Cheque Lock as the lock script and has a structure that is similar to the following:

```
lock:
    code_hash: <cheque_lock_script>
    args: <20-byte_receiver_lock_hash> <20-byte_sender_lock_hash>
type:
    <simple_udt_type_script>
data:
    <sudt_amount: uint128>
```

The `20-byte_receiver_lock_hash` and the `20-byte_sender_lock_hash` are `Blake2b160` hashes of lock scripts which rely on the default lock ([secp256k1-blake2b-sighash-all](https://github.com/nervosnetwork/ckb-system-scripts/wiki/How-to-sign-transaction#p2pkh)). Specifying the sender lock hash and receiver lock hash in the lock args defines who can access the assets that are locked in the Cheque cell.

A `Blake2b160` hash is calculated as follows. First, a fully populated lock script structure for the sender or receiver must be converted to its binary representation. Next, a `Blake2b256` hash of the binary representation is generated, which results in a 32-byte (256-bit) hash. Finally, this hash is truncated to the first 20 bytes, which is 160 bits.

The sender initiates the process by creating a Cheque Lock cell that contains the asset they wish to deposit. At this time they specify both the sender and receiver lock hashes as lock args on the Cheque cell. To create the Cheque cell, the sender must also provide the CKBytes necessary for the cell. The amount required depends on the requirements of the asset being transferred.

The receiver can claim the asset at any time after the Cheque cell has been created, as long as the asset has not been withdrawn by the sender. After the Cheque cell has been created, the sender cannot withdraw for a period of 6 epochs. This gives a guaranteed window of approximately 24 hours where only the receiver can claim the asset. If the receiver does not claim the asset within 6 epochs, then the sender has the option to cancel the process and withdraw the asset and CKBytes that they provided.

## Unlock Rules

The Cheque Lock follows the rules below when validating a transaction.

1. If a signature is provided in the witness:

    - 1.a. Check the signature against the sender lock hash and receiver lock hash. If the signature does not match either, then return with an error.

    - 1.b. If the provided signature is valid and matches the `20-byte_receiver_lock_hash`:

        - 1.b.i. Loop through all the input cells using the current Cheque Lock script). If any of these inputs has a [since](../0017-tx-valid-since/0017-tx-valid-since.md) value that is not zero, return with an error. This ensures that the receiver is always able to claim immediately without a time delay restriction.

        - 1.b.ii. Loop through all the output cells with the sender's lock hash. If the sum of the capacity in these cells is not equal to the sum of the capacity in the input Cheque cells, return with an error. This ensures that the CKBytes provided by the sender for the Cheque cell are always returned to the sender when the asset is claimed.

    - 1.c. If the provided signature is valid and matches the `20-byte_sender_lock_hash`:

        - 1.c.i. Loop through all the input cells using the current Cheque Lock script. If any of these inputs has a [since](../0017-tx-valid-since/0017-tx-valid-since.md) value that is not set to `0xA000000000000006`, return with an error. A `since` value of `0xA000000000000006` indicates that the cell cannot be committed in a transaction until a minimum of 6 epochs have passed since the Cheque cell was created. This ensures a window of approximately 24 hours where only the receiver can claim the asset.

2. If a signature is not provided in the witness:

   - 2.a. Loop through all the input cells checking their lock script hash against the `20-byte_receiver_lock_hash` and `20-byte_sender_lock_hash`. If no matches are found, return with an error.

   - 2.b. If an input cell is found that matches the `20-byte_receiver_lock_hash`:

     - 2.b.i. Perform the same checks as in rules 1.b.i and 1.b.ii.

     - 2.b.ii. Loop through all the input cells and locate the first input cell with a lock script hash that matches the `20-byte_receiver_lock_hash`, and note the index of the matched cell. Then locate the corresponding witness at the same index that was noted. If the witness at this index is empty, is not a [WitnessArgs](https://github.com/nervosnetwork/ckb/blob/a6733e6af5bb0da7e34fb99ddf98b03054fa9d4a/util/types/schemas/blockchain.mol#L104-L108) structure, or the WitnessArgs structure has an empty lock property, return with an error. This helps ensure proper lock usage and transaction structure.

   - 2.c. If an input cell is found that matches the `20-byte_sender_lock_hash`:

     - 2.c.i. Perform the same checks as in rules 1.c.i.

> Note: The Cheque Lock allows for batching, meaning that a single transaction can contain multiple Cheque cells for different claims and withdrawals which will all be processed at the same time. When two or more Cheque cells have identical scripts (the exact same code_hash, hash_type, and args), they will execute in the same lock script and process together in a single script execution group. If there is any difference in the scripts, such as the same code_hash, hash_type, but a different sender or receiver is provided in the args, then they will execute in separate script execution groups. 

## Examples

Below are example transactions for several operations of the Cheque Lock.

In these examples, a 0.01 CKByte transaction fee is used for simplicity. In a production environment, transaction fees should be [calculated](https://docs.nervos.org/docs/essays/faq/#how-do-you-calculate-transaction-fee) based on factors including transaction size, running cycles as well as network status.

### Create a Cheque Cell

```
inputs:
    sudt_cell:
        capacity: 1000 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 1000 UDT

outputs:
    cheque_cell:
        capacity: 165 CKBytes
        lock:
            code_hash: <cheque_lock_script>
            args:  <20-byte_receiver_lock_hash> <20-byte_sender_lock_hash>
        type: <sudt_type_script>
        data:
            sudt_amount: 100 UDT
    sudt_cell:
        capacity: 834.99 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 900 UDT

witnesses:
    <valid_signature_for_sender_secp256k1_blake2b_lock_script>
```

This transaction creates a Cheque cell, locking 100 UDT tokens that can be claimed by the receiver.

The `20-byte_sender_lock_hash` is a match to `sender_secp256k1_blake2b_lock_script`. This will allow the sender to withdraw the asset from the Cheque cell after 6 epochs if the receiver does not claim the asset.

### Claim

#### 1. Claim via Receiver Signature

```
inputs:
    cheque_cell:
        capacity: 165 CKBytes
        lock:
            code_hash: <cheque_lock_script>
            args: <20-byte_receiver_lock_hash> <20-byte_sender_lock_hash>
        type: <sudt_type_script>
        data:
            sudt_amount: 100 UDT
    sudt_cell:
        capacity: 200 CKBytes
        lock: <another_receiver_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 200 UDT

outputs:
    sudt_cell:
        capacity: 199.99 CKBytes
        lock: <another_receiver_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 300 UDT
    basic_cell:
        capacity: 165 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>

witnesses:
    <valid_signature_for_receiver_secp256k1_blake2b_lock_script>
    <valid_signature_for_another_receiver_lock_script>

```

This transaction claims the 100 UDT tokens in the Cheque cell using the receiver's signature, and sends them to a different address.

The receiver provides his signature (`witnesses[0]`) to unlock the Cheque cell (`inputs[0]`). The signature in witnesses[0] is a valid match to the `20-byte_receiver_lock_hash`. The receiver also provides an SUDT cell (`inputs[1]`) that contains the same SUDT tokens in the Cheque cell (`inputs[0]`), and extra capacity which will be used to cover the transaction fee. The SUDT cell uses a different lock script, `another_receiver_lock_script`, which means it must be unlocked using a different signature (`witnesses[1]`). The output SUDT cell (`outputs[0]`) receives the SUDT tokens from the Cheque cell (`inputs[0]`), and pays the 0.01 CKByte transaction fee. The 165 CKBytes of capacity from the Cheque cell (`inputs[0]`) are returned to the sender in a basic cell (`output[1]`).

#### 2. Claim via Receiver Lock Script

```
inputs:
    cheque_cell:
        capacity: 165 CKBytes
        lock:
            code_hash: <cheque_lock_script>
            args: <20-byte_receiver_lock_hash> <20-byte_sender_lock_hash>
        type: <sudt_type_script>
        data:
            sudt_amount: 100 UDT
    sudt_cell:
        capacity: 200 CKBytes
        lock: <receiver_secp256k1_blake2b_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 200 UDT

outputs:
    sudt_cell:
        capacity: 199.99 CKBytes
        lock: <receiver_secp256k1_blake2b_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 300 UDT
    basic_cell:
        capacity: 165 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>

witnesses:
    <0x>
    <valid_signature_for_receiver_secp256k1_blake2b_lock_script>

```

This transaction claims the 100 UDT tokens in the Cheque cell (`inputs[0]`) in a very similar way to the previous example, except that the receiver's lock script is used to unlock the Cheque cell instead of a separate signature.

When using the receiver's lock script to claim, no signature needs to be provided for the Cheque cell. Notice that `witnesses[0]` is empty because the Cheque cell (`inputs[0]`) does not require it. The input SUDT cell (`inputs[1]`) has a lock script `receiver_secp256k1_blake2b_lock_script` that matches the Cheque cell receiver lock hash `20-byte_receiver_lock_hash`. The signature in `witnesses[1]` is valid and unlocks the SUDT cell (`inputs[1]`). The Cheque cell receiver `20-byte_receiver_lock_hash` matches the lock on the SUDT cell `receiver_secp256k1_blake2b_lock_script`. The Cheque cell (`inputs[0]`) will unlock without a signature because the receiver's lock script is present in another input cell (`inputs[1]`), and it is unlocked with a signature provided in `witnesses[1]`.

### Withdraw

#### 1. Withdraw via Sender Signature

```
inputs:
    cheque_cell:
        capacity: 165 CKBytes
        lock:
            code_hash: <cheque_lock_script>
            args: <20-byte_receiver_lock_hash> <20-byte_sender_lock_hash>
        type: <sudt_type_script>
        data:
            sudt_amount: 100 UDT
        since: 0xA000000000000006

outputs:
    sudt_cell:
        capacity: 164.99 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 100 UDT

witnesses:
    <valid_signature_for_sender_secp256k1_blake2b_lock_script>
```

This transaction withdrawals 100 UDT tokens from the Cheque cell (`inputs[0]`) using the sender's signature, and returns the tokens and CKBytes to the sender.

The signature in `witnesses[0]` is a valid match for the lock script indicated by `20-byte_sender_lock_hash` in the Cheque cell (`inputs[0]`). This authorizes a withdrawal by the sender if 6 epochs have passed and the receiver has not claimed the asset. Notice that a since value of `0xA000000000000006` is present on the Cheque cell. This prevents the transaction from being committed until 6 epochs after the Cheque cell was created.

The Cheque cell (`inputs[0]`) has 165 CKBytes of capacity, which is enough for the output cell plus some extra capacity that is used to pay the 0.01 CKByte transaction fee. For that reason, no extra capacity needs to be provided by the sender to complete this transaction. The 100 UDT tokens and remaining CKBytes are returned to the sender in `outputs[0]`.

#### 2. Withdraw via Sender Lock Script

```
inputs:
    cheque_cell:
        capacity: 165 CKBytes
        lock:
            code_hash: <cheque_lock_script>
            args: <20-byte_receiver_lock_hash> <20-byte_sender_lock_hash>
        type: <sudt_type_script>
        data:
            sudt_amount: 100 UDT
        since: 0xA000000000000006
    basic_cell:
        capacity: 200 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>

outputs:
    sudt_cell:
        capacity: 165 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>
        type: <sudt_type_script>
        data:
            sudt_amount: 100 UDT
    basic_cell:
        capacity: 199.99 CKBytes
        lock: <sender_secp256k1_blake2b_lock_script>

witnesses:
    <0x>
    <valid_signature_for_sender_secp256k1_blake2b_lock_script>
```

This transaction withdraws the 100 UDT tokens in the Cheque cell (`inputs[0]`) in a very similar way to the previous example, except that the sender's lock script is used to unlock the Cheque cell instead of a separate signature.

When using the sender's lock script to claim, no signature needs to be provided for the Cheque cell. Notice that `witnesses[0]` is empty because the Cheque cell (`inputs[0]`) does not require it. The input basic cell (`inputs[1]`) has a lock script `sender_secp256k1_blake2b_lock_script` that matches the Cheque cell sender lock hash `20-byte_sender_lock_hash`. The signature in `witnesses[1]` is valid and unlocks the basic cell (`inputs[1]`). The Cheque cell sender `20-byte_sender_lock_hash` matches the lock on the SUDT cell `sender_secp256k1_blake2b_lock_script`. The Cheque cell (`inputs[0]`) will unlock without a signature because the sender's lock script is present in another input cell (`inputs[1]`), and it is unlocked with a signature provided in `witnesses[1]`.

Notice that a since value of `0xA000000000000006` is present on the Cheque cell. This prevents the transaction from being committed until 6 epochs after the Cheque cell was created.

## Deployments

The Cheque Lock script executable has been deployed to the Nervos CKB L1 Mainnet and Testnet and can be accessed using the parameters provided below.

### Lina / Mirana (Mainnet)

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0xe4d4ecc6e5f9a059bf2f7a82cca292083aebc0c421566a52484fe2ec51a9fb0c` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x04632cc459459cf5c9d384b43dee3e36f542a464bdd4127be7d6618ac6f8d268` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

> Note: A `dep_type` of `dep_group` means that the contents of this dep cell contains references to multiple cell deps. These are `secp256k1_data` and `cheque_lock`, both of which have a `dep_type` of `code`.

The `out_point` of `secp256k1_data` is:

```
{
  tx_hash: 0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c,
  index: 0x3
}
```

The `out_point` of `cheque_lock` is:

```
{
  tx_hash: 0x0a34aeea122d9795e06e185746a92e88bca0ad41b0e5842a960e5fd1d43760a6,
  index: 0x0
}
```

### Aggron / Pudge (Testnet)

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x60d5f39efce409c587cb9ea359cefdead650ca128f0bd9cb3855348f98c70d5b` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x7f96858be0a9d584b4a9ea190e0420835156a6010a5fde15ffcdc9d9c721ccab` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

> Note: A `dep_type` of `dep_group` means that the contents of this dep cell contains references to multiple cell deps. These are `secp256k1_data` and `cheque_lock`, both of which have a `dep_type` of `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f,
  index: 0x3
}
```

The `out_point` of `cheque_lock` is:

```
{
  tx_hash: 0x1b16769dc508c8349803fe65558f49aa8cf04ca495fbead42513e69e46608b6c,
  index: 0x0
}
```

## Reproducible Build

A reproducible build can be used to verify that the deployed scripts are consistent with the source code. Please refer to the [CI configure file](https://github.com/nervosnetwork/ckb-Cheque-script/blob/main/.github/workflows/build_and_test.yml) for the exact software versions and steps needed to build the binaries used for verification purposes.

<!--

To build the deployed Cheque Lock script, one can use the following steps:

```bash
$ git clone https://github.com/nervosnetwork/ckb-Cheque-script
$ cd ckb-Cheque-script
$ git checkout 4ca3e62ae39c32cfcc061905515a2856cad03fd8
$ git submodule update --init
$ cd contracts/ckb-Cheque-script/ckb-lib-secp256k1/ckb-production-scripts
$ git submodule update --init
$ cd .. && make all-via-docker
$ cd ../../.. && capsule build --release
```

-->

## Discussion

A draft of this specification was previously released, reviewed, and discussed in the community on the [Nervos Talk forums](https://talk.nervos.org/t/sudt-Cheque-deposit-design-and-implementation/5209).

## References

[1] SUDT Cheque Deposit Design and Implementation, https://talk.nervos.org/t/sudt-Cheque-deposit-design-and-implementation/5209

[2] Cheque Script Source Code, https://github.com/nervosnetwork/ckb-Cheque-script/tree/4ca3e62ae39c32cfcc061905515a2856cad03fd8
