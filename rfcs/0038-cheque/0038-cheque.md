---
Number: "0038"
Category: Standards Track
Status: Proposal
Author: Dylan Duan
Organization: Nervina Labs
Created: 2022-01-27
---

# Cheque Lock

This RFC describes a new lock script for CKB that can send SUDT([Simple UDT](../0025-simple-udt/0025-simple-udt.md)) to anyone that does not have an ACP([any-one-pay](../0026-anyone-can-pay/0025-anyone-can-pay.md)) cell for the SUDT. Previously, the receiver needs to create an ACP cell for the SUDT, and the receiver cannot actually know in advance that someone is going to send a new SUDT to him/her, for now the receiver can only be notified via an off-chain notification that an ACP cell is needed. Or the sender needs to give the receiver an ACP cell of the SUDT when sending the SUDT. These two ways will cause a problem that the receiver cannot receive the SUDT conveniently or the sender needs to pay additional costs.

Here we try to solve the problem by introducing a new cheque lock script, which can be claimed not only by the receiver who does not have an ACP cell to receive the SUDT, but also withdrawing by the sender after lock-up period(6 epochs). When the sender wants to send the SUDT to a receiver who does not have an ACP cell for the SUDT, he/she can transfer the SUDT to a cheque cell and then wait for the receiver to claim it. The receiver can get the cheque cell information from the chain and then decide whether to create a cell to receive the SUDT so that the receiver can receive the SUDT without creating an ACP cell in advance and the sender doesn’t need to pay the additional costs.

### Cheque Script Structure

A cheque cell looks like following:

```
data:
    amount: uint128
type:
    <simple_udt_type_script>
lock:
    code_hash: cheque lock script
    args: <20 byte receiver secp256k1-blake2b-sighash-all lock hash> <20 byte sender secp256k1-blake2b-sighash-all lock hash>
```

When the sender wants to transfer the SUDT to another, he/she needs to create a cheque cell whose lock args includes the receiver’s and sender’s secp256k1-blake2b-sighash-all lock hash. The receiver can unlock the related cheque cell to get the SUDT and give back the CKB to the sender.

When the cheque cell exceeds the lock-up period(6 epochs), the sender can withdraw his/her assets.

## Unlock Rules

The cheque lock follows the rules below:

1. If a signature is provided in witness, the lock continues with the cheque logic below:

   - 1.a. If the provided signature in witness fails validation with the receiver or the sender secp256k1 public key hash, the cheque lock returns withe an error state.

   - 1.b. If the provided signature in witness can be validated with the receiver secp256k1 public key hash, the cheque lock continues with the claim logic below:

     - 1.b.i. It loops through all input cells using the current cheque lock script(notice here the lock script we refer to include public key hash, meaning if a transaction contains 2 cells using the same cheque lock code, but different public key hash, they will be treated as different lock script, and each will perform the script unlock rule checking independently), if the since of 2 inputs are not zero, the cheque lock returns with an error state

     - 1.b.ii. It loops through all output cells using the receiver lock hash, if the sum of the output cells capacity is not equal to the sum of the cheque input cells capacity, the cheque lock returns with an error state

   - 1.c. If the provided signature in witness can be validated with the sender secp256k1 public key hash, the cheque lock continues with the withdraw logic below:

     - 1.c.i. It loops through all input cells using the current cheque lock script, if the any since of the cheque input cells is not same as `0xA000000000000006` which means the tx failed verification unless it is 6 epochs later since the input cells get confirmed on-chain, the cheque lock returns with an error state

2. If a signature is not provided in witness, the lock continues with the cheque logic below:

   - 2.a. It loops through all input cells using the receiver and the sender lock hash, if no matching input cells are found, the cheque lock returns with an error state

   - 2.b. If the matching input cells with the receiver lock hash are found, it does the same work as the 1.b.i and 1.b.ii and returns the same error state

     - 2.b.iii. It loops through all input cells using the receiver lock hash, if the matching inputs are not found or the first related witness is empty(the witness is not WitnessArgs or the lock of WitnessArgs is empty), the cheque lock returns with an error state

   - 2.c. If the matching input cells with the sender lock hash are found, it does the same work as the 1.c.i and returns the same error state

