---
Number: "0008"
Category: Standards Track
Status: Proposal
Author: Boyu Yang
Organization: Nervos Foundation
Created: 2018-12-17
---

# Serialization

CKB uses two major serialization formats, [Molecule][molecule] and [JSON][json].

[Molecule][molecule] is a canonicalization and zero-copy serialization format.
[Molecule][molecule] is in the experimental stage, and we may make a few minor changes.

[JSON][json] is used in node RPC service via [JSON-RPC][jsonrpc].

## Molecule

### Summary

#### Fixed Size or Dynamic Size

| Type | byte  | array | struct | vector  |  table  | option  |  union  |
|------|-------|-------|--------|---------|---------|---------|---------|
| Size | Fixed | Fixed | Fixed  | Dynamic | Dynamic | Dynamic | Dynamic |

#### Memory Layout

```
|  Type  |                      Header                      |               Body                |
|--------+--------------------------------------------------+-----------------------------------|
| array  |                                                  |  item-0 |  item-1 | ... |  item-N |
| struct |                                                  | filed-0 | field-1 | ... | field-N |
| fixvec | items-count                                      |  item-0 |  item-1 | ... |  item-N |
| dynvec | full-size | offset-0 | offset-1 | ... | offset-N |  item-0 |  item-1 | ... |  item-N |
| table  | full-size | offset-0 | offset-1 | ... | offset-N | filed-0 | field-1 | ... | field-N |
| option |                                                  | item or none (zero bytes)         |
| union  | item-type-id                                     | item                              |
```

- All items in Header are 32 bit unsigned integers in little-endian.

### Primitive Type

#### `byte`

The `byte` is a byte.

##### Examples

`00` is a `byte`.

### Composite Types

#### `array`

The `array` is a fixed-size type: it has a fixed-size inner type and a fixed length.
The size of an `array` is the size of inner type times the length.

Serializing an `array` only need to serialize all items in it.

There's no overhead to serialize an `array`, which stores all items consecutively, without extra space between two adjacent items.

##### Examples

If we define `array Byte3 [byte; 3];`, and we want to store three bytes: first is `01`, the second is `02` and the last is `03`, then the serialized bytes will be `01 02 03`.

If we define `array Uint32 [byte; 4];` , and we want to store a 32 bit unsigned integer `0x01020304` into it in little-endian, then the serialized bytes will be `04 03 02 01`.

If we define `array TwoUint32 [Uint32; 2];`, and we want to store two 32 bit unsigned integers in little-endian: first is `0x01020304` and second is `0xabcde`, then the serialized bytes will be `04 03 02 01 de bc 0a 00`.

#### `struct`

The `struct` is a fixed-size type: all fields in `struct` are fixed-size and it has a fixed quantity of fields.
The size of a `struct` is the sum of all fields' size.

Serializing a `struct` only need to serialize all fields in it.
Fields in a `struct` are stored in the order they are declared.

There's no overhead to serialize a `struct`, which stores all fields consecutively, without extra space between two adjacent items.

##### Examples

If we define `struct OnlyAByte { f1: byte }`, and we want to store a byte `ab`, then the serialized bytes will be `ab`.

If we define `struct ByteAndUint32 { f1: byte, f2: Uint32 }`, and we want to store a byte `ab` and a 32 bit unsigned integer `0x010203` in little-endian, then the serialized bytes will be `ab 03 02 01 00`.

#### vectors

There two kinds of vectors: fixed vector `fixvec` and dynamic vector `dynvec`.

Whether a vector is fixed or dynamic depends on the type of its inner item: if the inner item is fixed-size, then it's a `fixvec`; otherwise, it's a `dynvec`.

Both of `fixvec` and `dynvec` are dynamic-size types.

##### `fixvec` - fixed vector

There are two steps of serializing a `fixvec`:
1. Serialize the length as a 32 bit unsigned integer in little-endian.
2. Serialize all items in it.

###### Examples

If we define `vector Bytes <byte>;`:
- the serialized bytes of an empty bytes is `00 00 00 00`(the length of any empty fixed vector is `0`).
- the serialized bytes of `0x12` is `01 00 00 00, 12`.
- the serialized bytes of `0x1234567890abcdef` is `08 00 00 00, 12 34 56 78 90 ab cd ef`.

If we define `vector Uint32Vec <Uint32>;`:
- the serialized bytes of an empty `Uint32Vec` is `00 00 00 00`.
- the serialized bytes of `0x123` is `01 00 00 00, 23 01 00 00`.
- the serialized bytes of `[0x123, 0x456, 0x7890, 0xa, 0xbc, 0xdef]` is
  ```
  # there are 6 items
  06 00 00 00
  # six items
  23 01 00 00, 56 04 00 00, 90 78 00 00, 0a 00 00 00, bc 00 00 00, ef 0d 00 00
  ```

##### `dynvec` - dynamic vector

There are three steps of serializing a `dynvec`:
1. Serialize the full size in bytes as a 32 bit unsigned integer in little-endian.
2. Serialize all offset of items as 32 bit unsigned integer in little-endian.
3. Serialize all items in it.

###### Examples

