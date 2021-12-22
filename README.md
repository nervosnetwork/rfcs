# Nervos Network RFCs

[![Discord](https://img.shields.io/badge/chat-on%20Discord-7289DA.svg)](https://discord.gg/dBPuQ3qnXS)

This repository contains proposals, standards and documentations related to Nervos Network.

The RFC (Request for Comments) process is intended to provide an open and community driven path for new protocols, improvements and best practices, so that all stakeholders can be confident about the direction of Nervos network is evolving in.

RFCs publication here does not make it formally accepted standard until its status becomes Standard.

## Categories

Not all RFCs are standards, there are 2 categories:

* Standards Track - RFC that is intended to be standard followed by protocols, clients and applications in Nervos network.
* Informational - Anything related to Nervos network.

## Process

The RFC process attempts to be as simple as possible at beginning and evolves with the network.

### 1. Discuss Your Idea with Community

Before submitting a RFC pull request, you should send the draft to community to solicit initial feedbacks. The [#rfc-chat discord channel](https://discord.gg/SWE7AtDKc4) or [Nervos Talk](https://talk.nervos.org/) are both good places to go.

### 2. Create A Pull Request

After discussion, please create a pull request to propose your RFC:

> Copy `0000-template` as `rfcs/0000-feature-name`, where `feature-name` is the descriptive name of the RFC. Don't assign an number yet.

Nervos RFCs should be written in English, but translated versions can be provided to help understanding. English version is the canonical version, check english version when there's ambiguity.

Nervos RFCs should follow the keyword conventions defined in [RFC 2119](https://tools.ietf.org/html/rfc2119), [RFC 6919](https://tools.ietf.org/html/rfc6919).

A RFC should be put in either `Informational Track` or `Standards Track`. A RFC on `Standards Track` is a technical specification for software developers to facilitate an interoperable ecosystem. A RFC on `Informational Track` is a descriptive document providing necessary and/or helpful information to users and builders.

A RFC on `Informational Track` has 3 statuses:

1. `Draft` (initial status)
2. `Withdrawn`
3. `Final`

A RFC on `Standards Track` has 5 statuses:

1. `Proposal` (initial status)
2. `Active`
3. `Withdrawn`
4. `Rejected`
5. `Obsolete`

### 3. Review / Accept

The maintainers of RFCs and the community will review the PR, and you should update the RFC according to feedbacks. When a RFC is ready and get enough supports, it will be accepted and merged into this repository. The acceptance of a RFC is based on [rough consensus](https://en.wikipedia.org/wiki/Rough_consensus) at this early stage, we'll keep improving it as the network and ecosystem develops, until we reached the decentralized governance stage.

## RFCs

| Number | Title | Author | Category | Status |
|--------|-------|--------|----------|--------|
| [1](rfcs/0001-positioning) | [The Nervos Network Positioning Paper](rfcs/0001-positioning/0001-positioning.md) | The Nervos Team | Informational | Final |
| [2](rfcs/0002-ckb) | [Nervos CKB: A Common Knowledge Base for Crypto-Economy](rfcs/0002-ckb/0002-ckb.md) | Jan Xie | Informational | Final |
| [3](rfcs/0003-ckb-vm) | [CKB-VM](rfcs/0003-ckb-vm/0003-ckb-vm.md) | Xuejie Xiao | Informational | Final |
| [4](rfcs/0004-ckb-block-sync) | [CKB Block Synchronization Protocol](rfcs/0004-ckb-block-sync/0004-ckb-block-sync.md) | Ian Yang | Standards Track | Proposal |
| [5](rfcs/0005-priviledged-mode) | [Privileged architecture support for CKB VM](rfcs/0005-priviledged-mode/0005-priviledged-mode.md) | Xuejie Xiao | Informational | Withdrawn |
| [6](rfcs/0006-merkle-tree) | [Merkle Tree for Static Data](rfcs/0006-merkle-tree/0006-merkle-tree.md) | Ke Wang | Standards Track | Active |
| [7](rfcs/0007-scoring-system-and-network-security) | [P2P Scoring System And Network Security](rfcs/0007-scoring-system-and-network-security/0007-scoring-system-and-network-security.md) | Jinyang Jiang | Standards Track | Withdrawn |
| [8](rfcs/0008-serialization) | [Serialization](rfcs/0008-serialization/0008-serialization.md) | Boyu Yang | Standards Track | Proposal |
| [9](rfcs/0009-vm-syscalls) | [VM Syscalls](rfcs/0009-vm-syscalls/0009-vm-syscalls.md) | Xuejie Xiao | Standards Track | Proposal |
| [10](rfcs/0010-eaglesong) | [Eaglesong (Proof-of-Work Function for Nervos CKB)](rfcs/0010-eaglesong/0010-eaglesong.md) | Alan Szepieniec | Standards Track | Proposal |
| [11](rfcs/0011-serialization) | [Transaction Filter](rfcs/0011-transaction-filter-protocol/0011-transaction-filter-protocol.md) | Quake Wang | Standards Track | Proposal |
| [12](rfcs/00012-node-discovery) | [Node Discovery](rfcs/0012-node-discovery/0012-node-discovery.md) | Linfeng Qian, Jinyang Jiang | Standards Track | Proposal |
| [13](rfcs/0013-get-block-template) | [Block Template](rfcs/0013-get-block-template/0013-get-block-template.md) | Dingwei Zhang | Standards Track | Proposal |
| [14](rfcs/0014-vm-cycle-limits) | [VM Cycle Limits](rfcs/0014-vm-cycle-limits/0014-vm-cycle-limits.md) | Xuejie Xiao | Standards Track | Proposal |
| [15](rfcs/0015-ckb-cryptoeconomics) | [Crypto-Economics of the Nervos Common Knowledge Base](rfcs/0015-ckb-cryptoeconomics/0015-ckb-cryptoeconomics.md) | Kevin Wang, Jan Xie, Jiasun Li, David Zou | Informational | Draft |
| [17](rfcs/0017-tx-valid-since) | [Transaction valid since](rfcs/0017-tx-valid-since/0017-tx-valid-since.md) | Jinyang Jiang | Standards Track | Proposal
| [19](rfcs/0019-data-structures) | [Data Structures](rfcs/0019-data-structures/0019-data-structures.md) | Xuejie Xiao | Informational | Draft
| [20](rfcs/0020-ckb-consensus-protocol) | [CKB Consensus Protocol](rfcs/0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md) | Ren Zhang | Informational | Draft
| [21](rfcs/0021-ckb-address-format) | [CKB Address Format](rfcs/0021-ckb-address-format/0021-ckb-address-format.md) | Cipher Wang | Standards Track | Proposal
| [22](rfcs/0022-transaction-structure) | [CKB Transaction Structure](rfcs/0022-transaction-structure/0022-transaction-structure.md) | Ian Yang | Informational | Draft
| [23](rfcs/0023-dao-deposit-withdraw) | [Deposit and Withdraw in Nervos DAO](rfcs/0023-dao-deposit-withdraw/0023-dao-deposit-withdraw.md) | Jan Xie, Xuejie Xiao, Ian Yang | Standards Track | Proposal
| [24](rfcs/0024-ckb-system-script-list) | [CKB System Script List](rfcs/0024-ckb-system-script-list/0024-ckb-system-script-list.md) | Dylan Duan | Informational | Draft
| [25](rfcs/0025-simple-udt) | [Simple UDT](rfcs/0025-simple-udt/0025-simple-udt.md) | Xuejie Xiao | Standards Track | Proposal
| [26](rfcs/0026-anyone-can-pay) | [Anyone-Can-Pay Lock](rfcs/0026-anyone-can-pay/0026-anyone-can-pay.md) | Xuejie Xiao | Standards Track | Proposal
| [27](rfcs/0027-block-structure) | [CKB Block Structure](rfcs/0027-block-structure/0027-block-structure.md) | Ian Yang | Informational | Draft

## License

This repository is being licensed under terms of [MIT license](LICENSE).
