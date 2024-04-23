---
Number: "0052"
Category: Standards Track
Status: Proposal
Author: Xuejie Xiao <xxuejie@gmail.com>, Xu Jiandong <lynndon@gmail.com>
Created: 2024-01-09
---


# Extensible UDT

Extensible UDT(xUDT) is an extension of [Simple
UDT](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0025-simple-udt/0025-simple-udt.md) for
defining more behaviors a UDT might need. While simple UDT provides a minimal
core for issuing UDTs on Nervos CKB, extensible UDT builds on top of simple UDT
for more potential needs, such as regulations.

## **Data Structure**

**xUDT Cell**

An xUDT cell is backward compatible with Simple UDT, all the existing rules
defined in the Simple UDT spec must still hold true for xUDT cells. On top of
sUDT, xUDT extends a cell like the following:

```yaml
data:
    <amount: uint128> <xUDT data>
type:
    code_hash: xUDT type script
    args: <owner lock script hash> <xUDT args>
lock:
    <user_defined>
```

The added `xUDT args` and `xUDT data` parts provide all the new functions needed
by xUDT, the detailed structure is explained below.

### **xUDT Args**

xUDT args has the following structure:

```
<4-byte xUDT flags> <Variable length bytes, extension data>
```

Depending on the content of `flags`, different extension data might be attached:

• If `flags & 0x1FFFFFFF` is 0, no extension data is required. Note a
backward-compatible way of viewing things, which is that a plain sUDT cell also
has a hidden `flags` field with all zeros.

