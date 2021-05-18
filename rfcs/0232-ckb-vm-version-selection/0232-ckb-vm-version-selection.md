---
Number: "0232"
Category: Consensus (Hard Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-04-26
---

# CMB VM Version Selection

## Abstract

This RFC proposes a mechanism to choose the CKB VM version after the hard fork. What's included in the new CKB VM version is beyond the scope of this document.

## Motivation

It's essential to keep improving CKB VM because it is the computation bottleneck of the whole network. The upgrade packages can improve the performance, bring bug fixings and add new RISC-V extensions. However the upgrade should not break the old code, users must have the opt-in option to specify the VM version.

This RFC proposes a general mechanism that how CKB node chooses the CKB VM version for a transaction script group.

## Specification

The CKB VM upgrades via hard fork. The next scheduled hard fork is ckb2021, which is activated since a specific epoch. For all the transactions in the blocks before the activation epoch, they must run the CKB VM version 0 to verify all the script groups. In these transactions, the `hash_type` in cell lock and type script must be either 0 or 1.

After ckb2021 is activated, CKB node must choose the CKB VM version for each script group. The `hash_type` field in the lock and type script must be 1 or any even numbers. Cells are sorted into different groups if they have different `hash_type`. According to the value of `hash_type`:

* When the `hash_type` is 1, the script group matches code via type script hash and will run the code using the CKB VM version 1.
* When the `hash_type` is a even number D, the script group matches code via data hash and will run the code using the CKB VM version D/2.

See following sections about VM versions.

The transaction is considered invalid if any `hash_type` is:

* an odd number that is not 1
* an even number D that D/2 is larger than the largest known CKB VM version.

Because the VM selection algorithm depends on which epoch the transaction belongs to, it is not deterministic for transactions still in the memory pool. The CKB node must run two versions of transaction relay protocols, one for the current CKB version C and another for the next fork version N.

* Before the fork is activated, CKB node must relay transactions via relay protocol C and must drop all messages received via protocol N.
* After the fork is activated, CKB node must relay transactions via relay protocol N and must drop all messages received via protocol C.

The relay protocol C will be dropped after the fork succeeds.

When a new block is appended to the chain and the fork is activated, or a block is rolled back and the fork is deactivated, the CKB node must rerun the verification on all the transactions in the pool.

Because `hash_type` is no longer a simple enum with values "data" and "type", the [`Script`](https://github.com/nervosnetwork/ckb/blob/develop/rpc/README.md#type-script) structure in the RPC will receive a new field `vm_version`.

* When the `hash_type` is 1, the `hash_type` in the corresponding JSON object is "type" and `vm_version` must be absent.
* When the `hash_type` is an even number D, the `hash_type` in the corresponding JSON object is "data" and `vm_version` must be 0x prefixed string which encodes D/2 in hex.

### CKB VM Versions

The VM version 0 deployed with the Lina and Aggron genesis block is version 0.

The VM version 1 will be deployed along ckb2021. The [rfc236] highlights the changes in this version, and [rfc237] lists the new syscalls only available since version 1.

[rfc236]: ../0236-ckb-vm-version-1/0236-ckb-vm-version-1.md
[rfc237]: ../0237-vm-syscalls-2/0237-vm-syscalls-2.md

## Rationale

There are many other solutions to select VM versions. The current solution is the result of discussion and trade-off. Following are some example alternatives:

* Always use the latest VM version. The users have no options to freeze the VM versions used in their transactions.
* Depend on the script code cell epoch. Use the old VM version if the code cell is deployed before the fork, and use the new one otherwise. The problem of this solution is that anyone can re-deploy the cell and construct the transaction using the new code cell to choose VM versions.

## Backward compatibility

For cell scripts which reference codes via data hash, they will use the same VM before and after the fork. The those referenced by type hash, they will use the different VM versions. The dApps developers must ensure the compatiblity of their scripts and upgrade them if necessary.

## Acknowledgments

The authors would like to thank Jan (@janx) and Xuejie (@xxuejie) for their comments and insightful suggestions. The members in the CKB Dev team also helped by participating the discussion and review. Boyu (@yangby-cryptape) is the major author of the code changes, and his experiments and feedbacks are essential to complete this document.