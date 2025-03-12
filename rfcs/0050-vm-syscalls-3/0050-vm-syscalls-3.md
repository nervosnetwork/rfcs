---
Number: "0050"
Category: Standards Track
Status: Proposal
Author: Xuejie Xiao <xxuejie@gmail.com>, Jiandong Xu<lynndon@gmail.com>, Wanbiao Ye <mohanson@outlook.com>, Dingwei Zhang <zhangsoledad@gmail.com>
Created: 2023-04-17
---

# VM Syscalls 3

## Abstract

This document describes the addition of the syscalls during the CKB Meepo hardfork. This update significantly enhances the flexibility of CKB Script.

## Introduction

The design of the syscall spawn function draws inspiration from Unix and Linux, hence they share the same terminologies: process, pipe, and file descriptor. The spawn mechanism is used in ckb-vm to create new processes, which can then execute a different program or command independently of the parent process.

In the context of ckb-vm, a process represents the active execution of a RISC-V binary. This binary can be located within a cell. Additionally, a RISC-V binary can also be found within the witness during a syscall spawn. A pipe is established by associating two file descriptors, each linked to one of its ends. These file descriptors can't be duplicated and are exclusively owned by the process. Furthermore, the file descriptors can only be either read from or written to; they can't be both read from and written to simultaneously.

It is worth noting that process scheduling in ckb-vm is deterministic, specifically:

- For each hardfork version, the process scheduling will be deterministic, any indeterminism will be treated as critical / security bugs that requires immediate intervention
- However, based on real usage on chain, it is expected that future hardfork versions would improve the process scheduling workflow, hence making the behavior different across versions

We added 8 spawn-related syscalls and one block-related syscall, respectively:

- [Spawn]
- [Pipe]
- [Inherited File Descriptors]
- [Read]
- [Write]
- [Close]
- [Wait]
- [Process ID]
- [Load Block Extension]

### Spawn
[Spawn]: #spawn

The syscall Spawn is the core part of this update. The parent process calls the Spawn system call, which creates a new process (a child process) that is an independent ckb-vm instance. It's important to note that the parent process will not be blocked by the child process as a result of this syscall.

```c
typedef struct spawn_args_t {
  size_t argc;
  const char** argv;
  /* Spawned VM process ID */
  uint64_t* process_id;
  /* A list of file descriptor, 0 indicates end of array */
  const uint64_t* inherited_fds;
} spawn_args_t;

int ckb_spawn(size_t index, size_t source, size_t place, size_t bounds,
              spawn_args_t* spawn_args);
```

The arguments used here are:

- index: an index value denoting the index of entries to read.
- source: a flag denoting the source of cells or witnesses to locate, possible values include:
    - 1: input cells.
    - `0x0100000000000001`: input cells with the same running script as current script
    - 2: output cells.
    - `0x0100000000000002`: output cells with the same running script as current script
    - 3: dep cells.
- place: A value of 0 or 1:
    - 0: read from cell data
    - 1: read from witness
- bounds: high 32 bits means offset, low 32 bits means length. if length equals to zero, it read to end instead of reading 0 bytes.
- spawn_args: pass data during process creation or save return data.
    - argc: argc contains the number of arguments passed to the program
    - argv: argv is a one-dimensional array of strings
    - process_id: a pointer used to save the process_id of the child process
    - inherited_fds: an array representing the file descriptors passed to the child process. It must end with zero, for example, when you want to pass `fd1` and `fd2`, you need to construct an array `[fd1, fd2, 0]`.

The arguments used here - index, source, bounds, place, argc, and argv - follow the usage described in [EXEC].

There are some hard limits to the system to avoid the overuse of resources.

- CKB-VM allows 16 processes to exist at the same time (excluding the root process). Processes that are created but exit normally will not be counted.
- A maximum of 4 instantiated VMs is allowed. Each process needs to occupy a VM instance to run. When the number of processes is greater than 4, some processes will enter a state called "uninstantiated". CKB-VM implements a scheduler to decide which processes should be "instantiated" and which processes should be "uninstantiated". However, switching the instantiation state of a VM is very expensive, developers should try to keep the number of processes below 4 so that all processes are instantiated.

### Pipe
[Pipe]: #pipe

