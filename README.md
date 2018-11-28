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

Before submiting a RFC pull request, you should proposal the idea or document to [Nervos RFCs Chatroom](https://t.me/nervos_rfcs) or [Nervos RFCs Mailing List](#).

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
| [2](https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0002-ckb) | [Nervos CKB: A Common Knowledge Base for Blockchains and Applications](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0002-ckb/0002-ckb.md) | Jan Xie | Informational | Draft |
| [3](https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0003-ckb-vm) | [CKB-VM](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0003-ckb-vm/0003-ckb-vm.md) | Xuejie Xiao | Informational | Draft |
| [4](https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0004-ckb-block-sync) | [CKB Block Synchronization Protocol](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0004-ckb-block-sync/0004-ckb-block-sync.md) | Ian Yang | Standards Track | Proposal |
| [5](https://github.com/nervosnetwork/rfcs/tree/master/rfcs/0005-priviledged-mode) | [Privileged architecture support for CKB VM](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0005-priviledged-mode/0005-priviledged-mode.md) | Xuejie Xiao | Informational | Draft |

## License

This repository is being licensed under terms of [MIT license](LICENSE).
