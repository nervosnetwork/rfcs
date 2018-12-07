# Data order example 

## Schema

```
table Monster {
  name: string;
  stat: Stat;
  loots: [Item];
}

table Stat {
  hp: uint32;
  mp: uint32;
}

table Item {
  name: string;
}

root_type Monster;
```

## Data

```json
{
  "name": "Slime",
  "stat": {
    "hp": 100,
    "mp": 0
  },
  "loots": [
    { "name": "potion" },
    { "name": "gold" }
  ]
}
```

## Encoded binary

Depth first order:

- `monster`
- `name`
- `stat`
- `loots`
- `loots[0]`
- `loots[0].name`
- `loots[1]`
- `loots[1].name`

```text
header:
    0x00 10 00 00 00 ; monster starts at offset 0x10

vtable of monster:
    0x04 0a 00       ; vtable length = 10 bytes
    0x06 10 00       ; table length = 16 bytes
    0x08 04 00       ; field name: +0x04
    0x0a 08 00       ; field stat: +0x08
    0x0c 0c 00       ; field loots: +0x0c

    0x0e 00 00       ; padding
monster:
    0x10 0c 00 00 00 ; vtable offset: 0x10 - 0x0c = 0x04
    0x14 0c 00 00 00 ; name: 0x14 + 0x0c = 0x20
    0x18 18 00 00 00 ; stat: 0x18 + 0x18 = 0x30
    0x1c 1c 00 00 00 ; loots: 0x1c + 0x1c = 0x38

monster.name:
    0x20 05 00 00 00 ; length = 5
    0x24 53 6c 69 6d ; "Slim"
    0x28 65 00       ; "e\0"

vtable of stat, loots[1], loots[2]
    0x2a 06 00       ; vtable length = 6 bytes
    0x2c 08 00       ; table length = 8 bytes
    0x2e 04 00       ; field name/hp: +0x04

stat:
    0x30 06 00 00 00 ; vtable offset: 0x30 - 0x06 = 0x2a
    0x34 64 00 00 00 ; hp = 100

loots:
    0x38 02 00 00 00 ; length = 2
    0x3c 08 00 00 00 ; loots[0]: 0x3c + 0x08 = 0x44
    0x40 18 00 00 00 ; loots[1]: 0x40 + 0x18 = 0x58

loots[0]:
    0x44 1a 00 00 00 ; 0x44 - 0x1a = 0x2a
    0x48 04 00 00 00 ; name: 0x48 + 0x04 = 0x4c

loogs[0].name:
    0x4c 06 00 00 00 ; length = 6
    0x50 70 6f 74 69 ; "poti"
    0x54 6f 6e 00    ; "on\0"

    0x57 00          ; padding
loots[1]:
    0x58 2e 00 00 00 ; 0x58 - 0x2e = 0x2a
    0x5c 04 00 00 00 ; name: 0x5c + 0x04 = 0x60

loots[1].name:
    0x60 04 00 00 00 ; length = 4
    0x64 67 6f 6c 64 ; "gold"
    0x68 00          ; "\0"
```