This syscall create a pipe with read-write pair of file descriptions. The file descriptor with read permission is located at `fds[0]`, and the corresponding file descriptor with write permission is located at `fds[1]`. A maximum of 64 file descriptors can exist at the same time.

```c
int ckb_pipe(uint64_t fds[2]);
```

File descriptors can be passed to a child process via the `inherited_fds` parameter of the Spawn syscall.

### Inherited File Descriptors
[Inherited File Descriptors]: #inherited-file-descriptors

This syscall retrieves the file descriptors available to the current process, which are passed in from the parent process. These results are copied from the `inherited_fds` parameter of the Spawn syscall.

```c
int ckb_inherited_file_descriptors(uint64_t* fd, size_t* count);
```

When returning from the syscall, the syscall fills `fd` with the file descriptors in unit of `uint64_t` and fills in `count` with the count of corresponding file descriptors. The actual count of file descriptor written to `fd` is the minimum value between the count of `inherited_fds` in the Spawn syscall and the input value pointed to by `count` before syscall.

### Read
[Read]: #read

This syscall reads data from a pipe via a file descriptor. The syscall Read attempts to read up to value pointed by length bytes from file descriptor fd into the buffer, and the actual length of data read is written back to the length parameter. The syscall may pause the execution of current process.

```c
int ckb_read(uint64_t fd, void* buffer, size_t* length);
```

For the specific behavior description of Read, you can refer to the following [Write] syscall.

### Write
[Write]: #write

This syscall writes data to a pipe via a file descriptor. The syscall Write writes up to value pointed by length bytes from the buffer, and the actual length of data written is written back to the length parameter. The syscall may pause the execution of current process.

```c
int ckb_write(uint64_t fd, const void* buffer, size_t* length);
```

When using `ckb_read` and `ckb_write`, there may be the following scenarios:

**Success**

- If the writer writes W bytes and the reader reads R bytes where W > R, the writer will block, and the reader will return immediately with R bytes in `*length`. The reader can then call `ckb_read` again to read the remaining W - R bytes.
- If the writer writes W bytes and the reader reads R bytes where W <= R, both the writer and the reader will return immediately with W bytes in `*length`.

**Failure**

- If the writer writes data to pipe, but no other reader reads data from pipe, the writer will block permanently. If ckb-vm detects that all processes are blocked, ckb-vm will return a deadlock error.
- If the reader reads data from pipe, but no other writer writes data to pipe, the reader will block permanently. If ckb-vm detects that all processes are blocked, ckb-vm will return a deadlock error.

### Close
[Close]: #close

This syscall manually closes a file descriptor. After calling this, any attempt to read/write the file descriptor pointed to the other end would fail, so closing a single file descriptor, essentially closes the entire pair of pipes. After using close, there are four typical situations:

- close writer, and then try to write data to writer through `ckb_write`. In this case `ckb_write` will fail and return error(6).
- close writer, and then try to read data from reader through `ckb_read`. In this case if there is unread data in Pipe, ckb_read will execute normally; otherwise, it will return error(7).
- close reader, and then try to write data to writer through `ckb_write`. In this case `ckb_write` will fail and return error(7).
- close reader, and then try to read data from reader through `ckb_read`. In this case `ckb_read` will fail and return error(6).

```c
int ckb_close(uint64_t fd);
```

It's not always necessary to manually close file descriptors. When a process is terminated, all file descriptors owned by the process are automatically closed.

### Wait
[Wait]: #wait

The syscall pauses until the execution of a process specified by `pid` has ended. Retrieve the exit code of the process through the `exit_code` parameter. If a process is waited repeatedly, or you pass in the wrong Process ID, the method returns immediately with error(5), and the value saved in the `exit_code` will not be updated.

```c
int ckb_wait(uint64_t pid, int8_t* exit_code);
```

### Process ID
[Process ID]: #process-id

This syscall is used to get the current process id.

```c
uint64_t ckb_process_id();
```

Root process ID is 0.

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

## Error Code

Five new error types added:

- Error code 5: The file descriptor is invalid during syscall [Wait].
- Error code 6: The file descriptor is not owned by this process.
- Error code 7: The other end of the pipe is closed.
- Error code 8: The maximum count of spawned processes has been reached.
- Error code 9: The maximum count of created pipes has been reached.

## Deadlock