If we define `vector BytesVec <Bytes>;`:
- the serialized bytes of an empty `BytesVec`  is `04 00 00 00`(the full size of an empty dynamic vector is 4 bytes).
- the serialized bytes of `[0x1234]` is
  ```
  # the full size is 14 bytes
  0e 00 00 00
  # one offset
  08 00 00 00
  # one item
  02 00 00 00 12 34
  ```
- the serialized bytes of `[0x1234, 0x, 0x567, 0x89, 0xabcdef]` is
  ```
  # the full size is 52 (0x34) bytes
  34 00 00 00
  # five offsets (20 bytes in total)
  18 00 00 00, 1e 00 00 00, 22 00 00 00, 28 00 00 00, 2d 00 00 00
  # five items (28 bytes in total)
  02 00 00 00, 12 34
  00 00 00 00,
  02 00 00 00, 05 67
  01 00 00 00, 89
  03 00 00 00, ab cd ef
  ```

#### `table`

The `table` is a dynamic-size type. It can be considered as a `dynvec` but the length is fixed.

The serializing steps are same as `dynvec`:
1. Serialize the full size in bytes as a 32 bit unsigned integer in little-endian.
2. Serialize all offset of fields as 32 bit unsigned integer in little-endian.
3. Serialize all fields in it in the order they are declared.

##### Examples

If we define `table MixedType { f1: Bytes, f2: byte, f3: Uint32, f4: Byte3, f5: Bytes }`
- the serialized bytes of a `MixedType { f1: 0x, f2: 0xab, f3: 0x123, f4: 0x456789, f5: 0xabcdef }`  is
  ```
  # the full size is 43 (0x2b) bytes
  2b 00 00 00
  # five offsets (20 bytes in total)
  18 00 00 00, 1c 00 00 00, 1d 00 00 00, 21 00 00 00, 24 00 00 00
  # five items (19 bytes in total)
  00 00 00 00
  ab
  23 01 00 00
  45 67 89
  03 00 00 00, ab cd ef
  ```

#### `option`

The `option` is a dynamic-size type.

Serializing an `option` depends on whether it is empty or not:
- if it's empty, there is **zero** bytes (the size is `0`).
- if it's not empty, just serialize the inner item (the size is same as the inner item's size).

##### Examples

If we define `option BytesVecOpt (BytesVec);`
- the serialized bytes of `Option` is ` ` (empty).
- the serialized bytes of `Some([])` is `04 00 00 00`.
- the serialized bytes of `Some([0x])` is
  ```
  # the full size of BytesVec is 12 bytes
  0c 00 00 00
  # the offset of Bytes
  08 00 00 00
  # the length of Bytes
  00 00 00 00
  ```

#### `union`

The `union` is a dynamic-size type.

Serializing a `union` has two steps:
- Serialize a item type id in bytes as a 32 bit unsigned integer in little-endian.
  The item type id is the index of the inner items, and it's starting at 0.
- Serialize the inner item.

#### Examples

If we define `union HybridBytes { Byte3, Bytes, BytesVec, BytesVecOpt }`
- the serialized bytes of `Byte3 (0x123456)` is `00 00 00 00, 12 34 56`
- the serialized bytes of `Bytes (0x)` is `01 00 00 00, 00 00 00 00`
- the serialized bytes of `Bytes (0x123)` is `01 00 00 00, 02 00 00 00, 01 23`
- the serialized bytes of `BytesVec ([])` is `02 00 00 00, 04 00 00 00`
- the serialized bytes of `BytesVec ([0x])` is `02 00 00 00, 0c 00 00 00, 08 00 00 00, 00 00 00 00`
- the serialized bytes of `BytesVec ([0x123])` is `02 00 00 00, 0e 00 00 00, 08 00 00 00, 02 00 00 00, 01 23`
- the serialized bytes of `BytesVec ([0x123, 0x456])` is
  ```
  # Item Type Id
  02 00 00 00
  # the full size of BytesVec is 24 bytes
  18 00 00 00
  # two offsets of BytesVec (8 bytes in total)
  0c 00 00 00, 12 00 00 00,
  # two Bytes (12 bytes in total)
  02 00 00 00, 01 23
  02 00 00 00, 04 56
  ```
- the serialized bytes of `BytesVecOpt (None)` is `03 00 00 00`
- the serialized bytes of `BytesVecOpt (Some(([])))` is `03 00 00 00, 04 00 00 00`
- the serialized bytes of `BytesVecOpt (Some(([0x])))` is `03 00 00 00, 0c 00 00 00, 08 00 00 00, 00 00 00 00`
- the serialized bytes of `BytesVecOpt (Some(([0x123])))` is `03 00 00 00, 0e 00 00 00, 08 00 00 00, 02 00 00 00, 01 23`
- the serialized bytes of `BytesVecOpt (Some(([0x123, 0x456])))` is
  ```
  # Item Type Id
  03 00 00 00
  # the full size of BytesVec is 24 bytes
  18 00 00 00
  # two offsets of BytesVec (8 bytes in total)
  0c 00 00 00, 12 00 00 00,
  # two Bytes (12 bytes in total)
  02 00 00 00, 01 23
  02 00 00 00, 04 56
  ```

[molecule]: #molecule
[json]: https://www.json.org
[jsonrpc]: https://www.jsonrpc.org/specification
