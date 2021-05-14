---
Number: "0035"
Category: P2P Protocol 
Status: Draft
Author: Chao Luo, Ian Yang
Organization: Nervos Foundation
Created: 2021-07-01
---
# P2P protocol upgrade

## Abstract

This RFC describes how the network protocol changes before and after the ckb hard fork, and how the network protocols smoothly upgrade along the hard fork.

## Motivation

The network protocol is the foundation of distributed applications. Before and after hard fork, there will be small changes in data format, but the network should not be disconnected or split because of this change. After hard fork, only clients that support hard fork are allowed to connect.

This RFC describes in detail how the ckb node implements this functionality.

## Specification

We divide the entire hard fork process into three phases: before hard fork, the moment that hard fork activates, and after hard fork. The protocols are divided into two categories which have different upgrade strategies.

- Upgrade the version of a specific protocol and ensure that both versions of the protocol are supported and can be enabled at the same time
- Mount two protocols that are functionally identical but require runtime switching for smooth upgrades

### For protocols whose functionality and implementation do not need to be modified

Including protocols:

- Identify
- Ping
- Feeler
- DisconnectMessage
- Time
- Alert

##### Before hard fork

Change the version support list from `[1]` to `[1, 2]`, the client will support both versions of the protocol, the new client will enable version 2 and the old client will enable version 1

##### Hard fork moment

Disconnect all clients with the protocol version 1 on, and reject this version afterwards.

##### After hard fork

Remove the support for the protocol version 1 from the next version of client code, i.e. change the support list from `[1, 2]` to `[2]`, and clean up the compatibility code

### Implement protocols that requires modification

#### Discovery

##### Before hard fork

1. Change the version support list from `[1]` to `[1, 2]`.
2. Remove redundant codec operations from the previous implementation

##### Hard fork moment

Disconnect all clients with the protocol version 1 on, and reject this version afterwards.

##### After hard fork

Remove the support for the protocol version 1 from the next version of client code, i.e. change the support list from `[1, 2]` to `[2]`, and clean up the compatibility code

#### Sync

##### Before hard fork Before

1. Change the version support list from `[1]` to `[1, 2]`
2. Remove the 16 group limit from the sync request list and keep the maximum number of syncs, new version changes the block sync request limit from 16 to 32

##### Hard fork moment

Disconnect all clients with the protocol version 1 on, and reject this version afterwards.

##### After hard fork

Remove the support for the protocol version 1 from the next version of client code, i.e. change the support list from `[1, 2]` to `[2]`, and clean up the compatibility code

### For protocols whose behavior will conflict before and after fork

#### Relay

##### Before hard fork.

Since relay protocols before and after fork may have inconsistent cycle of transaction validation due to inconsistent vm, such behavior cannot be identified by a simple upgrade, for such protocols, another solution will be adopted to smooth the transition, i.e., open both relay protocols, disable the new protocol relay tx related messages, and let the old protocol work normally

##### Hard fork moment

1. Disable relay tx related messages in version 1 protocol and switch to the new relay
2. Allow opening the version 1 protocols

##### After hard fork

Remove the support for the old relay protocol in the next version of the client code, i.e. remove the support for the old relay protocol and clean up the compatibility code