Deadlock is a situation where two or more processes are unable to proceed because they are each waiting for resources or conditions that can only be provided by another waiting process. In the context of this scheduler, where processes communicate via pipes and can enter various states, such as `Runnable`, `Running`, `Terminated`, `WaitForExit`, `WaitForRead`, `WaitForWrite`. In our scheduler, deadlock will occur if all unterminated processes are waiting and no process is in a runnable state.

- The process enters the `Runnable` when a process is created, or it's blocking condition is resolved.
- The process enters the `Running` when a process starts running.
- The process enters the `Terminated` when a process is terminated.
- The process enters the `WaitForExit` state by calling the `wait()` on another process still running.
- The process enters the `WaitForRead` state by calling the `read()`. A process might not actually enter `WaitForRead` state by calling `read()`, if data are already available at the other end. It only enters this state when it wants data but data are not ready, in other words, it has a blocking condition.
- The process enters the `WaitForWrite` state by calling the `write()`. A process might not actually enter `WaitForRead` state by calling `write()`, if the other end is in `WaitForRead` state and is able to read all the data.

If multiple processes are in the `WaitForExit`, `WaitForWrite`, or `WaitForRead` states and are waiting on each other in a circular dependency, a deadlock can occur. Here are two examples:

1. A simple deadlock scenario, both processes are waiting for the other process to send data:
    - Process A is in `WaitForRead` for data from process B
    - Process B is in `WaitForRead` for data from process A. Both processes will wait indefinitely, as each is waiting for the other to proceed.

2. Deadlock caused by unbuffered pipes. Note that the pipe in ckb-vm is unbuffered. If one process blocks on a `WaitForWrite` state because the data is not fully read, and the reader process is also blocked in a `WaitForRead` state (but on a different file descriptor), this can create a deadlock if neither can proceed:
    - Process A wants to read 10 bytes from fd0, and then read 10 bytes from fd1, and finally read 10 bytes from fd0.
    - Process B writes 20 bytes into fd0, and then write 10 bytes into fd1.


## Cycles

Two new constants for cycles consumption are introduced:

```rust
pub const SPAWN_EXTRA_CYCLES_BASE: u64 = 100_000;
pub const SPAWN_YIELD_CYCLES_BASE: u64 = 800;
```

The Cycles consumption of each Syscall is as follows. Among them, the constant 500 and BYTES_TRANSFERRED_CYCLES can be referred to [RFC-0014](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0014-vm-cycle-limits/0014-vm-cycle-limits.md).

|     Syscall Name     |                                   Cycles Charge                                    |
| -------------------- | ---------------------------------------------------------------------------------- |
| spawn                | 500 + SPAWN_YIELD_CYCLES_BASE + BYTES_TRANSFERRED_CYCLES + SPAWN_EXTRA_CYCLES_BASE |
| pipe                 | 500 + SPAWN_YIELD_CYCLES_BASE                                                      |
| inherited_fd         | 500 + SPAWN_YIELD_CYCLES_BASE                                                      |
| read                 | 500 + SPAWN_YIELD_CYCLES_BASE + BYTES_TRANSFERRED_CYCLES                           |
| write                | 500 + SPAWN_YIELD_CYCLES_BASE + BYTES_TRANSFERRED_CYCLES                           |
| close                | 500 + SPAWN_YIELD_CYCLES_BASE                                                      |
| wait                 | 500 + SPAWN_YIELD_CYCLES_BASE                                                      |
| process_id           | 500                                                                                |
| load block extension | 500 + BYTES_TRANSFERRED_CYCLES                                                     |

In addition, when a VM switches between instantiated and uninstantiated states, it requires SPAWN_EXTRA_CYCLES_BASE cycles for each transition.

## Spawn Example

Consider the creation of a dependency library with a straightforward function that receives strings, concatenates them, and subsequently returns the resulting string to the caller(a.k.a echo).

**Caller**

