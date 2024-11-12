---
Number: "0053"
Category: Standards Track
Status: Draft
Author: Dingwei Zhang <zhangsoledad@gmail.com>
Created: 2024-09-13
---

# Nervos CKB Hardfork

## Introduction

This RFC outlines the proposal for a hardfork in the Nervos CKB blockchain. A hardfork is a substantial update to the blockchain protocol that results in a permanent divergence from the previous version. This update includes major changes that are not backward-compatible, necessitating the upgrade of all nodes in the network to maintain consensus.

## Motivation

One of the biggest differences between a hardfork and a softfork is that a hardfork requires all nodes in the network to upgrade, while a softfork only requires miner nodes to upgrade. This leads to differences in the impact and scope of the upgrades.

Nervos CKB introduces hardforks for:

- **New Functionalities**: Enabling new capabilities and features that enhance the utility of the Nervos CKB platform for developers and users by modifying data structures, introducing new RISC-V extensions, new syscalls, and more.
- **Security Upgrades**: Resolving critical issues, addressing critical bugs, and overcoming limitations in the current protocol that cannot be fixed through backward-compatible updates.

## Timing Policy

The policy for hardfork timing aims to maintain intervals of at least one year(2190 epochs) between hardforks. This ensures that each hardfork includes substantial forward-compatible upgrades, providing ample time for thorough testing. Additionally, this approach helps avoid the network instability that can result from frequent mandatory upgrades.

## Naming Convention

A hardfork includes a series of significant, coherent updates, and we define the naming of a hardfork as an "edition." Each edition's name is chosen from Dota heroes. Editions are named after the year in which they occur, with the complete format being **CKB Edition [Name] (Year)**. The mainnet and testnet will use the same name, and when needed, a suffix will be added to distinguish between them, such as **Meepo mainnet** and **Meepo testnet**.

**Naming Examples**:

- **CKB Edition Meepo (2024)**: **Meepo mainnet** and **Meepo testnet**.

### **Historical Edition**

When Nervos CKB first launched, the two networks, mainnet and testnet, were given distinct names: Lina (mainnet) and Aggron (testnet). During the 1st hardfork, known as the CKB2021 edition, the names changed to Mirana (mainnet) and Pudge (testnet). For the 2nd hardfork, we introduced a new naming convention that unifies the names across all networks. The edition name is now based on the mainnet name, and the testnet name matches the mainnet name without a separate designation.

- **Historical Editions**: Previous editions are also updated to the new naming convention, such as:
    - **CKB Edition Lina (2019)**
    - **CKB Edition Mirana (2021)**

## Hardfork Process

### Phase 1: Proposal and Discussion

1. **Proposal Creation**: Initiate the hardfork process by creating a detailed proposal.
2. **Feedback Collection and Discussion**: Share the proposal with the community to gather suggestions and feedback. Discuss and refine the scope of updates and changes for the hardfork.
3. **RFC Presentation**: Present the finalized proposal in the form of a Request for Comments (RFC).
4. **Initial Implementation and Testing**: After defining the general scope of updates, start implementation and initial testing. Adjust the proposal as needed based on initial findings.
5. **Hardfork-Ready Version**: Release a hardfork-ready version of the CKB node for local preview in a dev chain environment. This phase includes updating the surrounding ecosystem, such as SDKs, explorers, and wallets, to support the new changes.
6. **Duration**: This phase typically takes about 9 months, with adjustments based on development progress.

### Phase 2: Public Preview and Testnet Deployment

1. **Public Preview Network Deployment**: Once the implementation is mostly complete and thoroughly tested, a new network with the hardfork changes is deployed as a public preview. This allows network participants to test the changes.
2. **Monitoring and Testing**: The public preview network is observed and tested to ensure stability.
3. **Testnet Hardfork Deployment**: After the public preview network proves stable, the hardfork is deployed on the testnet. This involves:
    - **Release New Node Binary**: A new version of the node binary is released.
    - **Announce Epoch Number**: A specific epoch number is announced for the hardfork activation. The network upgrade does not happen immediately after the binary release but at the specified epoch number, even if all nodes are upgraded to the hardfork-ready binary beforehand.
    - **Activation**: All nodes upgrade to the hardfork-ready binary. The network upgrade occurs at the specified epoch number. The hardfork is considered successfully deployed if the majority of nodes upgrade smoothly by the specified epoch number. Nodes running the old version will no longer be able to connect to the testnet after the hardfork.

### Phase 3: Mainnet Deployment

When all network participants are ready to upgrade, the mainnet hardfork deployment process begins, following a similar approach as the testnet deployment.

1. **Release Mainnet Hardfork Binary and Epoch Number**: A new mainnet hardfork binary and a specific epoch number for activation are released.
2. **Preparation Period**: A preparation period of at least three months is provided to ensure all participants have sufficient time to complete the upgrade.
3. **Activation**: Activate the hardfork on the mainnet at the specified epoch number following majority node upgrade, marking successful deployment.

### Timeline Summary

- **Phase 1**: Proposal and Discussion, Initial Implementation and Testing - 9 months (approximately 3 months for discussion and 6 months for development and testing)
- **Phase 2**: Public Preview and Testnet Deployment - Variable duration based on stability
- **Phase 3**: Mainnet Deployment - At least 3 months of preparation time after announcement
