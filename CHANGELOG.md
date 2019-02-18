## v2019.02.12


### Bug Fixes

* **0002:** typo ([#69](https://github.com/nervosnetwork/rfcs/issues/69)) ([db4661c](https://github.com/nervosnetwork/rfcs/commit/db4661c))
* **0003:** Remove atomic operation support in CKB VM ([#68](https://github.com/nervosnetwork/rfcs/issues/68)) ([af51e3a](https://github.com/nervosnetwork/rfcs/commit/af51e3a))
* **0014:** url in readme ([#61](https://github.com/nervosnetwork/rfcs/issues/61)) ([558f2ba](https://github.com/nervosnetwork/rfcs/commit/558f2ba))



## v2018.01.28

### Updates

* [RFC0002]: This is a major update to CKB whitepaper, one year after its publication. Jan added the latest results come from discussions and developments and removed obsolete contents. ([#64](https://github.com/nervosnetwork/rfcs/pull/64))
* [RFC0003]: Previously, we keep atomic support in CKB VM hoping for maximum compatibility, but since now rv64imc without atomic support is starting to get popular, we don't need to keep atomic instruction support in our design. ([#68](https://github.com/nervosnetwork/rfcs/issues/68))

## v2018.01.14

### New RFC

* [RFC0013]: block template RFC describes the decentralized CKB mining protocol.
* [RFC0014]: cycle limit RFC describes cycle limits used to regulate VM scripts. CKB VM is a flexible VM that is free to implement many control flow constructs, such as loops or branches. As a result, we will need to enforce certain rules in CKB VM to prevent malicious scripts, such as a script with infinite loops.

### Updates

* [RFC0003]: update CKB VM examples based on latest development ([#63](https://github.com/nervosnetwork/rfcs/issues/63))
* [RFC0006]: use more reasonable proof structure ([#62](https://github.com/nervosnetwork/rfcs/issues/62))


## v2018.12.28

The RFC (Request for Comments) process is intended to provide an open and community driven path for new protocols, improvements and best practices. One month later after open source, we have 11 RFCs in draft or proposal status. We haven't finalized them yet, discussions and comments are welcome.


* [RFC0002] provides an overview of the Nervos Common Knowledge Base (CKB), the core component of the Nervos Network, a decentralized application platform with a layered architecture. The CKB is the layer 1 of Nervos, and serves as a general purpose common knowledge base that provides data, asset, and identity services.
* [RFC0003] introduces the VM for scripting on CKB the layer 1 chain. VM layer in CKB is used to perform a series of validation rules to determine if transaction is valid given transaction's inputs and outputs. CKB uses [RISC-V](https://riscv.org/) ISA to implement VM layer. CKB relies on dynamic linking and syscalls to provide additional capabilities required by the blockchain, such as reading external cells or other crypto computations. Any compilers with RV64I support, such as [riscv-gcc](https://github.com/riscv/riscv-gcc), [riscv-llvm](https://github.com/lowRISC/riscv-llvm) or [Rust](https://github.com/rust-embedded/wg/issues/218) can be used to generate CKB compatible scripts.
* [RFC0004] is the protocol how CKB nodes synchronize blocks via the P2P network. Block synchronization **must** be performed in stages with Bitcoin Headers First style. Block is downloaded in parts in each stage and is validated using the obtained parts.
* [RFC0006] proposes Complete Binary Merkle Tree(CBMT) to generate *Merkle Root*  and *Merkle Proof* for a static list of items in CKB. Currently, CBMT is used to calculate *Transactions Root*. Basically, CBMT is a ***complete binary tree***, in which every level, except possibly the last, is completely filled, and all nodes are as far left as possible. And it is also a ***full binary tree***, in which every node other than the leaves has two children. Compare with other Merkle trees, the hash computation of CBMT is minimal, as well as the proof size.
* [RFC0007] describes the scoring system of CKB P2P Networking layer and several networking security strategies based on it.
* [RFC0009] describes syscalls specification, and all the RISC-V VM syscalls implemented in CKB so far.
* [RFC0010] defines the consensus rule “cellbase maturity period”. For each input, if the referenced output transaction is cellbase, it must have at least `CELLBASE_MATURITY` confirmations; else reject this transaction.
* [RFC0011], transaction filter protocol, allows peers to reduce the amount of transaction data they send. Peer which wants to retrieve transactions of interest, has the option of setting filters on each connection. A filter is defined as a [Bloom filter](http://en.wikipedia.org/wiki/Bloom_filter) on data derived from transactions.
* [RFC0012] proposes a P2P node discovery protocol. CKB Node Discovery Protocol mainly refers to [Satoshi Client Node Discovery](https://en.bitcoin.it/wiki/Satoshi_Client_Node_Discovery), with some modifications to meet our requirements.

[RFC0002]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0002-ckb/0002-ckb.md
[RFC0003]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0003-ckb-vm/0003-ckb-vm.md
[RFC0004]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0004-ckb-block-sync/0004-ckb-block-sync.md
[RFC0006]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0006-merkle-tree/0006-merkle-tree.md
[RFC0007]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0007-scoring-system-and-network-security/0007-scoring-system-and-network-security.md
[RFC0009]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0009-vm-syscalls/0009-vm-syscalls.md
[RFC0010]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0010-cellbase-maturity-period/0010-cellbase-maturity-period.md
[RFC0011]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0011-transaction-filter-protocol/0011-transaction-filter-protocol.md
[RFC0012]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0012-node-discovery/0012-node-discovery.md
[RFC0013]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0013-get-block-template/0013-get-block-template.md
[RFC0014]: https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0014-vm-cycle-limits/0014-vm-cycle-limits.md
