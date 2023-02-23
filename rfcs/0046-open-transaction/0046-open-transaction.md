---
Number: "0046"
Category: Standards
Status: Proposal
Author: Ian Yang <@doitian>
Created: 2023-02-20
---

# CKB Open Transaction: An Extensible Transaction Format

## Synopsis

CKB Open Transaction is an extensible transaction format, which allows attaching any attribute to the transaction. It divides transaction construction into multiple small steps, each with a different modularised solution. A modular Open Transaction ecosystem could expand the possibilities for CKB DApps while lowering the barrier to development.

##  Wire Format

Molecule and JSON are two popular serialization protocols in the CKB ecosystem. This section will describe the format using Molecule schema and the Appendix will give the corresponding TypeScript definition.

An Open Transaction is a collection of `OtxMap`, and an `OtxMap` is a list of `OtxKeyPair`.

```mol
vector OtxMap <OtxKeyPair>;
```

An `OtxKeyPair` specifies the value for a key. The key part is a 32-bit unsigned integer (`key_type`) plus an optional `key_data`; and the value part is any binary data `value_data`. The `key_type` represents the type of the record. It determines how to encode `key_data` and `value_data`.

```mol
table OtxKeyPair {
    key_type: Uint32,
    key_data: BytesOpt,
    value_data: Bytes,
}
```

The CKB blockchain molecule schema has already defined `Uint32`, `BytesOpt` and `Bytes`.

```mol
// The `UintN` is used to store an `N` bits unsigned integer
// as a byte array in little-endian.
array Uint32 [byte; 4];
vector Bytes <byte>;
option BytesOpt (Bytes);
```

Any entity in a CKB transaction, including the cell dep, header dep, input, output, and witness, corresponds to an `OtxMap`. The Open Transaction organizes these maps into lists, it's easy to find the counter party of an entity by position. There's one exception: instead of keeping two lists for outputs and output data, the Open Transaction merges them into a single `outputs`  list. Finally, the `meta` map holds attributes global to the transaction.

```mol
table OpenTransaction {
    // Global attributes for the transaction
    meta: OtxMap,
    // cell_deps[i] is the attributes map for cell_deps[i] in the CKB transaction, same for header_deps, inputs, and witnesses
    cell_deps: OtxMapVec,
    header_deps: OtxMapVec,
    inputs: OtxMapVec,
    witnesses: OtxMapVec,
    // outputs[i] describes the attributes of outputs[i] and outputs_data[i] in the CKB transaction.
    outputs: OtxMapVec,
}
```

Appendix I gives the full schema definition in both Molecule and TypeScript.

## Key Types

There are two categories of key types defined in this RFC.

- The Essential Keys have one-to-one mappings to the CKB transaction fields.
- The Extra Keys do not relate to a CKB transaction field directly. They attach attributes to help construct the transaction.

This RFC follows the conventions below to allocate numbers. The Open Transaction protocol designers should carefully choose the key numbers to avoid conflicts. It's recommended to submit their own RFC proposals to reserve the key numbers.

- The Essential Keys reserve numbers from 0x00 to 0xFF.
- The Extra Keys will use the range 0x10000 to 0xFFFFF.
- The range from 0xF00000 and 0xFFFFFF are for private use by individuals and organizations.
- Numbers starting from 0x1000000 are reserved for future usage.

The different maps, for example, the input map and the output map, should not reuse the same key type number for different purposes. All the key types must be globally unique.

The transaction includes a key type on demand. The Open Transaction protocol participants must ignore unknown key types and leave them in place.

The key type number determines the format of the key data and value data. The transaction is invalid when key data and value data do not match the format.

All the types defined in this RFC use Molecule to serialize key data and value data using types below, all existing in the CKB molecule types.

```
// The `UintN` is used to store an `N` bits unsigned integer
// as a byte array in little-endian.
array Uint32 [byte; 4];
array Uint64 [byte; 8];

array Byte32 [byte; 32];

vector Bytes <byte>;

option BytesOpt (Bytes);
option ScriptOpt (Script);

table Script {
    code_hash:      Byte32,
    hash_type:      byte,
    args:           Bytes,
}
```

### Key Duplication

Two `OtxKeyPair`s have the duplicated keys if both `key_type` and `key_data` are identical. Any `OtxMap` should not contain key pairs with the duplicated keys, otherwise the open transaction is invalid.

## Essential Keys

Essential keys specify the value of the corresponding CKB fields directly.

The Open Transaction is completed if it has set all the CKB fields explicitly via essential keys.

