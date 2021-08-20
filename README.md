# Nervos Network RFCs

[![Telegram Group](https://cdn.rawgit.com/Patrolavia/telegram-badge/8fe3382b/chat.svg)](https://t.me/nervos_rfcs)

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

Before submiting a RFC pull request, you should proposal the idea or document to [Nervos RFCs Chatroom](https://t.me/nervos_rfcs) or [Nervos RFCs Mailing List](https://groups.google.com/a/nervos.org/d/forum/rfcs).

### 2. Propose Your RFC

After discussion, please create a pull request to propose your RFC:

> Copy `0000-template` as `rfcs/0000-feature-name`, where `feature-name` is the descriptive name of the RFC. Don't assign an number yet.

Nervos RFCs should be written in English, but translated versions can be provided to help understanding. English version is the canonical version, check english version when there's ambiguity.

Nervos RFCs should follow the keyword conventions defined in [RFC 2119](https://tools.ietf.org/html/rfc2119), [RFC 6919](https://tools.ietf.org/html/rfc6919).

### 3. Review / Accept

The maintainers of RFCs and the community will review the PR, and you can update the RFC according to comments left in PR. When the RFC is ready and has enough supports, it will be accepted and merged into this repository.

An Informational RFC will be in Draft status once merged and published. It can be made Final by author at any time, or by RFC maintainers if there's no updates to the draft in 12 months.

### 4. (Standards Track) Propose Your Standard

A Standards Track RFC can be in 1 of 3 statuses:

1. Proposal (Default)
2. Standard
3. Obsolete

A Standards Track RFC will be in **Proposal** status intially, it can always be updated and improved by PRs. When you believe it's rigorous and mature enough after more discussions, you should create a PR to propose making it a **Standard**.

The maintainers of RFCs will review the proposal, ask if there's any objections, and discuss about the PR. The PR will be accepted or closed based on **rough consensus** in this early stage.

## RFCs

| Number | Title | Author | Category | Status |
|--------|-------|--------|----------|--------|
| 1 | [The Nervos Network Positioning Paper](rfcs/0001-positioning/0001-positioning.md) | The Nervos Team | Informational | Draft |
| 2 | [Nervos CKB: A Common Knowledge Base for Crypto-Economy](rfcs/0002-ckb/0002-ckb.md) | Jan Xie | Informational | Draft |
| 3 | [CKB-VM](rfcs/0003-ckb-vm/0003-ckb-vm.md) | Xuejie Xiao | Informational | Draft |
| 4 | [CKB Block Synchronization Protocol](rfcs/0004-ckb-block-sync/0004-ckb-block-sync.md) | Ian Yang | Standards Track | Proposal |
| 5 | [Privileged architecture support for CKB VM](rfcs/0005-priviledged-mode/0005-priviledged-mode.md) | Xuejie Xiao | Informational | Draft |
| 6 | [Merkle Tree for Static Data](rfcs/0006-merkle-tree/0006-merkle-tree.md) | Ke Wang | Standards Track | Proposal |
| 7 | [P2P Scoring System And Network Security](rfcs/0007-scoring-system-and-network-security/0007-scoring-system-and-network-security.md) | Jinyang Jiang | Standards Track | Proposal |
| 8 | [Serialization](rfcs/0008-serialization/0008-serialization.md) | Boyu Yang | Standards Track | Proposal |
| 9 | [VM Syscalls](rfcs/0009-vm-syscalls/0009-vm-syscalls.md) | Xuejie Xiao | Standards Track | Proposal |
| 10 | [Eaglesong (Proof-of-Work Function for Nervos CKB)](rfcs/0010-eaglesong/0010-eaglesong.md) | Alan Szepieniec | Standards Track | Proposal |
| 11 | [Transaction Filter](rfcs/0011-transaction-filter-protocol/0011-transaction-filter-protocol.md) | Quake Wang | Standards Track | Proposal |
| 12 | [Node Discovery](rfcs/0012-node-discovery/0012-node-discovery.md) | Linfeng Qian, Jinyang Jiang | Standards Track | Proposal |
| 13 | [Block Template](rfcs/0013-get-block-template/0013-get-block-template.md) | Dingwei Zhang | Standards Track | Proposal |
| 14 | [VM Cycle Limits](rfcs/0014-vm-cycle-limits/0014-vm-cycle-limits.md) | Xuejie Xiao | Standards Track | Proposal |
| 15 | [Crypto-Economics of the Nervos Common Knowledge Base](rfcs/0015-ckb-cryptoeconomics/0015-ckb-cryptoeconomics.md) | Kevin Wang, Jan Xie, Jiasun Li, David Zou | Informational | Draft |
| 17 | [Transaction valid since](rfcs/0017-tx-valid-since/0017-tx-valid-since.md) | Jinyang Jiang | Standards Track | Proposal
| 19 | [Data Structures](rfcs/0019-data-structures/0019-data-structures.md) | Xuejie Xiao | Informational | Draft
| 20 | [CKB Consensus Protocol](rfcs/0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md) | Ren Zhang | Informational | Draft
| 21 | [CKB Address Format](rfcs/0021-ckb-address-format/0021-ckb-address-format.md) | Cipher Wang | Standards Track | Proposal
| 22 | [CKB Transaction Structure](rfcs/0022-transaction-structure/0022-transaction-structure.md) | Ian Yang | Informational | Draft
| 23 | [Deposit and Withdraw in Nervos DAO](rfcs/0023-dao-deposit-withdraw/0023-dao-deposit-withdraw.md) | Jan Xie, Xuejie Xiao, Ian Yang | Standards Track | Proposal
| 24 | [CKB System Script List](rfcs/0024-ckb-system-script-list/0024-ckb-system-script-list.md) | Dylan Duan | Informational | Draft
| 25 | [Simple UDT](rfcs/0025-simple-udt/0025-simple-udt.md) | Xuejie Xiao | Standards Track | Proposal
| 26 | [Anyone-Can-Pay Lock](rfcs/0026-anyone-can-pay/0026-anyone-can-pay.md) | Xuejie Xiao | Standards Track | Proposal
| 27 | [CKB Block Structure](rfcs/0027-block-structure/0027-block-structure.md) | Ian Yang | Informational | Draft

## License

This repository is being licensed under terms of [MIT license](LICENSE).
