# Table fields order example

## Schema

```
table Ok {
  value: uint32;
}
table Err {
  reason: string;
}
union Result { Ok, Err }

enum Color : byte { Red, Green, Blue }

struct Complex {
  a: uint64;
  b: uint64;
}

table T {
  a_ubyte: ubyte;
  complex: Complex;
  a_uint32: uint32;
  result: Result;
  a_uint64: uint64;
  uint16_array: [uint16];
  color: Color;
}

root_type T;
```

## Data

```json
{
  "a_ubyte": 5,
  "complex": { "a": 1, "b": 2 },
  "a_uint32": 4,
  "result_type": "Ok",
  "result": { "value": 6 },
  "a_uint64": 3,
  "uint16_array": [ 7, 8 ],
  "color": "Blue"
}
```

## Encoded binary

Following is the list of all the fields annotated with the alignment
requirements, and union fields are split into two fields in place. Because
`result` reference and `uint16_array` are all offsets into standalone components,
so their alignments are all 4.

- `a_ubyte`: alignment 1
- `complex`: alignment 16.
- `a_uint32`: alignment 4
- `result` type: alignment 1
- `result` reference: alignment 4
- `a_uint64`: alignment 8
- `uint16_array`: alignment 4
- `color`: alignment 1

Here is the order after sorting by alignment:

- `complex`: field offset 0x04, alignment 16
- `a_uint64`: field offset 0x14, alignment 8
- `a_uint32`: field offset 0x1c, alignment 4
- `result` reference: field offset 0x20, alignment 4
- `uint16_array`: field offset 0x24, alignment 4
- `a_ubyte`: field offset 0x28, alignment 1
- `result` type: field offset 0x29, type: alignment 1
- `color`: field offset 0x2a, alignment 1

```
header:
    0x00 1c 00 00 00 ;

vtable:
    0x04 14 00       ; vtable length = 20 bytes
    0x06 2b 00       ; table length = 43 bytes
    0x08 28 00       ; a_ubyte
    0x0a 04 00       ; complex
    0x0c 1c 00       ; a_uint32
    0x0e 29 00       ; result type
    0x10 20 00       ; result
    0x12 14 00       ; a_uint64
    0x14 24 00       ; uint16_array
    0x16 2a 00       ; color
    
    0x18 00 00 00 00 ; padding
root table:
    0x1c 18 00 00 00 ; vtable offset: 0x1c - 0x18 = 0x04
    0x20 01 00 00 00 00 00 00 00 ; complex.a = 1
    0x28 02 00 00 00 00 00 00 00 ; complex.b = 2
    0x30 03 00 00 00 00 00 00 00 ; a_uint64 = 3
    0x38 04 00 00 00 ; a_uint32 = 4
    0x3c 14 00 00 00 ; result offset: 0x3c + 0x14 = 0x50
    0x40 18 00 00 00 ; uint16_array offset: 0x40 + 0x18 = 0x58
    0x44 05          ; a_ubyte = 5
    0x45 01          ; result type = Ok
    0x46 02          ; color = Blue
    
    0x47 00          ; padding
vtable for result:
    0x48 06 00       ; vtable length = 6 bytes
    0x4a 08 00       ; table length = 8 bytes
    0x4c 04 00       ; value
    
    0x4e 00 00       ; padding
result:
    0x50 08 00 00 00 ; vtable offset: 0x50 - 0x08 = 0x48
    0x54 06 00 00 00 ; value = 6
    
uint16_array:
    0x58 02 00 00 00 ; length = 2
    0x5c 07 00       ; uint16_array = [ 1,
    0x5e 08 00       ;                  2 ]
```
