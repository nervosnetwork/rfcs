---
Number: "0053"
Category: Standards Track
Status: Draft
Author: Dingwei Zhang <zhangsoledad@gmail.com>
Created: 2024-09-13
---

# Nervos CKB Hardfork

## Introduction

This RFC presents a proposal for a hardfork in the Nervos Common Knowledge Base (CKB) blockchain. A hardfork represents a significant protocol update that introduces a permanent divergence from the previous version. Unlike minor updates, a hardfork involves changes that are not backward-compatible, requiring all network nodes to upgrade to maintain consensus.

## Motivation

A key distinction between a hardfork and a softfork lies in their upgrade requirements: a hardfork mandates that all nodes in the network adopt the new protocol, whereas a softfork only requires miners to upgrade. This fundamental difference amplifies the scope and impact of a hardfork.

The Nervos CKB implements hardforks to achieve the following objectives:

- **New Functionalities**: To unlock advanced capabilities and features that enhance the platform’s utility for developers and users. This includes modifications to data structures, the introduction of new RISC-V extensions, additional system calls (syscalls), and other enhancements.
- **Security Upgrades**: To address critical vulnerabilities, fix significant bugs, and resolve limitations in the existing protocol that cannot be remedied through backward-compatible changes.

## Timing Policy

The timing policy for hardforks establishes a minimum interval of one year (equivalent to 2190 epochs) between successive hardforks. This cadence ensures that each hardfork delivers substantial, forward-compatible improvements while allowing sufficient time for rigorous testing. By spacing out these mandatory upgrades, the policy also minimizes the risk of network instability caused by frequent changes.

## Naming Convention

Each hardfork is designated as an "edition," comprising a cohesive set of impactful updates. Edition names are drawn from heroes in the game Dota, and they follow the format **CKB Edition [Name] (Year)**, reflecting the year of implementation. Both the mainnet and testnet share the same edition name, with suffixes (e.g., **Meepo mainnet** and **Meepo testnet**) added when differentiation is necessary.

### Naming Examples

- **CKB Edition Meepo (2024)**: Includes **Meepo mainnet** and **Meepo testnet**.

### Historical Editions

At the launch of Nervos CKB, the mainnet and testnet were assigned distinct names: Lina (mainnet) and Aggron (testnet). The first hardfork, termed the CKB2021 edition, renamed them to Mirana (mainnet) and Pudge (testnet). Starting with the second hardfork, a unified naming convention was adopted, aligning the testnet name with the mainnet’s edition name and eliminating separate designations. Historical editions have been retroactively updated to reflect this convention:

- **CKB Edition Lina (2019)**
- **CKB Edition Mirana (2021)**

| Old Name | New Name |
|--------|-------|
| CKB2019 | CKB Edition Lina (2019) |
| Lina  | Lina mainnet |
| Aggron | Lina testnet |
| CKB2021 | CKB Edition Mirana (2021) |
| Mirana | Mirana mainnet |
| Pudge | Mirana testnet |
| CKB2023 | CKB Edition Meepo (2024) |

## Hardfork Process

The hardfork deployment unfolds in three distinct phases:

### Phase 1: Proposal and Discussion

1. **Proposal Creation**: The process begins with the drafting of a comprehensive hardfork proposal.
2. **Feedback Collection and Discussion**: The proposal is shared with the community to solicit feedback and suggestions, refining the scope of updates through collaborative discussion.
3. **RFC Presentation**: The finalized proposal is submitted as a formal RFC.
4. **Initial Implementation and Testing**: Development commences based on the defined scope, followed by initial testing. Adjustments are made as needed based on early results.
5. **Hardfork-Ready Version**: A preview version of the CKB node, compatible with the hardfork, is released for local testing in a development chain environment. This phase also involves updating ecosystem components—such as SDKs, block explorers, and wallets—to support the changes.
6. **Duration**: This phase typically spans approximately 9 months, with flexibility based on development progress (e.g., 3 months for discussion and 6 months for implementation and testing).

### Phase 2: Public Preview and Testnet Deployment

1. **Public Preview Network Deployment**: Once the implementation is largely complete and well-tested, a public preview network incorporating the hardfork changes is launched, enabling participants to evaluate the updates.
2. **Monitoring and Testing**: The preview network is closely monitored and tested to confirm its stability.
3. **Testnet Hardfork Deployment**: Upon achieving stability in the preview network, the hardfork is rolled out to the testnet, involving:
    - **Release New Node Binary**: A new version of the node software is distributed.
    - **Announce Epoch Number**: A specific epoch is designated for hardfork activation. The upgrade takes effect at this epoch, not immediately upon binary release, even if all nodes have upgraded earlier.
    - **Activation**: Nodes transition to the hardfork-ready binary, and the upgrade activates at the specified epoch. The deployment is deemed successful if the majority of nodes upgrade smoothly by this point. Nodes running older versions will lose connectivity to the testnet post-hardfork.

### Phase 3: Mainnet Deployment

When the network community is prepared, the mainnet deployment mirrors the testnet process:

1. **Release Mainnet Hardfork Binary and Epoch Number**: A new binary and activation epoch are released for the mainnet.
2. **Preparation Period**: A minimum of 3 months is allocated to allow participants ample time to upgrade.
3. **Activation**: The hardfork activates on the mainnet at the designated epoch, following a majority node upgrade, signifying a successful deployment.

### Timeline Summary

- **Phase 1**: Proposal, Discussion, Implementation, and Testing – Approximately 9 months
- **Phase 2**: Public Preview and Testnet Deployment – Duration varies based on stability
- **Phase 3**: Mainnet Deployment – At least 3 months of preparation post-announcement

## Hardfork Activation Mechanism

Hardforks can be activated using one of two methods, each with distinct characteristics:

### Expedited Activation

- **Description**: This method triggers activation within a short timeframe, even if some validating nodes have not upgraded. Safety is enhanced by requiring near-unanimous miner enforcement of the new rules.
- **Process**: Activation occurs automatically after 90% of the network’s hashpower signals readiness, followed by a predetermined delay.
- **Risk Mitigation**: If consensus is lacking, this approach can detect it through failure to reach the 90% hashpower threshold, preventing premature activation.

### Flag Day Activation

- **Description**: This method schedules activation for a specific future date, chosen to ensure nearly all node operators have upgraded to software enforcing the new rules.
- **Process**: Activation proceeds automatically without relying on miner signaling or support.
- **Risk**: Without a built-in consensus check, this approach risks a chainsplit if adoption is incomplete—detectable only through mandatory signaling during activation or violations of the new rules afterward.

### Historical and Future Activation Methods

- **CKB Edition Mirana** and **CKB Edition Meepo** utilized the Flag Day Activation method.
- Future hardforks will transition to the Expedited Activation method to bolster consensus verification and reduce the likelihood of network instability.
