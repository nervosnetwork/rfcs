---
Number: "0048"
Category: Standards Track
Status: Proposal
Author: Dingwei Zhang <zhangsoledad@gmail.com>
Created: 2023-04-17
---

# Remove Block Header Version Reservation Rule


## Abstract

This rfc proposes to remove this reservation and allow for the use of CKB softfork activation [RFC43] in the block header. This change will be implemented in the 2023 edition of the CKB consensus rules.

## Motivation

The version field in the CKB block header currently has no real meaning, as the consensus rule forces it to be 0 in CKB Edition Mirana and earlier. This means that it cannot be used to signal CKB softfork activation [RFC43]. To address this issue, This rfc proposes to remove this reservation and allow for the use of version bits in the block header.

## Specification

This RFC must be activated via a hard fork. After activation, any unsigned 32-bit integer is legal for the version field and no verification rule will be required.
