---
Number: "0035"
Category: Standards Track
Status: Proposal
Author: Chao Luo, Ian Yang
Organization: Nervos Foundation
Created: 2021-07-01
---
# P2P Protocols Upgrade

## Abstract

This RFC describes how network protocols change before and after the CKB hard fork, and how they are upgraded smoothly during the hard fork.

## Motivation

Network protocols are the basis of distributed applications. There will be small changes in data format before and after the hard fork, but the network should not be disconnected or split because of this change. After the hard fork, only clients that support the hard fork can connect.

This RFC describes how CKB nodes implement this functionality in detail.

## Specification

The hard fork process consists of three phases: before the hard fork, the hard fork activation, and after the hard fork. The protocols are divided into two categories with different upgrade strategies.

- Upgrade the version of a specific protocol and ensure that both versions can be enabled simultaneously
- Mount two functionally identical protocols that will require runtime switching for smooth upgrades

### Protocols whose functionality and implementation do not require modification

#### Protocols

- Identify
- Ping
- Feeler
- DisconnectMessage
- Time
- Alert

##### Before the hard fork

Change the version support list from `[1]` to `[1, 2]`. Clients will be able to use both versions. New clients will enable version 2 and old clients will enable version 1.

##### Hard fork activation

Disconnect all clients that are using version 1 of the protocol, and reject it afterward.

##### After the hard fork

Remove the support for version 1 of the protocol from the next version of the client code, i.e. change the support list from `[1, 2]` to `[2]`, and clean up the compatibility code.

### Protocols that require modification

#### Discovery Protocols

##### Before the hard fork

1. Change the version support list from `[1]` to `[1, 2]`.
2. Remove redundant codec operations from the previous implementation.

##### Hard fork activation

Disconnect all clients using version 1 of the protocol and reject it afterward.

##### After the hard fork

Remove the support for version 1 of the protocol from the next version of the client code, i.e. change the support list from `[1, 2]` to `[2]`, and clean up the compatibility code.

#### Sync Protocols

##### Before the hard fork

1. Change the version support list from `[1]` to `[1, 2]`
2. Remove the 16 group limit from the sync request list, keep the maximum number of syncs, and change the block sync request limit from 16 to 32.

##### Hard fork activation

Disconnect all clients using version 1 of the protocol and reject it afterward.

##### After hard fork

Remove the support for version 1 of the protocol from the next version of the client code, i.e. change the support list from `[1, 2]` to `[2]`, and clean up the compatibility code.

### Protocols that have conflicting behavior before and after the hard fork

#### Relay Protocols

##### Before the hard fork

Relay protocols may have different cycles for transaction validation before and after the hard fork due to inconsistent VMs. Such behavior cannot be identified by a simple upgrade. Alternatively, another solution can be used to smooth the transition, i.e., open both relay protocols, disable the new protocol from relaying messages related to tx, and allow the old protocol to continue functioning normally.

##### Hard fork activation

1. Disable relaying messages related to tx in version 1 and switch to the new relay.
2. Allow the opening of the protocol version 1.

##### After the hard fork

Remove the support for the old relay protocol in the next version of the client code, i.e. remove the old relay protocol support and clean up the compatibility code.