• If `flags & 0x1FFFFFFF` is 0x1, extension data will contain a
[molecule](https://github.com/nervosnetwork/molecule) serialized `ScriptVec`
structure:

```
table Script {
    code_hash:      Byte32,
    hash_type:      byte,
    args:           Bytes,
}

vector ScriptVec <Script>
```

Each entry included in `ScriptVec` structure is interpreted as
an extension script with additional behaviors. When an xUDT script is
executed, it will run through each included extension script. Only when all
extension scripts pass validation, will xUDT also consider the validation to be
successful.

An extension script can be loaded in any of the following ways:

1. Some extension logics might have a predefined hash, for example, we can
   use `0x0000 ... 0001` to represent regulation extension. The actual code for
   such scripts can be embedded in xUDT script itself.
2. If an input cell in the current transaction uses a lock script with the same
   script hash as the current extension script, we can consider the extension
   script to be validated already.
3. If an extension script does not match any of the above criteria, xUDT will
   use the code_hash and hash_type included in the extension script to
   invoke [ckb_dlopen2](https://github.com/nervosnetwork/ckb-c-stdlib/blob/37eba3102100808ffc6fa2383bcf9e1e2651c8ea/ckb_dlfcn.h#L108-L113) function,
   hoping to load a dynamically linked script from cell deps in the current
   transaction. If a script can be located successfully, xUDT will then look for
   an exported function with the following signature:

```c
int validate(int is_owner_mode, size_t extension_index, const uint8_t* args, size_t args_length);
```

`is_owner_mode` indicates if the current xUDT is unlocked via owner mode(as
described by sUDT), `extension_index` refers to the index of the current
extension in the `ScriptVec` structure. `args` and `args_length` are set to the
script args included in `Script` structure of the current extension script.

If this function returns 0, the current extension script validation is
considered successful.

• If `flags & 0x1FFFFFFF` is 0x2, extension data will contain the blake160 hash
of the `ScriptVec` structure as explained in the previous section. The
actual `extension_scripts` (`ScriptVec`) structure data will be included in a
witness field `input_type` or `output_type` contained in the current
transaction. We will explain this part below. Choosing `input_type` or
`output_type` depends on whether the type script is running on input or output
cells. Under a lot of scenarios, it is `input_type`. But in the following example “Owner
Mode Without Consuming Cell”, we can see it’s possible on `output_type`.

### xUDT Witness

The `input_type` or `output_type` field in witness has the following data
structure in molecule format:

```js
table XudtWitness {
    owner_script: ScriptOpt,		
    owner_signature: BytesOpt,
    extension_scripts: ScriptVecOpt,
    extension_data: BytesVec,
}
```

The field `owner_script` and `owner_signature` will be used in owner mode. The
field `extension_scripts` is used when `flags & 0x1FFFFFFF` is 0x2 in args.

The length of `extension_data` structure inside must also be the same as
`ScriptVec` in `xUDT args` or `extension_scripts`. An extension script might also
require transaction-specific data for validation. The witness here provides a
place for these data needs.

### Owner Mode Update

As described in RFC sUDT, if an input cell in the current transaction uses an
input lock script with the same script hash as the owner lock script hash, the
`is_owner_mode` will be set to true. In xUDT, this rule is updated by the
following rule:

If an input or output cell in the current transaction uses one or more of the
following:

- input lock script (when `flags & 0x20000000` is **zero** or `flags` is not present)
- output type script (when `flags & 0x40000000` is **non-zero**)
- input type script (when `flags & 0x80000000` is **non-zero**)

With the same script hash as the owner lock script hash, the `is_owner_mode`
will be set to true. The output lock scripts are not included, because they
won’t be run in a transaction.

If the `owner_script` in witness isn’t none and its blake2b hash is the same as
the owner lock script hash in `args`, this script will be run as an extension
script. If the script returns success, `is_owner_mode` is set to true. Note, the
`owner_signature` field can be used by this owner script. When tokens are
minted, the `owner_script` and `owner_signature` can be set to some proper
values. When tokens are transferred, they can be set to none.

### **xUDT Data**

xUDT data is a molecule serialized `XudtData` structure:

```
vector Bytes <byte>
vector BytesVec <Bytes>

table XudtData {
  lock: Bytes,
  data: BytesVec,
}
```

The `data` field included in `XudtData`, must be of the same length
as `ScriptVec` structure included in xUDT args. Some extensions might require
user-specific data stored in each xUDT cell. xUDT data provides a place for such
data. The `XudtData` can be optional regardless of whether there is any extension
script or not. However, if an extension script requires such data, it must be
present.

The `lock` field included in `XudtData` will not be used by the xUDT script. It
is reserved for lock script specific data for current cells.

An extension script should first locate the index it resides in xUDT
args, then look for the data for the current extension script at the same index
in `data` field of `XudtData` structure.

## **Operations**

xUDT uses the same governance operations as Simple UDT: an owner lock controls
all governance operations, such as minting.

A normal transfer operation of xUDT, however, differs from Simple UDT. Depending
on the flags used, there might be 2 usage patterns:

### **Raw Extension Script**

When `flags & 0x1FFFFFFF` are set to 0x1, raw extension data is included in xUDT args directly.

```yaml
Inputs:
    <vec> xUDT_Cell
        Data:
            <amount: uint128> <xUDT data>
        Type:
            code_hash: xUDT type script
            args: <owner lock script hash> <xUDT args>
        Lock:
            <user defined>
    <...>
Outputs:
    <vec> xUDT_Cell
        Data:
            <amount: uint128> <xUDT data>
        Type:
            code_hash: xUDT type script
            args: <owner lock script hash> <xUDT args>
        Lock:
            <user defined>
    <...>
Witnesses:
    WitnessArgs structure:
        Lock: <user defined>
        Input Type: <XudtWitness>
            owner_script: <None>
            owner_signature: <None>				
            extension_scripts: <None>
            extension_data: 
                <vec> BytesVec
                    <data> 
                <...>
```

The witness of the same index as the first input xUDT cell is located by xUDT script. It is parsed first as WitnessArgs structure, the `input_type` or `output_type` field of `WitnessArgs`, is thus treated as `XudtWitness` structure.

Note that each extension script is only executed once in the transaction. When multiple instances of the same extension script are included, each instance will execute independently for each inclusion. The extension script is responsible for checking all xUDT cells of the current type, ensuring each cell data and witness for the current extension script, can be validated against the extension script’s rules.

### **P2SH Style Extension Script**

When `flags & 0x1FFFFFFF` are set to 0x2, only the blake160 hash of extension data is included in xUDT args. The user is required to provide the actual extension data in witness directly:

```yaml
Inputs:
    <vec> xUDT_Cell
        Data:
            <amount: uint128> <xUDT data>
        Type:
            code_hash: xUDT type script
            args: <owner lock script hash> <xUDT args, hash of raw extension data>
        Lock:
            <user defined>
    <...>
Outputs:
    <vec> xUDT_Cell
        Data:
            <amount: uint128> <xUDT data>
        Type:
            code_hash: xUDT type script
            args: <owner lock script hash> <xUDT args, hash of raw extension data>
        Lock:
            <user defined>
    <...>
Witnesses:
    WitnessArgs structure:
        Lock: <user defined>
        Input Type: XudtWitness
            owner_script: <None>
            owner_signature: <None>				
            extension_scripts: 
                <vec> ScriptVec
                    <script>
                <...>
            extension_data: 
                <vec> BytesVec
                    <data>
                <...>
```

The only difference here is that `XudtWitness` in `input_type` or
`output_type` field in the corresponding WitnessArgs structure, contains raw
extension data in `ScriptVec` data structure, xUDT script must first validate
that the hash of raw extension data provide here, is the same as blake160 hash
included in xUDT args. After this, it uses the same logic as the previous
workflow.

### Owner Mode without Consuming Cell

As described above, If an input cell uses an input lock script with same script
hash as the owner lock script hash, the `is_owner_mode` will be set to true. It
isn’t convenient: this requires extra cell to be consumed. With `owner_script`
and `owner_signature` set to proper values, we can use owner mode without extra
cell.

```yaml
Inputs:
    <vec>
			<Any input cells>
    <...>
Outputs:
    <vec> xUDT_Cell
        Data:
            <amount: uint128> <xUDT data>
        Type:
            code_hash: xUDT type script
            args: <owner lock script hash 1> <xUDT args>
        Lock:
            <user defined>
    <...>
Witnesses:
    WitnessArgs structure:
        Lock: <user defined>
        Input Type: <None>
        Output Type: XudtWitness
            owner_script: <owner script 1>
            owner_signature: <signature 1>				
            extension_scripts: 
                <vec> ScriptVec
                    <script>
                <...>
            extension_data: 
                <vec> BytesVec
                    <data>
                <...>
```

The example above shows a scenario of owner mode without consuming the owner's
cell.  We can implement an extension script as `<owner script 1>` with signature
validation. The `<signature 1>` can be used by `<owner script 1>` to place
signature information.

## Deployment

An [implementation](https://github.com/nervosnetwork/ckb-production-scripts/blob/master/c/xudt_rce.c) of
the spec above has been deployed to Mirana CKB mainnet and Pudge testnet:

- Mirana(mainnet)

| parameter | value |
| --- | --- |
| code_hash | 0x50bd8d6680b8b9cf98b73f3c08faf8b2a21914311954118ad6609be6e78a1b95 |
| hash_type | data1 |
| tx_hash | 0xc07844ce21b38e4b071dd0e1ee3b0e27afd8d7532491327f39b786343f558ab7 |
| index | 0x0 |
| dep_type | code |

This script is not upgradeable due to zero lock (lock args with all zeros).
We have previously deployed scripts with the ability to be upgraded. However, we
consider this upgrading mechanism to be harmful as it compromises the
decentralization of the blockchain. With the ability to upgrade, it means that
the owners (whether it's several people or even just one person) of this cell
can upgrade it at any time. This gives one or several individuals complete
control over the assets associated with the deploy scripts. That's why we have
chosen to use a zero lock when deploying this script.


- Pudge(testnet)

| parameter | value |
| --- | --- |
| code_hash | 0x50bd8d6680b8b9cf98b73f3c08faf8b2a21914311954118ad6609be6e78a1b95 |
| hash_type | data1 |
| tx_hash | 0xbf6fb538763efec2a70a6a3dcb7242787087e1030c4e7d86585bc63a9d337f5f |
| index | 0x0 |
| dep_type | code |

A reproducible build is supported to verify the deploy script. To build the
deployed the script above, one can use the following steps:

```
$ git clone https://github.com/nervosnetwork/ckb-production-scripts
$ cd ckb-production-scripts
$ git checkout abdcb117b512e35910fa8e30241a7a354e5cacf0
$ git submodule update --init --recursive
$ make all-via-docker
```
