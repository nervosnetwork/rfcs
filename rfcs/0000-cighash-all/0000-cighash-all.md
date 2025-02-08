---
Number: "0000"
Category: Standards Track
Status: Proposal
Author: Xuejie Xiao <xxuejie@gmail.com>
Created: 2025-02-05
---

# CIGHASH_ALL

This document defines a new message calculation scheme used by CKB lock scripts to guard against malleable attacks.

## Rationale

Unlike most blockchains out there, CKB does not formally define signature verification flow in CKB transactions. Instead, a CKB transaction is considered to be valid when all lock scripts in its input cells, as well as all type scripts in its input & output cells succeed in [execution](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0003-ckb-vm/0003-ckb-vm.md).

Nonetheless, a transaction must not be malleable, meaning a transaction shall not be tampered with after someone creates it in the first place. By convention, the lock scripts in CKB guard against malleable attacks: a typical lock script, running for a series of input cells forming a particular script group, would calculage a `message` by accessing the transaction it runs upon, then fetches a signature from one of the designated witness field. It then runs a signature verification process to validate the signature against the `message`, and only succeeds when the signature passes the verification. With this mechanism, any tampering on the transaction itself will result in a different `message`, resulting in a failure of the verification process, leading to a failure of the execution of lock scripts.

The exact way to calculate such a `message` processes enough challenge, since the `message` shall capture enough information so the transaction is safe from any tampering, while the `message` shall not cover too much data to obscure interoperability.