```c
#include <stdint.h>
#include <string.h>

#include "ckb_syscalls.h"

#define CKB_STDIN (0)
#define CKB_STDOUT (1)

// Function read_all reads from fd until an error or EOF and returns the data it read.
int ckb_read_all(uint64_t fd, void* buffer, size_t* length) {
    int err = 0;
    size_t read_length = 0;
    size_t full_length = *length;
    uint8_t* b = buffer;
    while (true) {
        size_t n = full_length - read_length;
        err = ckb_read(fd, b, &n);
        if (err == CKB_OTHER_END_CLOSED) {
            err = 0;
            *length = read_length;
            break;
        } else {
            if (err != 0) {
                goto exit;
            }
        }
        if (full_length - read_length == 0) {
            err = CKB_LENGTH_NOT_ENOUGH;
            if (err != 0) {
                goto exit;
            }
        }
        b += n;
        read_length += n;
        *length = read_length;
    }

exit:
    return err;
}

// Mimic stdio fds on linux
int create_std_fds(uint64_t* fds, uint64_t* inherited_fds) {
    int err = 0;

    uint64_t to_child[2] = {0};
    uint64_t to_parent[2] = {0};
    err = ckb_pipe(to_child);
    if (err != 0) {
        goto exit;
    }
    err = ckb_pipe(to_parent);
    if (err != 0) {
        goto exit;
    }

    inherited_fds[0] = to_child[0];
    inherited_fds[1] = to_parent[1];
    inherited_fds[2] = 0;

    fds[CKB_STDIN] = to_parent[0];
    fds[CKB_STDOUT] = to_child[1];

exit:
    return err;
}

int main() {
    int err = 0;

    const char* argv[] = {};
    uint64_t pid = 0;
    uint64_t fds[2] = {0};
    // it must be end with zero
    uint64_t inherited_fds[3] = {0};
    err = create_std_fds(fds, inherited_fds);
    if (err != 0) {
        goto exit;
    }

    spawn_args_t spgs = {
        .argc = 0,
        .argv = argv,
        .process_id = &pid,
        .inherited_fds = inherited_fds,
    };
    err = ckb_spawn(0, 3, 0, 0, &spgs);
    if (err != 0) {
        goto exit;
    }

    size_t length = 0;
    length = 12;
    err = ckb_write(fds[CKB_STDOUT], "Hello World!", &length);
    if (err != 0) {
        goto exit;
    }
    err = ckb_close(fds[CKB_STDOUT]);
    if (err != 0) {
        goto exit;
    }

    uint8_t buffer[1024] = {0};
    length = 1024;
    err = ckb_read_all(fds[CKB_STDIN], buffer, &length);
    if (err != 0) {
        goto exit;
    }
    err = memcmp("Hello World!", buffer, length);
    if (err != 0) {
        goto exit;
    }

exit:
    return err;
}
```

**Callee**

```c
#include <stdint.h>
#include <string.h>

#include "ckb_syscalls.h"

#define CKB_STDIN (0)
#define CKB_STDOUT (1)

// Function read_all reads from fd until an error or EOF and returns the data it read.
int ckb_read_all(uint64_t fd, void* buffer, size_t* length) {
    int err = 0;
    size_t read_length = 0;
    size_t full_length = *length;
    uint8_t* b = buffer;
    while (true) {
        size_t n = full_length - read_length;
        err = ckb_read(fd, b, &n);
        if (err == CKB_OTHER_END_CLOSED) {
            err = 0;
            *length = read_length;
            break;
        } else {
            if (err != 0) {
                goto exit;
            }
        }
        if (full_length - read_length == 0) {
            err = CKB_LENGTH_NOT_ENOUGH;
            if (err != 0) {
                goto exit;
            }
        }
        b += n;
        read_length += n;
        *length = read_length;
    }

exit:
    return err;
}

int main() {
    int err = 0;

    uint64_t fds[2] = {0};
    uint64_t fds_len = 2;
    err = ckb_inherited_file_descriptors(fds, &fds_len);
    if (err != 0) {
        goto exit;
    }

    uint8_t buffer[1024] = {0};
    size_t length;
    length = 1024;
    err = ckb_read_all(fds[CKB_STDIN], buffer, &length);
    if (err != 0) {
        goto exit;
    }
    err = ckb_write(fds[CKB_STDOUT], buffer, &length);
    if (err != 0) {
        goto exit;
    }
    err = ckb_close(fds[CKB_STDOUT]);
    if (err != 0) {
        goto exit;
    }

exit:
    return err;
}
```

[EXEC]: ../0034-vm-syscalls-2/0034-vm-syscalls-2.md#exec
[Partial Loading]: ../0009-vm-syscalls/0009-vm-syscalls.md#partial-loading
