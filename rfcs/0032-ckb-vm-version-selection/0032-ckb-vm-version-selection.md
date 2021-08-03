---
Number: "0032"
Category: Consensus (Hard Fork)
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2021-04-26
---

# CKB VM Version Selection

## Abstract

This RFC proposes a mechanism to choose the CKB VM version after the hard fork. What's included in the new CKB VM version is beyond the scope of this document.

## Motivation

It's essential to keep improving CKB VM because it is the computation bottleneck of the whole network. The upgrade packages can improve the performance, bring bug fixings and add new RISC-V extensions. However the upgrade should not break the old code, users must have the opt-in option to specify the VM version.

This RFC proposes a general mechanism that determines how the CKB node chooses the CKB VM version for a transaction script group.

## Specification

The CKB VM upgrades via hard fork. The next scheduled hard fork is ckb2021, which is activated since a specific epoch. For all the transactions in the blocks before the activation epoch, they must run the CKB VM version 0 to verify all the script groups. In these transactions, the `hash_type` in cell lock and type script must be either 0 or 1 in the serialized molecule data.

After ckb2021 is activated, CKB nodes must choose the CKB VM version for each script group. The allowed values for the `hash_type` field in the lock and type script are 0, 1, and 2. Cells are sorted into different groups if they have different `hash_type`. According to the value of `hash_type`:

* When the `hash_type` is 0, the script group matches code via data hash and will run the code using the CKB VM version 0.
* When the `hash_type` is 1, the script group matches code via type script hash and will run the code using the CKB VM version 1.
* When the `hash_type` is 2, the script group matches code via data hash and will run the code using the CKB VM version 1.

| `hash_type` | matches by       | VM version |
| ----------- | ---------------- | ---------- |
| 0           | data hash        | 0          |
| 1           | type script hash | 1          |
| 2           | data hash        | 1          |

The VM version 0 deployed with the Lina and Aggron genesis block is version 0.

The VM version 1 will be deployed along ckb2021. The [rfc33] highlights the changes in this version, and [rfc34] lists the new syscalls only available since version 1.

[rfc33]: ../0033-ckb-vm-version-1/0033-ckb-vm-version-1.md
[rfc34]: ../0034-vm-syscalls-2/0034-vm-syscalls-2.md

The transaction is considered invalid if any `hash_type` is not in the allowed values 0, 1, and 2.

See more information about code locating using `hash_type` in [rfc22].

[rfc22]: ../0022-transaction-structure/0022-transaction-structure.md

Because the VM selection algorithm depends on which epoch the transaction belongs to, it is not deterministic for transactions still in the memory pool. The CKB node must run two versions of transaction relay protocols, one for the current CKB version C and another for the next fork version N.

* Before the fork is activated, CKB node must relay transactions via relay protocol C and must drop all messages received via protocol N.
* After the fork is activated, CKB node must relay transactions via relay protocol N and must drop all messages received via protocol C.

The relay protocol C will be dropped after the fork succeeds. See [rfc35] for details.

[rfc35]: ../0035-ckb2021-p2p-protocol-upgrade/0035-ckb2021-p2p-protocol-upgrade.md

Attention that, [rfc33], [rfc34], and [rfc35] must be activated together with this one starting at the same epoch.

When a new block is appended to the chain and the fork is activated, or a block is rolled back and the fork is deactivated, the CKB node must rerun the verification on all the transactions in the pool.

In [nervosnetwork/ckb](https://github.com/nervosnetwork/ckb), the `hash_type` is returned in the JSON RPC as an enum. Now it has three allowed values:

* 0: "data"
* 1: "type"
* 2: "data1"

## Rationale

There are many other solutions to select VM versions. The current solution is the result of discussion and trade-off. Following are some example alternatives:

* Always use the latest VM version. The users have no options to freeze the VM versions used in their transactions.
* Depend on the script code cell epoch. Use the old VM version if the code cell is deployed before the fork, and use the new one otherwise. The problem of this solution is that anyone can re-deploy the cell and construct the transaction using the new code cell to choose VM versions.

## Backward compatibility

For cell scripts which reference codes via data hash, they will use the same VM before and after the fork. For those referenced by type hash, they will use the different VM versions. The dApps developers must ensure the compatibility of their scripts and upgrade them if necessary.

## Acknowledgments

The authors would like to thank Jan (@janx) and Xuejie (@xxuejie) for their comments and insightful suggestions. The members in the CKB Dev team also helped by participating the discussion and review. Boyu (@yangby-cryptape) is the major author of the code changes, and his experiments and feedbacks are essential to complete this document.
