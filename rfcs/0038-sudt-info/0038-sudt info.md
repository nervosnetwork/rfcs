---
Number: "0038"
Category: Standards Track
Status: Proposal
Author: Xiang Cheng
Organization: Lay2dev
Created: 2021-12-25
---

# SUDT Info

## 1.Overview

SUDT is a very simple UDT standard. With the UDT deployed by this standard, we can only get the balance from the chain, but not the token name, token symbol, decimals and other parameters. 

To extend the existing SUDT standard, it is necessary to design a scheme to store token information and bind it to the corresponding SUDT, but does not destroy any compatibility with the existing SUDT.

## 2. SUDT Info format

In SUDT Info, the most basic information that must be included is token_name, token_symbol, and decimals. As for total supply and balance, they can all be obtained by indexing the cell.

A SUDT Info in specification looks like following:

```
decimals: uint8
name: Common knowledge Byte
symbol: CKB
extra: {website:"https://nervos.org"} // optional
```

The serialization format of SUDT Info should be JSON. 

**Data:**

- **decimals:** the number of decimal digits used by the token, if decimals are 8 it means that the token can be divided to 0.00000001 at least, uint8 type.
- **token name:** name of the token, an array of characters encoded in UTF8.
- **symbol:** identifier of the token, such as “HIX”, an array of characters encoded in UTF8.
- extra: Anything you want to write, such as the website, the hash value of a certain picture, etc.

The first three items are parameters that must be filled in, and information can be added as required.

If info is placed in a cell, the cell should look like this:

````
Data:
	SUDT Info
Type:
	code_hash: SUDT_Info typescript
	args: SUDT type script hash or type_ID
Lock:
	...
````

## 3. Info data in Cell

### 3.1. For Single Owner SUDT

The issuance of SUDT on CKB is controlled by lockscript, so the simplest SUDT is issued by an individual or organization using a lockscript controlled by a private key, such as USDC and other stable coins.

For this type of SUDT, you can construct an info_cell while minting SUDT, whose typescript's code_hash is info_cell typescript, its args is SUDT's type_script hash. Info_cell will check whether the transaction meets the conditions.

````
// Issue new SUDT/ create a new SUDT_Info cell
Inputs:
  <... one of the input cells must have owner lock script as lock>
Outputs:
	SUDT_Cell:
		Data:
			amount: uint128
        Type:
        	code_hash: simple_UDT type script
     		args: owner lock script hash (...)
     	Lock:
     		<user defined>
	SUDT_Info_Cell:
  		Data:
  			SUDT Info
  		Type:
  			code_hash: SUDT_Info type script
  			args: SUDT type script hash
  		Lock:
  			SUDT creator defined
````

The following rules should be met in a SUDT Info Cell (typescript):

- **Rule 1:** The info cell data should match the SUDT info format we mention above. We will not validate the format on-chain. If it is invalid when we parse it off-chain, just ignore the info and treat it as a SUDT without info.
- **Rule 2:** In this transaction, at least one SUDT cell must exist in the output cell, and the hash of its typescript matches the args of Info_cell.
- **Rule 3:** In this transaction, at least one cell must exist in the input cell, and its lockscript is the owner lockscript of SUDT.
- **Rule 4:** the lockscript of info_cell should be set to deadlock by default, in some cases, developers can choose other lockscript.
- **Rule 5:** If there are multiple Info_cells, choose the info_cell with the smallest block height at the time of generation. If it is at the same block height, choose the info_cell with the smallest transaction index. The same transaction cannot generate two info_cells.

### 3.2. For Script-drive SUDT

However, there is another type of SUDT on CKB, which is not issued by a lockscript controlled by a private key but follows a specific script logic. Such as NexisDAO's dCKB and Tai, and the previous Info_cell design is no longer suitable for this situation.

Since anyone can mint SUDT while following the script logic, if we continue to use the previous logic, anyone can generate the corresponding info_cell. So we need to add new logic on the basis of the previous design.

Since it is impossible to distinguish whether an owner lockscript is script-driven from the outside, it should be checked first according to the script-driven logic.

````
// Create a new SUDT_Info cell
Inputs:
	 ...
Outputs:
	SUDT_Info_Cell:
		Data:
			SUDT Info
		Type:
			code_hash: SUDT_Info type script
			args: type_id
		Lock:
			SUDT creator defined
````

The following rules should be met in a SUDT Info Cell (typescript):

- **Rule 1:** The info cell data should match the SUDT info format we mention above. We will not validate the format on-chain. If it is invalid when we parse it off-chain, just ignore the info and treat it as a SUDT without info.
- **Rule 2:** The args conform to the rules of type id.
- **Rule 3:** The lockscript of info_cell should be set to deadlock by default, in some cases, developers can choose other lockscript.
- **Rule 4:** After constructing this Info cell, use the hash of info_cell's type_script as the first 32 bytes of the args of the lockscript of SUDT owner. 

The type script of the info cell checks whether the transaction satisfies one of the two logics(single-owner or script-driven) above.

## 4. info data in witness

The above describes a solution to put info data in the cell, but if we don’t change info often, we can treat SUDT Info as static data and put it in witness. This solution is an additional solution to info_cell and does not conflict with info_cell.

The advantage is that it can reduce the state occupation on the chain. When SUDT is useless, no state will be occupied, and there will be no situation where the state is still occupied on the chain after the EOS fundraising ends. The disadvantage is that if the blockchain of ckb is to be prune in the future, the information may be lost.

### 4.1. For Single Owner SUDT

````
// Create new SUDT_Info data
Inputs:
	<... one of the input cells must have owner lock script as lock>
Outputs:
	UDT_Cell:
		Data:
			amount: uint128
		Type:
			code_hash: simple_UDT typescript
			args: owner lock script hash (...)
		Lock:
			SUDT creator defined
Witnesses:
	...
	<Corresponding to owner cell>lock:signature,input_type:...,output_type:UDT_info_data
	...
````

For a single-owner-controlled SUDT, info_data satisfies the following rules:

- **Rule 1:** First, check according to the rules of info_cell, if there is a corresponding info_cell, use info_cell.
- **Rule 2:** When there is no corresponding info_cell, scan the entire chain to find the first SUDT issuance transaction that has data in the SUDT Info format in the output_type of the witness corresponding to owner_lock, and use the SUDT Info.

### 4.2. For Script-drive SUDT

Script-driven SUDT stands for, the owner_lock of SUDT is not a lock controlled by a private key, but a special script.

Since it is impossible to distinguish whether an owner lockscript is script-driven from the outside, it should be checked first according to the script-driven logic.

````
// Create a new SUDT_Info data
Inputs:
	<... one of the input cells must have owner lock script as lock>
Outputs:
	UDT_Cell:
		Data:
			amount: uint128
		Type:
			code_hash: simple_UDT typescript
			args: owner lock script hash (...)
		Lock:
			<user defined>
Witnesses:
	...
	<Corresponding to owner cell>lock:signature,input_type:...,output_type:UDT_info_data
	...
````

For a script-drive SUDT, info_data satisfies the following rules:

- **Rule 1:** First, check according to the rules of info_cell, if there is a corresponding info_cell, use info_cell.
- **Rule 2:**  When there is no corresponding info_cell, scan the entire chain to find the first issuance transaction corresponding to SUDT with data in the SUDT Info format in the output_type of the witness corresponding to the owner lockscript, and the hash of info_data is equal to the first 32 bytes of the owner lockscript args.