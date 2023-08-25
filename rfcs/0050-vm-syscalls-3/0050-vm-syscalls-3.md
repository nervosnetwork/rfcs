---
Number: "0050"
Category: Standards Track
Status: Draft
Author: Xu Jiandong <lynndon@gmail.com>, Dingwei Zhang <zhangsoledad@gmail.com>
Created: 2023-04-17
---

# VM Syscalls 3

## Abstract

This document describes the addition of the syscalls during the CKB2023. This update significantly enhances the flexibility of CKB Script.

The following four syscalls are added:

- [Spawn]
- [Get Memory Limit]
- [Current Memory]
- [Set Content]
- [Load Block Extension]

### Spawn
[Spawn]: #spawn

The syscall Spawn is the core part of this update. The *Spawn* and the latter two syscalls: *Get Memory Limit* and *Set Content* together, implement a way to call another CKB Script in a CKB Script. Unlike the *Exec*[1](../0034-vm-syscalls-2/0034-vm-syscalls-2.md) syscall, *Spawn* saves the execution context of the current script, like [posix_spawn](https://man7.org/linux/man-pages/man3/posix_spawn.3.html), the parent script blocks until the child script ends.


```c
typedef struct spawn_args_t {
  uint64_t memory_limit;
  int8_t* exit_code;
  uint8_t* content;
  uint64_t* content_length;
} spawn_args_t;

int ckb_spawn(size_t index, size_t source, size_t bounds,
              int argc, char* argv[], spawn_args_t* spgs);
```

The arguments used here are:

- `index`: an index value denoting the index of entries to read.
- `source`: a flag denoting the source of cells to locate, possible values include:
    - 1: input cells.
    - `0x0100000000000001`: input cells with the same running script as current script
    - 2: output cells.
    - `0x0100000000000002`: output cells with the same running script as current script
    - 3: dep cells.
- `bounds`: high 32 bits means `offset`, low 32 bits means `length`. If `length` equals to zero, it read to end instead of reading 0 bytes.
- `argc`: argc contains the number of arguments passed to the program
- `argv`: argv is a one-dimensional array of strings
- `memory_limit`: an integer value denoting the memory size to use(Not including descendant children scripts), possible values include:
    - 1 (0.5 M)
    - 2 (1 M)
    - 3 (1.5 M)
    - 4 (2 M)
    - 5 (2.5 M)
    - 6 (3 M)
    - 7 (3.5 M)
    - 8 (4 M)
- `exit_code`: an int8 pointer denoting where we save the exit code of a child script.
- `content`: a pointer to a buffer in VM memory space denoting where we would load the sub-script data. The child script will write data in this buffer via `set_content`.
- `content_length`: a pointer to a 64-bit unsigned integer in VM memory space. When calling the syscall, this memory location should store the length of the buffer specified by `content`. When returning from the syscall, CKB VM would fill in `content_length` with the actual length of the buffer. `content_length` up to 256K.

The arguments used here `index`, `source`, `bounds`, `argc` and `argv` follow the usage described in [EXEC].

This syscall might return the following results:

- 0: Success.
- 1-3: Reserved. These values are already assigned to other syscalls.
- 4: Elf format error
- 5: Exceeded max content length.
- 6: Wrong memory limit
- 7: Exceeded max peak memory

Note that now we have a new limit called *Peak Memory Usage*. The maximum memory usage of the parent script and its descendant children cannot exceed this value. Currently, this limit is set at 32M.

Unlike cycles which always increase, the current memory can decrease or increase. When a child script is returned, the occupied memory is freed. This makes current memory usage lower.


### Get Memory Limit
[Get Memory Limit]: #get-memory-limit

Get the maximum available memory for the current script.

```c
int ckb_get_memory_limit();
```

For the script(prime script) directly invoked by CKB, it will always return 8(4M). For the child script invoked by prime script or other child script, it depends on the parameters set by *Spawn*.

### Current Memory
[Current Memory]: #current-memory

Get the Current Memory Usage. The result is the sum of the memory usage of the parent script and the child script.

```c
int ckb_current_memory();
```

The system call returns an integer. Multiply it by 0.5 to get the actual memory usage (unit: megabytes)

### Set Content
[Set Content]: #set-content

The child script can return bytes data to the parent script through `Set Content`.

```c
int ckb_set_content(uint8_t* content, uint64_t* length);
```

- Length up to 256K.
- If the written length is greater than the limit given by *Spawn*, the final written length is the minimum of the two.
- This function is optional. Not every child script needs to call this.

### Spawn example

Consider the creation of a dependency library with a straightforward function that receives parameters, concatenates them, and subsequently returns the resulting string to the caller.

**lib_strcat.c**

```c
#include <stdint.h>
#include <string.h>

#include "ckb_syscalls.h"

int main(int argc, char *argv[]) {
  char content[80];
  for (int i = 0; i < argc; i++) {
    strcat(content, argv[i]);
  }
  uint64_t content_size = (uint64_t)strlen(content);
  ckb_set_content(&content[0], &content_size);
  if (content_size != (uint64_t)strlen(content)) {
    return 1;
  }
  return 0;
}
```

We can call this dependent library in the prime script. The prime script passes in two parameters "hello", "world" and checks if the return value is equal to "helloworld”:

**prime.c**

```c
#include <stdint.h>
#include <string.h>

#include "ckb_syscalls.h"

int main() {
  const char *argv[] = {"hello", "world"};

  int8_t       spgs_exit_code = 255;
  uint8_t      spgs_content[80] = {};
  uint64_t     spgs_content_length = 80;
  spawn_args_t spgs = {
    .memory_limit = 8,
    .exit_code = &spgs_exit_code,
    .content = &spgs_content[0],
    .content_length = &spgs_content_length,
  };

  ckb_spawn(1, 3, 0, 2, argv, &spgs);
  if (strlen(spgs_content) != 10) {
    return 1;
  }
  if (strcmp(spgs_content, "helloworld") != 0) {
    return 1;
  }
  if (spgs_exit_code != 0) {
    return 1;
  }
  return 0;
}
```

### Load Block Extension
[Load Block Extension]: #load-block-extension

*Load Block Extension* syscall has a signature like the following:

```c
int ckb_load_block_extension(void* addr, uint64_t* len, size_t offset, size_t index, size_t source)
{
  return syscall(2104, addr, len, offset, index, source, 0);
}
```

The arguments used here are:

* `addr`, `len` and `offset` follow the usage described in [Partial Loading] section.
* `index`: an index value denoting the index of entries to read.
* `source`: a flag denoting the source of cells to locate, possible values include:
    + 1: input cells.
    + `0x0100000000000001`: input cells with the same running script as current script
    + 3: dep cells.
    + 4: header deps.

This syscall would locate the `extension` field associated either with an input cell, a dep cell, or a header dep based on `source` and `index` value, then use the same step as documented in [Partial Loading] section to feed the serialized value into VM.

Note when you are loading the `extension` associated with an input cell or a dep cell, the header hash of the corresponding block should still be included in `header deps` section of the current transaction.

This syscall might return the following errors:
* An invalid source value would immediately trigger an VM error and halt execution.
* The syscall would return with `1` as return value if the index value is out of bound.
* This syscall would return with `2` as return value if requesting a header for an input cell, but the `header deps` section is missing the header hash for the input cell.

In case of errors, `addr` and `index` will not contain meaningful data to use.

[EXEC]: ../0034-vm-syscalls-2/0034-vm-syscalls-2.md#exec
[Partial Loading]: ../0009-vm-syscalls/0009-vm-syscalls.md#partial-loading
