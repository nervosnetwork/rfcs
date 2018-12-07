# Data alignment example 

## Schema

```
table T1 {
  f1: uint64;
  s1: [ubyte];
  f2: T2;
  s2: [ubyte];
  f3: [uint64];
  s3: [ubyte];
  f4: string;
}

table T2 {
  f1: ubyte;
}

root_type T1;
```

## Data

```json
{
  "f1": 100,
  "s1": [ 80 ],
  "f2": { "f1": 2 },
  "s2": [ 1, 2, 3, 4, 5 ],
  "f3": [ 101 ],
  "s3": [ 96 ],
  "f4": "a"
}
```

## Encoded binary

```text
header:
    0x00 1c 00 00 00 ; t1 starts at offset 0x1c

vtable of t1:
    0x04 12 00       ; vtable length = 18 bytes
    0x06 24 00       ; table length = 36 bytes
    0x08 04 00       ; f1
    0x0a 0c 00       ; s1
    0x0c 10 00       ; f2
    0x0e 14 00       ; s2
    0x10 18 00       ; f3
    0x12 1c 00       ; s3
    0x14 20 00       ; f4

padding:
    0x16 00 00 00 00 ; 6 bytes padding, because t1.f1 must align
    0x1a 00 00       ; to multiple of 8
    
t1:
    0x1c 18 00 00 00 ; vtable offset: 0x1c - 0x18 = 0x04
    0x20 64 00 00 00 ; f1 = 100
    0x24 00 00 00 00 ; f1 cont.
    0x28 18 00 00 00 ; s1: 0x28 + 0x18 = 0x40
    0x2c 20 00 00 00 ; f2: 0x2c + 0x20 = 0x4c
    0x30 24 00 00 00 ; s2: 0x30 + 0x24 = 0x54
    0x34 30 00 00 00 ; f3: 0x34 + 0x30 = 0x64
    0x38 38 00 00 00 ; s3: 0x38 + 0x38 = 0x70
    0x3c 3c 00 00 00 ; f4: 0x3c + 0x3c = 0x78

t1.s1:
    0x40 01 00 00 00 ; length = 1
    0x44 50          ; s1 = [ 80 ]
    
padding:
    0x45 00          ; 1 byte padding, vtable must align to multiple of 2

vtable of t1.f2:
    0x46 06 00       ; vtable length = 6 bytes
    0x48 05 00       ; table length = 5 bytes
    0x4a 04 00       ; t1.f2.f1

t1.f2:
    0x4c 06 00 00 00 ; vtable offset: 0x4c - 0x06 = 0x46
    0x50 02          ; t1.f2.f1 = 2

padding:
    0x51 00 00 00    ; 3 bytes padding ensure the vector length
                     ; is multiple of 4
    
t1.s2:
    0x54 05 00 00 00 ; length = 5
    0x58 01 02 03 04 ; s2 = [ 1, 2, 3, 4,
    0x5c 05          ;        5 ]
    
padding:
    0x5d 00 00 00    ; 7 bytes padding, because f3 elements must align
    0x60 00 00 00 00 ; to multiple of 8

t1.f3:
    0x64 01 00 00 00 ; length = 1
    0x68 65 00 00 00 ; f3 = [ 65 ]
    0x6c 00 00 00 00 ;

t1.s3:
    0x70 01 00 00 00 ; length = 1
    0x74 60          ; s3 = [ 96 ]
    
padding:
    0x75 00 00 00    ; string length must align to multiple of 4

t1.f4:
    0x78 01 00 00 00 ; length = 1
    0x7c 61 00       ; "a\0"
```