If there are different ways to specify a CKB field, the keys are grouped into mutually exclusive sets. Keys in the distinct sets are conflict and should not co-exist in the map. If a key is present, all the keys in the same set must be present to make the Open Transaction complete.

In other words, the Open Transaction is completed if in any `OtxMap` that

1. All the essential keys not in an exclusive set exist.
2. At least one keys set in an exclusive group is present in the map. If the set contains multiple keys, all the keys must be present together.

It's straightforward to convert a completed Open Transaction to CKB Transaction. For an incomplete Open Transaction, use the default value listed below to fill the missing fields. If there are exclusive sets to set the field, use the default values of the keys in the primary set.

**Attention** that, `None` means the value is absent for an option type in Molecule.

### Meta Map Keys

| Name | key_type | key_data | value_data | default |
| --- | --- | --- | --- | --- |
| CKB Transaction Version | OTX_META_VERSION = 0x01 | None | Uint32 | 0 |

### Cell Dep Keys

| Name | key_type | key_data | value_data | default |
| --- | --- | --- | --- | --- |
| Out Point Tx Hash | OTX_CELL_DEP_OUTPOINT_TX_HASH = 0x02 | None | Byte32 | All zeros |
| Out Point Index | OTX_CELL_DEP_OUTPOINT_INDEX = 0x03 | None | Uint32 | 0xffffffff |
| Dep Type | OTX_CELL_DEP_TYPE = 0x04 | None | byte: 0 - Code, 1 - DepGroup, Other - Invalid | 0 |

### Header Dep Keys

| Name | key_type | key_data | value_data | default |
| --- | --- | --- | --- | --- |
| Header Dep Hash | OTX_HEADER_DEP_HASH = 0x05 | None | Byte32 | All zeros |

### Input Keys

| Name | key_type | key_data | value_data | default |
| --- | --- | --- | --- | --- |
| Previous Output Tx Hash | OTX_INPUT_OUTPOINT_TX_HASH = 0x06 | None | Byte32 | All zeros |
| Previous Output Index | OTX_INPUT_OUTPOINT_INDEX = 0x07 | None | Uint32 | 0xffffffff |
| Since | OTX_INPUT_SINCE = 0x08 | None | Uint64 | 0 |

### Witness Keys

| Name | key_type | key_data | value_data | default |
| --- | --- | --- | --- | --- |
| Witness | OTX_WITNESS_RAW = 0x09 | None | Bytes | 0x10000000100000001000000010000000 |
| Witness Args for Input Lock Script | OTX_WITNESS_INPUT_LOCK = 0x0A | None | None | BytesOpt | None |
| Witness Args for Input Type Script | OTX_WITNESS_INPUT_TYPE = 0x0B | None | None | BytesOpt | None |
| Witness Args for Output Type Script | OTX_WITNESS_OUTPUT_TYPE = 0x0C | None | None | BytesOpt | None |

The key `OTX_WITNESS_RAW` is exclusive with the keys set `OTX_WITNESS_INPUT_LOCK`, `OTX_WITNESS_INPUT_TYPE`, and `OTX_WITNESS_OUTPUT_TYPE`. `OTX_WITNESS_RAW` is the primary keys set in this exclusive group.

When `OTX_WITNESS_INPUT_LOCK`, `OTX_WITNESS_INPUT_TYPE`, or `OTX_WITNESS_OUTPUT_TYPE` exists, the witness is a serialized `WitnessArgs`. For example, if `OTX_WITNESS_INPUT_LOCK` is `0xFF`, and the other two are None, the witness is:

```jsx
WitnessArgs {
  lock: "0xFF",
  input_type: None,
  output_type: None,
}
```

### Output Keys

| Name | key_type | key_data | value_data | default |
| --- | --- | --- | --- | --- |
| Capacity | OTX_OUTPUT_CAPACITY = 0x0D | None | Uint64 | 0 |
| Lock Script Code Hash | OTX_OUTPUT_LOCK_CODE_HASH = 0x0E | None | Byte32 | All zeros |
| Lock Script Hash Type | OTX_OUTPUT_LOCK_HASH_TYPE = 0x0F | None | byte: see tx hash_type in [RFC32] | 0 |
| Lock Script Args | OTX_OUTPUT_LOCK_ARGS = 0x10 | None | Bytes | Empty |
| Type Script | OTX_OUTPUT_TYPE_SCRIPT = 0x11 | None | ScriptOpt | None |
| Type Script Code Hash | OTX_OUTPUT_TYPE_CODE_HASH = 0x12 | None | Byte32 | All zeros |
| Type Script Hash Type | OTX_OUTPUT_TYPE_HASH_TYPE = 0x13 | None | byte: see tx hash_type in [RFC32] | 0 |
| Type Script Args | OTX_OUTPUT_TYPE_ARGS = 0x14 | None | Bytes | Empty |
| Data | OTX_OUTPUT_DATA = 0x15 | None | Bytes | Empty |