## Examples

Here we describe useful transaction examples involving cheque lock.

### Create a cheque Cell

```
Inputs:
    SUDT Cell:
        Capacity: 1000 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 1000 UDT

Outputs:
    Cheque Cell:
        Capacity: 165 CKBytes
        Lock:
            code_hash: cheque lock
            args:  <receiver_secp256k1_blake2b_lock_hash[0..20]> <sender_secp256k1_blake2b_lock_hash[0..20]>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 100 UDT
    SUDT Cell:
        Capacity: 834.99 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 900 UDT

Witnesses
    <valid signature for sender public key hash>
```

Note here we assume 0.01 CKByte is paid as the transaction fee, in production one should calculate the fee based on factors including transaction size, running cycles as well as network status. 0.01 CKByte will be used in all examples as fees for simplicity.

### Claim

#### 1. Claim via receiver signature

```
Inputs:
    Cheque Cell:
        Capacity: 165 CKBytes
        Lock:
            code_hash: cheque lock
            args: <receiver_secp256k1_blake2b_lock_hash[0..20]> <sender_secp256k1_blake2b_lock_hash[0..20]>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 100 UDT
    SUDT Cell:
        Capacity: 200 CKBytes
        Lock: <another_receiver_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 200 UDT

 Outputs :
    SUDT Cell :
        Capacity: 199.99 CKBytes
        Lock: <another_receiver_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 300 UDT
    Normal Cell:
        Capacity: 165 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>

 Witnesses :
      < valid signature for another public key hash >
      < valid signature for receiver public key hash >
```

When a signature is provided and can be validated by the receiver public key hash, and the sum of sender output cells capacity is equal to the sum of the cheque input cells capacity, the cheque cells can be unlocked. In this example a cheque cell is converted back to a sender normal cell and the SUDT is transferred from the sender to an arbitrary lock script set by the receiver.

#### 2. Claim via receiver lock script

```
Inputs:
    Cheque Cell:
        Capacity: 165 CKBytes
        Lock:
            code_hash: cheque lock
            args: <receiver_secp256k1_blake2b_lock_hash[0..20]> <sender_secp256k1_blake2b_lock_hash[0..20]>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 100 UDT
    SUDT Cell:
        Capacity: 200 CKBytes
        Lock: <receiver_secp256k1_blake2b_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 200 UDT

Outputs:
    SUDT Cell:
        Capacity: 199.99 CKBytes
        Lock: <receiver_secp256k1_blake2b_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 300 UDT
    Normal Cell:
        Capacity: 165 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>

Witnesses:
    < 0x >
    < valid signature for receiver_receiver public key hash >

```

Here the transaction inputs contain a receiver secp256k1_blake160 cell whose first 20 bytes of lock script hash is equal to the `receiver_secp256k1_blake2b_lock_hash[0..20]` of the cheque cell lock args, and the signature can be validated by the receiver public key hash, and the sum of sender output cells capacity is equal to the sum of the cheque input cells capacity, the cheque cell can be unlocked.

### Withdraw

#### 1. Withdraw via sender signature

```
Inputs:
    Cheque Cell:
        Capacity: 165 CKBytes
        Lock:
            code_hash: <cheque_cell_script_code_hash>
            args: <receiver_secp256k1_blake2b_lock_hash[0..20]> <sender_secp256k1_blake2b_lock_hash[0..20]>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 100 UDT
        Since: 0xA000000000000006

Outputs:
    SUDT Cell:
        Capacity: 164.99 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 100 UDT

Witnesses:
    < valid signature for sender public key hash >
```

When a signature is provided and can be validated by the sender public key hash, and the since of the cheque input cell is same as `0xA000000000000006` which means the tx failed verification unless it is 6 epochs later since the input cells get confirmed on-chain, the cheque cell can be unlocked. In this example a cheque cell is converted back to a sender normal cell with SUDT.

#### 2. Withdraw via sender lock script

