# Contract

```
Author: Xuejie Xiao <x@nervos.org>
Category: CKB
Start Date: 2018-08-27
```

## Overview

This RFC proposes several changes on current contract execution model to achieve following goals:

* Cell type schema and validator execution flows are finalized
* Communication solution between different contracts within a transaction is defined

Note that all sample code and examples in this RFC will be written in Ruby due to the following reasons:

* It is already been proved that CKB VM can run Ruby by running a Ruby VM directly
* The main goal here is to explain how CKB contract works here, not achieving absolutely minimal resource usage
* Most(if not all) of the team members already know Ruby, plus Ruby is easy to read.

## Recap

Right now, transaction execution flow is as follows:

![](assets/current-flow.png "Current Flow")

1. Existing UTXOs, also known as `Cells` in CKB, has a data field as well as data/owner locks. For space consideration, each lock here only consists of a single lock script hash.
2. In a transaction, an input would reference a UTXO with the actual unlock script(whose hash should match the lock script hash in UTXO) and unlock script data. When we execute the script together with the data on CKB VM, it should return success.
3. The output of the transaction is also a UTXO(if there is one), which will also contain data field and data/owner locks. Existing or new unlock script hash could be used here in each lock.

## Concepts

Several concepts to current contract execution flow are proposed here.

### IO Group

First, IO group is added to transactions: A transaction is divided to one or more IO groups, each IO groups can contain one or more of the following cell actions:

* Create: a new output cell is created
* Transform: an existing input cell is transformed to a new output cell
* Destroy: an existing input cell is consumed, no output cell is created

A transaction is either all accepted, or all rejected, it's not possible to accept only some IO groups in a transaction. Refer to later sections on how IO group can affect transaction.

![](assets/iogroup.png "IO Group")

With the exception of coinbase transactions, all transactions should satisfy the property that the sum of capacities of all output cells must not exceed the sum of input capacities of all input cells.

### Cell Type

![](assets/cell.png "Cell")

In the whitepaper CKB defines `cell type`, which consists of schema and validator. But the format of them are never settled. This RFC will define what schema and validator will look like.

#### Schema

Schema provides a handy way to access binary data stored in the designated cell. In CKB, schema is implemented as a dynamic linked library for CKB VM. Once loaded, it can provide one or more utility functions to parse and read cell data. For example, a weather oracle cell can provide the following schema to read current weather:

```c
int temperature(int city_index, int year, int month, int day);
int wind(int city_index, int year, int month, int day);
```

Note that it's just an example that we use C interface here. The only rules a schema needs to follow, is that it must be in ELF shared object format for RISC-V architecture, which is what CKB VM uses. That means it's totally okay to create a schema that can only be loaded into a mruby VM on top of CKB VM with Ruby-only contracts:

```ruby
module Weather
  def self.temperature(city_index, year, month, day)
    # calling actual library
  end

  def self.wind(city_index, year, month, day)
    # calling actual library
  end
end
```

In this case, an initialization function is needed to load the new Ruby modules into mruby VM, but the point is a C interface is totally optional depending on Cell creator.

Schema is entirely optional: for cell with simple data formats, it's definitely possible to read cell data directly instead of loading a library to access the data. But for more complex data structures, schema would be more helpful here.

Schema is also quite flexible: CKB doesn't have a set of rules for defining specific items in the cell, such as integers or strings. Instead, it just let Cell creator provide a series of functions to work on top of the binary data. It's totally up to the cell creator to decide what format he/she shall use for each individual component in the cell.

#### Validator

While schema provides a way to access formatted data in an existing cell, validator ensures the data of the cell follows this pre-defined format. At the very top level, validator is just a RISC-V executable contract like unlock script. CKB will run this validator contract in its own VM with the following arguments:

```bash
$ ./validator <number of deps> <dep 1 cell ID> <dep 2 cell ID> ... \
    <number of inputs> <input 1 cell ID> <input 2 cell ID> ... \
    <number of outputs> <output 1 cell ID> <output 2 cell ID> ... \
    <current output cell ID>
```

While running, contract can leverage CKB APIs and syscalls to load cell schema library, read cell data, communicate with other contract(this will be discussed in more details later). Upon completion, the returned code of the RISC-V executable denotes if the validator succeeds.

#### Cell Type Properties

Cell type part, including schema and validator, can either be inlined within current cell, or referenece external cell. It's possible to create a designated meta cell containing only cell type data(schema and validator), then create many other cells referencing this single meta cell as cell type.

Cell type is also immutable: once a cell is given a type, there's no way one can change the type of this cell via transform action. The only thing one can do here, is to use a destroy action to destroy the original cell, and then use a create action to create a new cell with new cell type.

## Current Contract Execution Flow

With newly introduced concepts above, now contract execution flow looks like this:

![](assets/new-flow.png "New Flow")

1. For each input in all IO groups in current transaction, CKB would locate the referenced UTXOs first. The exact lock script hash to use is based on action type:
   - If input is used in transform action, data lock hash will be used;
   - If input is used in destroy action, owner lock hash will be used.
2. CKB will launch a separate VM for each input unlock script with specificed script data. If any VM fails, the whole transaction is marked with failure. Notice all VMs here could run concurrently.
3. Once all inputs are verified via unlock script, CKB will then test all cell type validators: for each validator (if there exists one) in each output cells(this include all transform actions and create actions), a separate VM will be started with validator script. The validator script will be provided with following arguments:
   - All deps cells in the transaction are included as deps;
   - All input cells from current IO group are included as inputs;
   - All output cells from current IO group are included as outputs.
   - Current output cell ID is also provided for convenience.
4. All VMs from the same IO group here can be treated as running concurrently, VMs in the same IO group can communicate in the following way:
   - They can communicate via reading each other's cell;
   - CKB will also provide a special syscall in VM that can be used to create a channel between VMs in the same IO group, 2 VMs can leverage this channel to send and receive data.
5. One all VMs launched here return a success result, current transaction can be marked as success.

It's easy to see here that IO groups are used to isolate different cells: with IO groups, one can group related cells together for processing. Atomicity, on the other hand, is provided at transaction level.

Notice those steps only contain execution flow relating to contracts and VMs, CKB will still perform other sanity checks before and maybe after performing this execution flow, such as capacity checking.

## Examples

Examples will be provided here to show how the newly added changes can be used to achieve certain features.

### Currency Exchange

### Plasma