Historically, a particular `message` calculation algorithm has been [introduced](https://github.com/nervosnetwork/ckb-system-scripts/blob/934166406fafb33e299f5688a904cadb99b7d518/c/secp256k1_blake160_sighash_all.c#L149-L219) by lock scripts included in CKB's genesis blocks, and used since then. Many other locks from the community have also adopted a similar workflow. However, this workflow has only since existed in part of a script's implementation. It has never been properly documented. On the other hand, certain pitfalls of this very workflow arise as we learn more about coding for CKB's particular environment:

* While the current workflow assumes the first witness of current executed input cells [script group](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0022-transaction-structure/0022-transaction-structure.md) is a [WitnessArgs](https://github.com/nervosnetwork/ckb/blob/a6733e6af5bb0da7e34fb99ddf98b03054fa9d4a/util/types/schemas/blockchain.mol#L104-L108) structure serialized in the [molecule](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0008-serialization/0008-serialization.md) serialization format, this particular assumption is not enforced, and there is code that [exploits](https://github.com/cryptape/quantum-resistant-lock-script/blob/22de5369b60b1e59bb698927c143d9efbe8527a9/c/ckb-sphincsplus-lock.c#L67-L80) this oversight for certain gains. We do believe this can be a problem as future standards arise.
* The current workflow covers the whole [Transaction](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0022-transaction-structure/0022-transaction-structure.md) structure, as well as all witnesses from the current script group. However, the `Transaction` structure only contains pointer to all the consumed input cells, it does not cover any contents of the input cells, e.g., the CKBytes store in each input cell, or any input cell's data. This makes it harder to design a proper offline signing protocol. If we dig through the literature, the Bitcoin community actually made the same choice early, but later [came up](https://en.bitcoin.it/wiki/BIP_0143) with an updated design, that signs actual contents of each input UTXOs as well. We do believe a message that covers all input cells' contents can definitely bring merits to future CKB wallets & appliations.

As a result, this document aims to propose `CIGHASH_ALL`, a properly defined message calculation scheme used by CKB lock scripts to ensure transactions are not malleable.

The name `CIGHASH_ALL` comes from `CKB's Signature Hash All`. In many places, including [filename](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/secp256k1_blake160_sighash_all.c) from CKB's system script code, `SIGHASH_ALL` has been used to represent the old workflow to calculate a signing message. Here we explicitly pick a different name, so as to distinguish between the two.

## Specification

For a CKB transaction, `CIGHASH_ALL` utilities the following workflow:

* The first witness field of the current running script group, must be a valid `WitnessArgs` structure serialized in the molecule serialization format, with compatible mode turned off. The message calculation workflow fails if molecule validation fails.
* The byte concatenation of all the following fields is then calculated, following the exact same order defined here:
    + 32-byte transaction hash returned by [Load Transaction Hash](https://github.com/nervosnetwork/rfcs/blob/bd5d3ff73969bdd2571f804260a538781b45e996/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-transaction-hash) syscall.
    + For each input cell of the current transaction in sequential order:
        * The full [CellOutput](https://github.com/nervosnetwork/ckb/blob/a6733e6af5bb0da7e34fb99ddf98b03054fa9d4a/util/types/schemas/blockchain.mol#L44-L48) structure of current input cell serialized in the molecule serialization format, which is also the full content returned by [Load Cell](https://github.com/nervosnetwork/rfcs/blob/bd5d3ff73969bdd2571f804260a538781b45e996/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell) syscall, given the correct `index` and `source`.
        * The length of current input cell, packed in little-endian encoded unsigned 32-bit integer.
        * The full cell data of current input cell, or the full content returned by [Load Cell Data](https://github.com/nervosnetwork/rfcs/blob/bd5d3ff73969bdd2571f804260a538781b45e996/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-cell-data) syscall, given the correct `index` and `source`.
    + The first 16 bytes of data from the first witness field in current script group.
    + The whole `input_type` field (a `BytesOpt` structure) from the first witness field in current script group.
    + The whole `output_type` field (a `BytesOpt` structure) from the first witness field in current script group.
    + Starting from the second witness field in current script group, for each witness in sequential order:
        * The length of the witness field, packed in little-endian encoded unsigned 32-bit integer.
        * The full witness field, or the full content returned by [Load Witness](https://github.com/nervosnetwork/rfcs/blob/bd5d3ff73969bdd2571f804260a538781b45e996/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-witness) syscall, given the correct `index` and `source`.
    + Starting from the first witness that do not have an input cell of the same index(e.g., assuming a transaction has 5 input cells in total, the counting here starts from index 5 of witnesses), for each witness in sequential order:
        * The length of the witness field, packed in little-endian encoded unsigned 32-bit integer.
        * The full witness field, or the full content returned by [Load Witness](https://github.com/nervosnetwork/rfcs/blob/bd5d3ff73969bdd2571f804260a538781b45e996/rfcs/0009-vm-syscalls/0009-vm-syscalls.md#load-witness) syscall, given the correct `index` and `source`.
* As an optional step, a cryptographic hashing algorithm can be leveraged to convert the above concatenated bytes into a hash of 32 bytes or more.

### Notable Points

There are several notable points worth mentioning regarding the above specification:

* The first witness of current running script group must be a valid [WitnessArgs] structure serialized in the molecule serialization format. There shall be not assumptions with respect to this rule.
* The content of all input cells are all covered by any signature guarding a particular CKB transaction, making it much easier to design an offline signing scheme.
* Witness length is packed in 32-bit unsigned integers, while 64-bit unsigned integers were used in older workflow.
* A different concatenation/hashing design is introduced for the first witness of the current script group, here we discard the zero-filled design, in favor of a different solution that only includes selective, useful bytes, this can contribute to a more optimized implementation, both in terms of runtime cycles and binary size.

## Examples

Following the defined spec above, a [series of libraries, CKB scripts and utilities](https://github.com/xxuejie/cighash-all-test-vector-utils) have been developed as a demonstration and inspiration. For example:

* A [Rust module](https://github.com/xxuejie/cighash-all-test-vector-utils/blob/c500a3dd8dd2b8e245527133709bc48d6e67d694/crates/cighash-all-utils/src/cighash_all_in_ckb_vm.rs) calculates `CIGHASH_ALL` message with the help of [ckb-std](https://docs.rs/ckb-std/latest/ckb_std/) to provide CKB-related APIs in CKB-VM environment. It is also designed in a generic way, which makes it compatible with different kinds of hashers;
* Another [Rust module](https://github.com/xxuejie/cighash-all-test-vector-utils/blob/c500a3dd8dd2b8e245527133709bc48d6e67d694/crates/cighash-all-utils/src/cighash_all_from_mock_tx.rs) also calculates `CIGHASH_ALL` message in a generic way. But it was designed to take the whole CKB [Transaction](https://docs.rs/ckb-gen-types/0.119.0/ckb_gen_types/packed/struct.Transaction.html) as input. Certainly, the CKB Transaction structure is missing the actual contents for all input cells, a user can either provide [MockTransaction](https://docs.rs/ckb-mock-tx-types/latest/ckb_mock_tx_types/struct.MockTransaction.html) instead, or simply provide the contents for input cells.
* A [C header-only implementation](https://github.com/xxuejie/cighash-all-test-vector-utils/blob/c500a3dd8dd2b8e245527133709bc48d6e67d694/contracts/c-assert-cighash/cighash_all.h) is also provided to calculate `CIGHASH_ALL` message, also in a generic way to support different kinds of hashers, in CKB-VM compatible environments.

All of the above Rust & C implementations have been carefully written, well optimized, and extensively tested. They are considered to be usable in production environments.

A [utility](https://github.com/xxuejie/cighash-all-test-vector-utils/tree/main/crates/native-test-vector-generator) is also provided so one can manually generate as many test vectors as one wish. Each test vector includes a tx file that can be accepted and executed in [ckb-debugger](https://github.com/nervosnetwork/ckb-standalone-debugger), as well as the generated `CIGHASH_ALL` message, together with enough information to generate such message.
