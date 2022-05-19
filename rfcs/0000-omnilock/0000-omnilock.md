---
Number: "0000"
Category: Standards Track
Status: Proposal
Author: Xu Jiandong
Organization: Nervos Foundation
Created: 2022-05-19
---

# Omnilock

Omnilock is a new lock script designed for interoperability. It supports various transaction verifications used in
popular blockchains, such as Bitcoin, Ethereum, EOS, and Dogecoin. Omnilock is also extensible, so more verification
algorithms can be added in future. This feature makes Omnilock a powerful module in Nervos interoperability 2.0.

Another feature of Omnilock for practitioners is the regulation compliance module (Consider it as interoperability with
the traditional world). If enabled, the specified administrator can revoke tokens held by users under circumstances
which the administrator deems proper. This part has evolved from the [Regulation Compliance Extension
(RCE)](https://talk.nervos.org/t/rfc-regulation-compliance-extension/5338) proposal for
[xUDT](https://talk.nervos.org/t/rfc-extensible-udt/5337). This feature provides an option that sits at the other side
of the asset lock spectrum and lays the foundation of registered assets like Apple stock on CKB. When used together,
Omnilock and RCE provide an [ERC-1404](https://erc1404.org/) equivalence.

## Authentication

Omnilock introduces a new concept, authentication ( auth ) to CKB lock scripts: an auth is a 21-byte data structure
containing the following components:

```
<1 byte flag> <20 bytes auth content>
```

Depending on the value of the flag, the auth content has the following interpretations:

* 0x0: The auth content represents the blake160 hash of a secp256k1 public key. The lock script will perform secp256k1
  signature verification, the same as the [SECP256K1/blake160
  lock](https://github.com/nervosnetwork/rfcs/blob/780b2f98068ed2337f3a97b02ec6b5336b6fb143/rfcs/0024-ckb-genesis-script-list/0024-ckb-genesis-script-list.md#secp256k1blake160).

* 0x01~0x05: It follows the same unlocking methods used by
  [PW-lock](https://github.com/lay2dev/pw-lock/blob/c2b1456bcca06c892e1bb8ec8ac0a64d4fb2b83d/c/pw_lock.h#L190-L223)


* 0x06: It follows the same unlocking method used by [CKB
  MultiSig](https://github.com/nervosnetwork/ckb-system-scripts/blob/master/c/secp256k1_blake160_multisig_all.c)

* 0xFC: The auth content that represents the blake160 hash of a lock script. The lock script will check if the current
  transaction contains an input cell with a matching lock script. Otherwise, it would return with an error. It's similar
  to [P2SH in BTC](https://en.bitcoin.it/wiki/Pay_to_script_hash).

* 0xFD: The auth content that represents the blake160 hash of a preimage. The preimage contains
  [exec](https://github.com/nervosnetwork/rfcs/pull/237) information that is used to delegate signature verification to
  another script via exec.

* 0xFE: The auth content that represents the blake160 hash of a preimage. The preimage contains [dynamic
  linking](https://docs.nervos.org/docs/labs/capsule-dynamic-loading-tutorial/) information that is used to delegate
  signature verification to the dynamic linking script. The interface described in [Swappable Signature Verification
  Protocol Spec](https://talk.nervos.org/t/rfc-swappable-signature-verification-protocol-spec/4802) is used here.


## Omnilock Script

An Omnilock script has the following structure:
```text
Code hash: Omnilock script code hash
Hash type: Omnilock script hash type
Args: <21 byte auth> <Omnilock args>
```

among which, the structure of `<Omnilock args>` is as follows:

```
<1 byte Omnilock flags> <32 byte RC cell type ID, optional> <2 bytes minimum ckb/udt in ACP, optional> <8 bytes since for time lock, optional> <32 bytes type script hash for supply, optional>
```

| Name               | Flags      | Affected Args   |Affected Args Size (byte)|Affected Witness
| -------------------|------------|-----------------|---------|-------------------------------- 
| administrator mode | 0b00000001 |	RC cell type ID | 32      | omni_identity/signature in OmniLockWitnessLock
| anyone-can-pay mode| 0b00000010 | minimum ckb/udt in ACP| 2 | N/A
| time-lock mode     | 0b00000100 | since for timelock| 8     | N/A
| supply mode        | 0b00001000 |type script hash for supply| 32 | N/A
| Omnilock args      | N/A        |21-byte auth identity | 21 | signature in OmniLockWitnessLock


## Administrator Mode

When "administrator mode" is enabled, `<32 byte RC cell type ID>` must be present. The RC cell type ID contains the type script hash used by a special
cell with the same format as [RCE Cell](https://talk.nervos.org/t/rfc-regulation-compliance-extension/5338). RC cell
follows a set of rules and contains whitelists and blacklists. These lists can be used in the [SMT proofs
scenarios](https://github.com/nervosnetwork/sparse-merkle-tree).

The RCE cells are organized in tree structure illustrated in the following diagram:

![RCE Cells](./rce_cells.png)


The above shows the 4 lists in total. The RC Cell type ID is pointed to the root of tree and represents 4 lists in
order. If the current `RCRule` uses blacklist, the `auth` identity in `omni_identity` (see below) must not be present in
the blacklist SMT tree. If the current `RCRule` uses whitelist, the `auth` identity in `omni_identity` must be present
in the whitelist SMT tree.

The RC cell has the following distinctions compared to RCE Cell:

* The cell used here contains auth identities, not lock script hashes.

* If the cell contains an RCRule structure, this structure must be in whitelist mode.

* If the cell contains an RCCellVec structure, there must be at least one RCRule structure using whitelists in the RCCellVec.

To make it easier for reference, we call this cell `RC AdminList Cell`. To make this mode more flexible, when no type
script hash is found in cell_deps, it continues searching input cells with the same type script hash. Once a cell is
found, it will be used as `RC AdminList Cell`.

If the administrator mode flag is on, Anyone-can-pay mode, Time-lock mode and Supply mode flag will be ignored even set.
That means both the administrator and the user can unlock the cell, but the administrator is not constrained by
timelock. The administrator can only unlock existing cells with Administrator mode on. It's still impossible to bypass
supply limitation or mint new tokens at will.

## Anyone-can-pay Mode

When anyone-can-pay mode is enabled, `<2 bytes minimum ckb/udt in ACP>` must be present. It follows the rules of
[anyone-can-pay
lock](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0026-anyone-can-pay/0026-anyone-can-pay.md). The `<1 byte
CKByte minimum>` and `<1 byte UDT minimum>` are present at the same time.

## Time-lock Mode

When time-lock mode is enabled, `<8 bytes since for time lock>` must be present. The
[check_since](https://github.com/nervosnetwork/ckb-system-scripts/blob/63c63e9c96887395fc6990908bcba95476d8aad1/c/common.h#L91)
is used. The input parameter since is obtained from `<8 bytes since for time lock>`.

## Supply Mode

When supply mode is enabled, `<32 bytes type script hash>` must be present. The cell data of info cell which is specified
by type script hash has the following data structure:

```
version (1 byte)
current supply (16 bytes, little endian number)
max supply (16 bytes, little endian number)
sUDT script hash (32 bytes, sUDT type script hash)
... (variable length, other data)
```

Currently, the version is 0. Only the current supply field can be updated during transactions. The script iterates all
input and output cells, accumulating input amounts and output amounts identified by sUDT script hash. Then the script
verifies:

```
<issued amount> = <output amount> - <input amount>
<output current supply> = <issued amount> + <input current supply>
```
and
```
<output current supply> <= <max supply>
```

All the modes mentioned above can co-exist in Omnilock args in memory layout.

## Omnilock Witness

When unlocking an Omnilock, the corresponding witness must be a proper `WitnessArgs` data structure in molecule format. In
the lock field of the `WitnessArgs`, an `OmniLockWitnessLock` structure must be present as follows:
```
import xudt_rce;

array Auth[byte; 21];

table Identity {
    identity: Auth,
    proofs: SmtProofEntryVec,
}
option IdentityOpt (Identity);

// the data structure used in lock field of witness
table OmniLockWitnessLock {
    signature: BytesOpt,
    omni_identity: IdentityOpt,
    preimage: BytesOpt,
}
```

When `omni_identity` is present, it will be validated whether the provided auth in `omni_identity` is present in RC
AdminList Cell associated with the current lock script via SMT validation rules. In this case, the auth included in
`omni_identity` will be used in further validation.

If `omni_identity` is missing, the auth included in lock script args will then be used in further validation.

Once the processing above is successfully done and the auth to be used is confirmed, the flag in the designated auth
will be checked for the succeeding operations:

* When the auth flag is 0x0, a signature must be present in `OmniLockWitnessLock`. We will use the signature for secp256k1
  recoverable signature verification. The recovered public key hash using the blake160 algorithm must match the current
  auth content.

* When the auth flag is 0xFC, we will check against the current transaction, and there must be an input cell, whose lock
  script matches the auth content when hashed via blake160.


When `signature` is present, the signature can be used to unlock the cell in anyone-can-pay mode.

When `preimage` is present, if auth flag is:
* 0xFD (exec): the preimage's memory layout will be as follows:
```
exec code hash (32 bytes)
exec hash type (1 byte)
place (1 byte)
bounds (8 bytes)
pubkey hash (20 bytes)
```
Firstly, message, signature, pubkey hash are encoded into hex strings suggested by [Ideas on chained
locks](https://talk.nervos.org/t/ideas-on-chained-locks/5887). Then these strings are passed in as arguments in
[ckb_exec](https://github.com/nervosnetwork/rfcs/pull/237/files). The code finally returned is the same as ckb_exec.

* 0xFE (dynamic linking), the preimage's memory layout will be as follows:
```
dynamic library code hash (32 bytes)
dynamic library hash type (1 byte)
pubkey hash （20 bytes)
```

It loads the dynamic linking libraries of code hash and hash type, and gets the entry function of
[validate_signature](https://talk.nervos.org/t/rfc-swappable-signature-verification-protocol-spec/4802). Then it calls
the entry function to validate the message and signature. The auth returned from the entry function is compared with the
blake160 hash of the pubkey. If they are the same, then validation succeeds.

## Examples

### Unlock via owner's public key hash
```
CellDeps:
    <vec> Omnilock Script Cell
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0x0> <pubkey hash 1> <Omnilock flags: 0>
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <valid secp256k1 signature for pubkey hash 1>
        omni_identity: <...>
        preimage: <...>
      <...>
```

### Unlock via owner's lock script hash

```
CellDeps:
    <vec> Omnilock Script Cell
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0xFC> <lock hash: 0x1234> <Omnilock flags: 0>
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock: blake160 for this lock script must be 0x1234
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <...>
        omni_identity: <...>
        preimage: <...>
      <...>
```

### Unlock via administrator's public key hash

```
CellDeps:
    <vec> Omnilock Script Cell
    <vec> RC AdminList Cell 1
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0x0> <pubkey hash 1> <Omnilock flags: 1> <RC AdminList Cell 1's type ID>
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <valid secp256k1 signature for pubkey hash 2>
        omni_identity:
           identity: <flag: 0x0> <pubkey hash 2>
           proofs: <SMT proofs for the above identity in RC AdminList Cell 1>
        preimage: <...>
      <...>
```
### Unlock via administrator's lock script hash (1)
Note: the location of RC AdminList Cell 1 is in cell deps

```
CellDeps:
    <vec> Omnilock Script Cell
    <vec> RC AdminList Cell 1
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0> <pubkey hash 1> <Omnilock flags: 1> <RC AdminList Cell 1's type ID>
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock: blake160 for this lock script must be 0x1234
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <...>
        omni_identity:
           identity: <flag: 0xFC> <lock hash: 0x1234>
           proofs: <SMT proofs for the above identity in RC AdminList Cell 1>
        preimage: <...>
      <...>
```

### Unlock via administrator's lock script hash (2)
Note: the location of RC AdminList Cell 1 is in input cell

```
CellDeps:
    <vec> Omnilock Script Cell

Inputs:
    <vec> RC AdminList Cell 1
        Data: <RCData, union of RCCellVec and RCRule>
        Type: <its hash is same to RC AdminList Cell 1's type ID>
        Lock: <...>
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0> <pubkey hash 1> <Omnilock flags: 1> <RC AdminList Cell 1's type ID>
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock: blake160 for this lock script must be 0x1234
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <...>
        omni_identity:
           identity: <flag: 0xFC> <lock hash: 0x1234>
           proofs: <SMT proofs for the above identity in RC AdminList Cell 1>
        preimage: <...>
      <...>
```

### Unlock via anyone-can-pay

```
CellDeps:
    <vec> Omnilock Script Cell
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0x0> <pubkey hash 1> <Omnilock flags: 2> <2 bytes minimun ckb/udt in ACP>
    <...>
    follow anyone-can-pay rules
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <...>
        omni_identity: <...>
        preimage: <...>
      <...>
```

### Unlock via dynamic linking

```
COPY
CellDeps:
    <vec> Omnilock Script Cell
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0xFE> <preimage hash> <Omnilock flags: 0>
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <valid secp256k1 signature for pubkey hash 1>
        omni_identity: <...>
        preimage: <code hash> <hash type> <pubkey hash 1>
      <...>
```

### Unlock via exec
```
COPY
CellDeps:
    <vec> Omnilock Script Cell
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0xFD> <preimage hash> <Omnilock flags: 0>
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <valid secp256k1 signature for pubkey hash 1>
        omni_identity: <...>
        preimage: <code hash> <hash type> <place> <bounds> <pubkey hash 1>
      <...>
```

### Unlock via owner's public key hash with time lock limit
```
CellDeps:
    <vec> Omnilock Script Cell
Inputs:
    <vec> Cell
        Data: <...>
        Type: <...>
        Lock:
            code_hash: Omnilock
            args: <flag: 0x0> <pubkey hash 1> <Omnilock flags: 4> <since 1>
    <...>
Outputs:
    <vec> Any cell
Witnesses:
    WitnessArgs structure:
      Lock:
        signature: <valid secp256k1 signature for pubkey hash 1>
        omni_identity: <...>
        preimage: <...>
      <...>
```


## Notes

An [implementation](https://github.com/nervosnetwork/ckb-production-scripts/blob/master/c/omni_lock.c) of the Omnilock spec above has been deployed to Mirana CKB mainnet and  Pudge testnet:


- Mirana

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | TODO   |
| `hash_type` | `type`                                                               |
| `tx_hash`   | TODO   |
| `index`     | `0x0`                                                                |
| `dep_type`  | `code`                                                               |

- Pudge

| parameter   | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| `code_hash` | 0xf329effd1c475a2978453c8600e1eaf0bc2087ee093c3ee64cc96ec6847752cb   |
| `hash_type` | `type`                                                               |
| `tx_hash`   | 0x27b62d8be8ed80b9f56ee0fe41355becdb6f6a40aeba82d3900434f43b1c8b60   |
| `index`     | `0x0`                                                                |
| `dep_type`  | `code`                                                               |


Reproducible build is supported to verify the deploy script. To build the deployed the script above, one can use the following steps:

```bash
$ git clone https://github.com/nervosnetwork/ckb-production-scripts
$ cd ckb-production-scripts
$ git checkout 716433e
$ git submodule update --init --recursive
$ make all-via-docker
```

A draft of this specification has already been released, reviewed, and discussed in the community at [here](https://blog.cryptape.com/omnilock-a-universal-lock-that-powers-interoperability-1) for quite some time.
