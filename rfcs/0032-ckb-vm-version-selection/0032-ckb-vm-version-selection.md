---
Number: "0032"
Category: Standards Track
Status: Proposal
Author: Ian Yang <@doitian>
Created: 2021-04-26
---

# CKB VM Version Selection

## Abstract

This RFC proposes a mechanism for selecting the CKB VM version to execute transaction scripts.

## Motivation

CKB VM must be continuously improved, since it is the computation bottleneck of the entire network. The upgrade package can improve performance, bring bug fixes and add new RISC-V extensions. However, the upgrade must not break the old code, and users must have the opt-in option to specify the VM version.

This RFC proposes a general mechanism that determines how the CKB node chooses the CKB VM version for a transaction script group.

## Specification

When CKB launches the testnet Lina, it has only one VM version, version 0. The first hard fork will bring VM version 1, which will coexist with version 0. By setting the `hash_type` field, users can specify which VM version to use to run a cell's script.

Each VM version in CKB has its own bundled instruction set, syscalls, and cost model. [RFC3], [RFC5], [RFC9] and [RFC14] have defined what VM version 0 is. VM version 1 is version 0 plus the revisions mentioned in [RFC33] and [RFC34].

[RFC3]: ../0003-ckb-vm/0003-ckb-vm.md
[RFC5]: ../0005-priviledged-mode/0005-priviledged-mode.md
[RFC9]: ../0009-vm-syscalls/0009-vm-syscalls.md
[RFC14]: ../0014-vm-cycle-limits/0014-vm-cycle-limits.md
[RFC33]: ../0033-ckb-vm-version-1/0033-ckb-vm-version-1.md
[RFC34]: ../0034-vm-syscalls-2/0034-vm-syscalls-2.md

The first hard fork takes effect from an epoch decided by the community consensus. For the transactions in blocks before the activation epoch, it is necessary to run CKB VM version 0 to verify all script groups. In these transactions, the `hash_type` field in the cell lock and type script must be 0 or 1 in the serialized molecule data.

After the fork is activated, CKB nodes must choose CKB VM version for each script group. The allowed values for the `hash_type` field in the lock and type script are 0, 1, and 2. Cells are sorted into different groups if they have different `hash_type` values. A script group matches code and select the VM version according to the value of `hash_type`:

* When the value of `hash_type` is 0, the script group matches code via data hash and will run the code using CKB VM version 0.
* When the value of `hash_type` is 1, the script group matches code via type script hash and will run the code using CKB VM version 1.
* When the value of `hash_type` is 2, the script group matches code via data hash and will run the code using CKB VM version 1.

| `hash_type` | matches by       | VM version |
| ----------- | ---------------- | ---------- |
| 0           | data hash        | 0          |
| 1           | type script hash | 1          |
| 2           | data hash        | 1          |

If a `hash_type` is not one of the allowed values 0, 1, or 2, then the transaction is invalid.

For more information about locating code using `hash_type`, see [RFC22].

[RFC22]: ../0022-transaction-structure/0022-transaction-structure.md

The `hash_type` encoding pattern ensures that if a script matches code via type hash, CKB always uses the latest available version of VM depending when the script is executed. But if the script matches code via data hash, the VM version is determined when the cell is created.

Here is an example of when VM version 2 is available:

| `hash_type` | matches by       | VM version |
| ----------- | ---------------- | ---------- |
| 0           | data hash        | 0          |
| 1           | type script hash | 2          |
| 2           | data hash        | 1          |
| \*          | data hash        | 2          |

> \* The actual value to represent data hash plus VM version 2 is undecided yet.

Cell owners can trade off between determination and VM performance boost when creating the cell. They can use data hash for determination, and type hash for the latest VM techniques.

In [nervosnetwork/ckb](https://github.com/nervosnetwork/ckb), the `hash_type` is returned in the JSON RPC as an enum. Now it has three allowed values:

* 0: "data"
* 1: "type"
* 2: "data1"

## RFC Dependencies

This RFC depends on [RFC33], [RFC34], and [RFC35]. The 4 RFCs must be activated together at the same epoch.

[RFC35]: ../0035-ckb2021-p2p-protocol-upgrade/0035-ckb2021-p2p-protocol-upgrade.md

The first two RFCs, [RFC33] and [RFC34] are the specification of VM version 1. [RFC35] proposes to run two versions of transaction relay protocols during the fork. This is because the VM selection algorithm depends on which epoch transactions belong to, thus it is not deterministic for transactions still in the memory pool.

## Rationale

There are many other solutions to select VM versions. The current solution is the result of discussions and trade-offs.

The following are two alternative solutions:

- Use the latest VM version consistently. You cannot specify the VM version for transactions, and the version selection will be non-deterministic due to the chain state.

* Select the VM version depending on the epoch of the script code cell. If the code cell is deployed before the fork, you can use the old VM version. Otherwise, use the new version. This solution has the problem that anyone can re-deploy the cell and then construct the transaction using the new code cell to choose VM versions.

## Backward Compatibility

The cell scripts that match code via data hash will use the same VM before and after the fork. The cell scripts that match code via type hash will use different VM versions. DApp developers must ensure the compatibility of their scripts and upgrade them if necessary.

## Test Vectors

### Transaction Hash

The following is a transaction containing the `data1` hash type.

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

The transaction hash is `0x9110ca9266f89938f09ae6f93cc914b2c856cc842440d56fda6d16ee62543f5c`.

## Acknowledgments

The authors would like to thank Jan Xie and Xuejie Xiao for their comments and insightful suggestions. The members of the CKB Dev team also helped by participating in the discussion and review. Boyu Yang is the primary author of the code changes, and his experiments and feedbacks are essential to complete this document.