The key `OTX_OUTPUT_TYPE_SCRIPT` is exclusive with the keys set `OTX_OUTPUT_TYPE_CODE_HASH`, `OTX_OUTPUT_TYPE_HASH_TYPE`, and `OTX_OUTPUT_TYPE_ARGS`. `OTX_OUTPUT_TYPE_SCRIPT` is the primary set in this exclusive group.

[RFC32]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0032-ckb-vm-version-selection/0032-ckb-vm-version-selection.md

## Extra Keys

The Extra Keys do not relate to a CKB transaction field directly. They attach attributes to help construct the transaction.

An Extra Key Group bundle several keys for a specific feature. It’s recommended to submit new proposals as RFCs to reserve the key numbers.

This RFC has defined three Extra Key groups, Versioning, Identifying, and Rejecting.

### Versioning (0x10000)

| Name | Scope | key_type | key_data | value_data |
| --- | --- | --- | --- | --- |
| Open Transaction Version | meta | OTX_VERSIONING_META_OPEN_TX_VERSION = 0x10000 | None | Uint32 |

It’s required and must set to 1.

### Identifying (0x10010)

Open Transaction hash and witness hash are meta map keys. They correspond to the transaction hash and the witness hash of the CKB transaction generated from the open transaction.

| Name | Scope | key_type | key_data | value_data |
| --- | --- | --- | --- | --- |
| Transaction Hash | meta | OTX_IDENTIFYING_META_TX_HASH = 0x10010 | None | Byte32 |
| Transaction Witness Hash | meta | OTX_IDENTIFYING_META_TX_WITNESS_HASH = 0x10011 | None | Byte32 |

When any of the fields are available, it must match the generated CKB transaction.

### Rejecting (0x10020)

| Name | Scope | key_type | key_data | value_data |
| --- | --- | --- | --- | --- |
| Rejecting Reason | meta | OTX_REJECTING_META_REASON = 0x10020 | Uint32, See below | Bytes |

The Rejecting Reason is a meta map key to show that the open transaction should be rejected.

The key data is the rejection code to differentiate different reasons.

- `0x00` verification failure
- `0x01` orphan inputs, dep cells or dep headers.
- `0x02` double spent conflict
- `0x03` timeout
- `0x04` to `0x7F` are reserved for future usage.
- `0x80` and above are for private use by individuals and organizations.

The value data MUST be a string encoded in UTF-8.

## Appendix I: Open Transaction Schema

### Molecule Schema

```mol
/// Types defined in CKB
// The `UintN` is used to store an `N` bits unsigned integer
// as a byte array in little-endian.
array Uint32 [byte; 4];
vector Bytes <byte>;
option BytesOpt (Bytes);

/// Types for Open Transaction
table OtxKeyPair {
    key_type: Uint32,
    key_data: BytesOpt,
    value_data: Bytes,
}

table OpenTransaction {
    // Global attributes for the transaction
    meta: OtxMap,
    // cell_deps[i] is the attributes map for cell_deps[i] in the CKB transaction, same for header_deps, inputs, and witnesses
    cell_deps: OtxMapVec,
    header_deps: OtxMapVec,
    inputs: OtxMapVec,
    witnesses: OtxMapVec,
    // outputs[i] describes the attributes of outputs[i] and outputs_data[i] in the CKB transaction.
    outputs: OtxMapVec,
}
```

### TypeScript Schema

```typescript
export type Uint32 = number
// Bytes serialized in hex, starting with 0x
export type Bytes = string
export interface OtxKeyPair {
    key_type: Uint32
    key_data?: Bytes
    value_data: Bytes
}
export type OtxMap = OtxKeyPair[]
export type OtxMapVec = OtxMap[]
export interface OpenTransaction {
    // Global attributes for the transaction
    meta: OtxMap,
    // cell_deps[i] is the attributes map for cell_deps[i] in the CKB transaction, same for header_deps, inputs, and witnesses
    cell_deps: OtxMapVec,
    header_deps: OtxMapVec,
    inputs: OtxMapVec,
    witnesses: OtxMapVec,
    // outputs[i] describes the attributes of outputs[i] and outputs_data[i] in the CKB transaction.
    outputs: OtxMapVec,
}
```
