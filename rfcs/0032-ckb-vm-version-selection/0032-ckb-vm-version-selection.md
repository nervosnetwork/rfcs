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

This RFC proposes a mechanism to decide on the CKB VM version to execute the transaction scripts.

## Motivation

It's essential to keep improving CKB VM because it is the computation bottleneck of the whole network. The upgrade packages can improve the performance, bring bug fixings and add new RISC-V extensions. However the upgrade should not break the old code, users must have the opt-in option to specify the VM version.

This RFC proposes a general mechanism that determines how the CKB node chooses the CKB VM version for a transaction script group.

## Specification

When CKB launches the testnet Lina, it only has one VM version, the version 0. The first hard fork will bring VM version 1 which coexists with version 0. Users have the opt-in option to specify which VM version to run the script of a cell by setting the `hash_type` field.

In CKB, each VM version also has its bundled instruction set, syscalls and cost model. The [rfc3], [rfc5], [rfc9] and [rfc14] have defined what is VM version 0. VM version 1 is version 0 plus the revisions mentioned in [rfc33] and [rfc34].

[rfc3]: ../0003-ckb-vm/0003-ckb-vm.md
[rfc5]: ../0005-priviledged-mode/0005-priviledged-mode.md
[rfc9]: ../0009-vm-syscalls/0009-vm-syscalls.md
[rfc14]: ../0014-vm-cycle-limits/0014-vm-cycle-limits.md
[rfc33]: ../0033-ckb-vm-version-1/0033-ckb-vm-version-1.md
[rfc34]: ../0034-vm-syscalls-2/0034-vm-syscalls-2.md

The first hard fork takes effect from an epoch decided by the community consensus. For all the transactions in the blocks before the activation epoch, they must run the CKB VM version 0 to verify all the script groups. In these transactions, the `hash_type` in cell lock and type script must be 0 or 1 in the serialized molecule data.

After the fork is activated, CKB nodes must choose the CKB VM version for each script group. The allowed values for the `hash_type` field in the lock and type script are 0, 1, and 2. Cells are sorted into different groups if they have different `hash_type`. According to the value of `hash_type`:

* When the `hash_type` is 0, the script group matches code via data hash and will run the code using the CKB VM version 0.
* When the `hash_type` is 1, the script group matches code via type script hash and will run the code using the CKB VM version 1.
* When the `hash_type` is 2, the script group matches code via data hash and will run the code using the CKB VM version 1.

| `hash_type` | matches by       | VM version |
| ----------- | ---------------- | ---------- |
| 0           | data hash        | 0          |
| 1           | type script hash | 1          |
| 2           | data hash        | 1          |

The transaction is invalid if any `hash_type` is not in the allowed values 0, 1, and 2.

See more information about code locating using `hash_type` in [rfc22].

[rfc22]: ../0022-transaction-structure/0022-transaction-structure.md

The `hash_type` encoding pattern ensures that if a script matches code via type hash, CKB always uses the latest available version of VM depending when the script is executed. But if the script matches code via data hash, the VM version to execute is determined when the cell is created.

Here is an example of when VM version 2 is available:

| `hash_type` | matches by       | VM version |
| ----------- | ---------------- | ---------- |
| 0           | data hash        | 0          |
| 1           | type script hash | 2          |
| 2           | data hash        | 1          |
| \*          | data hash        | 2          |

> \* The actual value to represent data hash plus VM version 2 is undecided yet.

User can trade off between the determination and VM performance boost when creating the cell. Choose data hash for determination, and type hash for the latest VM techniques.

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

There are many other solutions to select VM versions. The current solution results from discussion and trade-off. Following are some example alternatives:

* Always use the latest VM version. The users have no options to freeze the VM versions used in their transactions.
* Depend on the script code cell epoch. Use the old VM version if the code cell is deployed before the fork, and use the new one otherwise. The problem with this solution is that anyone can re-deploy the cell and construct the transaction using the new code cell to choose VM versions.

## Backward compatibility

For cell scripts which reference codes via data hash, they will use the same VM before and after the fork. For those referenced by type hash, they will use the different VM versions. The dApps developers must ensure the compatibility of their scripts and upgrade them if necessary.

## Test Vectors

### Transaction Hash

This is a transaction containing `data1` hash type.

<details><summary>JSON</summary>

```json
{
    "version": "0x0",
    "cell_deps": [
    {
        "out_point": {
        "tx_hash": "0xace5ea83c478bb866edf122ff862085789158f5cbff155b7bb5f13058555b708",
        "index": "0x0"
        },
        "dep_type": "dep_group"
    }
    ],
    "header_deps": [],
    "inputs": [
    {
        "since": "0x0",
        "previous_output": {
        "tx_hash": "0xa563884b3686078ec7e7677a5f86449b15cf2693f3c1241766c6996f206cc541",
        "index": "0x7"
        }
    }
    ],
    "outputs": [
    {
        "capacity": "0x2540be400",
        "lock": {
        "code_hash": "0x709f3fda12f561cfacf92273c57a98fede188a3f1a59b1f888d113f9cce08649",
        "hash_type": "data",
        "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
        },
        "type": null
    },
    {
        "capacity": "0x2540be400",
        "lock": {
        "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
        "hash_type": "type",
        "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
        },
        "type": null
    },
    {
        "capacity": "0x2540be400",
        "lock": {
        "code_hash": "0x709f3fda12f561cfacf92273c57a98fede188a3f1a59b1f888d113f9cce08649",
        "hash_type": "data1",
        "args": "0xc8328aabcd9b9e8e64fbc566c4385c3bdeb219d7"
        },
        "type": null
    }
    ],
    "outputs_data": [
    "0x",
    "0x",
    "0x"
    ],
    "witnesses": [
    "0x550000001000000055000000550000004100000070b823564f7d1f814cc135ddd56fd8e8931b3a7040eaf1fb828adae29736a3cb0bc7f65021135b293d10a22da61fcc64f7cb660bf2c3276ad63630dad0b6099001"
    ]
}
```

</details>

The Transaction Hash is `0x9110ca9266f89938f09ae6f93cc914b2c856cc842440d56fda6d16ee62543f5c`.

## Acknowledgments

The authors would like to thank Jan (@janx) and Xuejie (@xxuejie) for their comments and insightful suggestions. The members in the CKB Dev team also helped by participating the discussion and review. Boyu (@yangby-cryptape) is the major author of the code changes, and his experiments and feedbacks are essential to complete this document.