```
Inputs:
    Cheque Cell:
        Capacity: 165 CKBytes
        Lock:
            code_hash: <cheque_cell_script_code_hash>
            args: <receiver_secp256k1_blake2b_lock_hash[0..20]> <sender_secp256k1_blake2b_lock_hash[0..20]>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 100 UDT
        Since: 0xA000000000000006
    Normal Cell:
        Capacity: 200 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>

Outputs:
    SUDT Cell:
        Capacity: 165 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>
        Type: <sudt_type_script>
        Data:
            sudt_amount: 100 UDT
    Normal Cell:
        Capacity: 199.99 CKBytes
        Lock: <sender_secp256k1_blake2b_lock_script>

Witnesses:
    < 0x >
    < valid signature for sender public key hash >
```

Here the transaction inputs contain a sender secp256k1_blake160 cell whose first 20 bytes of lock script hash is equal to the `sender_secp256k1_blake2b_lock_hash[0..20]` of the cheque cell lock args, and the signature can be validated by the sender public key hash, and the since of the cheque input cell is same as `0xA000000000000006` which means the tx failed verification unless it is 6 epochs later since the input cells get confirmed on-chain, the cheque cell can be unlocked. In this example a cheque cell is converted back to a sender normal cell with SUDT.

## Deployment

[cheque](https://talk.nervos.org/t/sudt-cheque-deposit-design-and-implementation/5209) ([Source Code](https://github.com/nervosnetwork/ckb-cheque-script/tree/4ca3e62ae39c32cfcc061905515a2856cad03fd8)) allows a sender to temporarily provide cell capacity in asset transfer.

- Lina

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0xe4d4ecc6e5f9a059bf2f7a82cca292083aebc0c421566a52484fe2ec51a9fb0c` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x04632cc459459cf5c9d384b43dee3e36f542a464bdd4127be7d6618ac6f8d268` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

**Note:**

The `dep_type` of `cheque` in Lina is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `cheque` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0xe2fb199810d49a4d8beec56718ba2593b665db9d52299a0f9e6e75416d73ff5c,
  index: 0x3
}
```

and the `out_point` of `cheque` whose `dep_type` is `code` is

```
{
  tx_hash: 0x0a34aeea122d9795e06e185746a92e88bca0ad41b0e5842a960e5fd1d43760a6,
  index: 0x0
}
```

- Aggron

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | `0x60d5f39efce409c587cb9ea359cefdead650ca128f0bd9cb3855348f98c70d5b` |
| `hash_type` | `type`                                                               |
| `tx_hash`   | `0x7f96858be0a9d584b4a9ea190e0420835156a6010a5fde15ffcdc9d9c721ccab` |
| `index`     | `0x0`                                                                |
| `dep_type`  | `dep_group`                                                          |

**Note:**

The `dep_type` of `cheque` in Aggron is `dep_group` means that the content of this dep cell contains two cell deps which are `secp256k1_data` and `cheque` whose `dep_type` are `code`.

The `out_point` of `secp256k1_data` is

```
{
  tx_hash: 0x8f8c79eb6671709633fe6a46de93c0fedc9c1b8a6527a18d3983879542635c9f,
  index: 0x3
}
```

and the `out_point` of `cheque` is

```
{
  tx_hash: 0x1b16769dc508c8349803fe65558f49aa8cf04ca495fbead42513e69e46608b6c,
  index: 0x0
}
```

## Notes

Reproducible build is supported to verify the deploy script. To build the deployed cheque lock script above, one can use the following steps:

```bash
$ git clone https://github.com/nervosnetwork/ckb-cheque-script
$ cd ckb-cheque-script
$ git checkout 4ca3e62ae39c32cfcc061905515a2856cad03fd8
$ git submodule update --init
$ cd contracts/ckb-cheque-script/ckb-lib-secp256k1/ckb-production-scripts
$ git submodule update --init
$ cd .. && make all-via-docker
$ cd ../../.. && capsule build --release
```

A draft of this specification has already been released, reviewed, and discussed in the community at [here](https://talk.nervos.org/t/sudt-cheque-deposit-design-and-implementation/5209) for quite some time.
