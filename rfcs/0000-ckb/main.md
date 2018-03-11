# Nervos CKB

* Start Date: 2018-01-02
* RFC PR: #link-to-github-pr

A general purpose common knowledge base.

## Abstract

This document provides an overview to the Common Knowledge Base (CKB), the core project of the Nervos blockchain. Nervos is a distributed service platform with layered architecture. CKB is the foundational layer of Nervos, as a general purpose common knowledge base to provide data, identity and the abstraction of value.

## Background

As we see more blockchain use cases emerging, the current generation blockchain technologies are finding it difficult to meet real world application's demand on performance, (???), and robustness of the economic and trust models.

Bitcoin is the first blockchain network in the world, designed as a peer to peer cash ledger. Bitcoin's ledger is the system state maintained by the Bitcoin network. The minimum storage unit on the ledger is UTXO. Users can use wallets to spend current UTXOs, generate new UTXOs, package them into transactions to send to the Bitcoin network for validation and consensus. The UTXOs records the cash amount and ownership expressed with lock scripts. Users have to provide proper unlocking data to spend UTXOs. Due to the data structure and Bitcoin script's limitations, it's difficult to use the Bitcoin ledger to record other types of assets and data. Solutions like Colored Coins, Meta Coins or Bitcoin hard forks are possible, but expensive and inflexible in implementation.

Ethereum brought us a general purpose computation blockchain platform with the introduction of smart contracts. The Ethereum ledger is the system state maintained by the Ethereum network. Ethereum's ledger consists of the global states of all accounts. Smart contracts are the type of accounts that have code stored inside, together with a 256 bit K/V store. Users can start two types (???) of transactions on Ethereum: the first type is to create a contract and deploy on the blockchain the user programmed application logic; the second type is to send the input data provided by the user to a specific contract account. This executes the code stored on the contract and updates contract state. Ethereum's smart contracts provide more computation power and flexibility, and solve some of Bitcoin's problems. But it still has limitations:

* Difficult to scale: Ethereum's design focuses on the events of the state machine (see figure 1). Ethereum allows a Turing complete scripting language. Ethereum transactions store the inputs of state transitions, instead of the states themselves. For those two reasons, it's difficult for full nodes to tell dependencies between transactions, therefore difficult to process transactions in parallel. Also, because the transactions don't include states, this causes data availability issues in sharding solutions.

* Uncertain states: in Ethereum, the states of the contracts are updated by the contract code, and contract code execution depends on execution context (such as the current block height). Therefore users won't know the exact execution result when they start the transactions.

* Mono-Contract: Ethereum smart contracts tightly couple computation and storage together. Users have to use the account model, EVM bytecode and the 256 bit K/V database paradigm to implement all scenarios. This is not efficient or flexible.

The economic models of current blockchains care more about cost of consensus and computation, instead of storage (see the economic model section). After consensus, common knowledge can store in the blockchain for free forever.

For those reasons, we'd like to design a more modular, general purpose common knowledge base, with a matching economic model.

![Figure 1. Event-focused vs. State-focused Design](fig1.png)
> Figure 1. Event-focused vs. State-focused Design

## Overview

Nervos CKB (CKB for short) is a general purpose common knowledge base built with blockchain technologies. Every piece of common knowledge in the CKB includes the following three elements:

* Data
* Validation logic of the data in its domain
* Identity of the party that submits the data

This design not only makes CKB suitable for strictly defined and independently verifiable common knowledge (such as the result of value transfers in token systems), but also suitable for real business scenarios based on trust.

The current state of CKB is the set of all common knowledge that it stores. The CKB design of data flow and economic incentives is based on states - states are generated on the client side, validated by the consensus algorithm, and stored on the distributed network, forming common knowledge. CKB uses Lambda Calculus as the computation model, and the generic Cell data model. It supports virtual machines. Users can define their own data types and their generation and validation algorithms.

Table 1 compares Bitcoin, Ethereum and Nervos CKB as common knowledge bases:

| Common Knowledge Base | Bitcoin          | Ethereum          | Nervos CKB      |
| --------------------- | ---------------- | ----------------- | --------------- |
| Knowledge Type        | Ledger           | Smart Contract    | General         |
| Storage               | UTXO             | Account K-V Store | Cell            |
| Data Schema           | N/A              | N/A               | Type            |
| Validation Rule       | Limited (Script) | Any (Contract)    | Any (Validator) |
| State Write           | Direct (User)    | Indirect (EVM)    | Direct (User)   |
| State Read*           | No               | Yes               | Yes             |
> Table 1. Comparison of Common Knowledge Bases
(* State Read refers to on chain readability only, which means if the state can be read during on chain validation. Chain state is transparent to off chain reader.)

 
The formation of common knowledge has three phases in CKB: generation, validation and storage. Generation is done on the client side with the generation algorithm. New states are then propagated to the network nodes with transactions (see [Transaction](#Transaction)). Nodes validate new states with the validation algorithms defined in their types and store them in the blockchain.

In the CKB, the state generation and validation are separate. They can use the same algorithms or different algorithms.

For general business scenarios, currently there are no generic ways to get simplified and efficient validation algorithms from the generation algorithm. In this case we can use the same algorithm state generation and validation: the client side uses the algorithm to generate new states, then nodes run the same algorithm using the transaction's inputs and compare the output states with the new states in the transaction. If the states match, then the validation passes. When the same algorithm is used, state generation and validation have the same computation complexity, but running in different environments. The advantages of separating generation and validation are:

* Certainty of transactions: Certainty of transactions is one of the core pursuits of distributed systems. Certainty in transaction latency (see [Hybrid Consensus](#hybrid-consensus)) has seen a lot of attention, but certainty in transaction output hasn't see much discussions. If new states are generated on the nodes, the users that started the transaction won't be able to be certain about the execution context of the transaction, and the transaction could generate unexpected outputs. In CKB, the users generate new states on the client side. They can confirm with the new states before propagating it to the network. The users can be certain with the the outcome of the transaction: whether the transaction passes validations and gets accepted by the network, or the validation process fails and there won't be state changes. (see diagram 2)
* Parallelism: If new states are generated on the nodes, they won't know the state dependencies of transactions before they are processed. This makes it difficult for the nodes to know which transactions are independent and can be executed in parallel, and which transactions have dependency relationships and have to be executed serially. In CKB, transactions need to declare their dependent states in the inputs, so the nodes can see dependency relationships between transactions (see [Transaction](#transaction)). Independent transactions can be processed in parallel in many ways, such as on different CPUs or sent to different shards. Parallelism can help us improve scalability of blockchain systems.
* Distributed computation: the system's efficiency improves when we utilize computation resources on the clients and lower the the computation load on the nodes.
* More flexible client side implementation and easier to integrate with client side platforms: even when the algorithms are the same, generation and validation can be implemented differently. The client side has the flexibility to choose the programming language for better performance, or integrate the generation logic into their own runtimes to give better user experience.

In many specific scenarios, we can find validation algorithms much more efficient than the generation algorithm. The most typical examples are the UTXO transactions and asymmetric signatures. Sorting and searching algorithms are other examples: the computational complexity for quick sort, one of the best sorting algorithms for the average case, is `O(NlogN)`, but the algorithm to validate the result is just `O(N)`; Searching for the index of an element in a sorted array is `O(logN)` with binary search, but its validation only takes `O(1)`. The more complicated the business rules are, the higher probability that there can be asymmetric generation and validation algorithms with different computational complexity.

The throughput of validating nodes can be greatly improved with asymmetric generation and validation algorithms. With the advancement of cryptography, we may find methods to design generic asymmetric algorithms, such as general purpose zkSNARKs. CKB's architecture will be able to provide proper support when it happens.

Moving state transition details to the client side also helps with protection and privacy of the algorithms themselves.

![Figure 2. Non-deterministic vs. Deterministic State Generation](fig2.png)
> Figure 2. Non-deterministic vs. Deterministic State Generation

We're going to provide an overview of the Cell data model in CKB, with the goal to better explain the functionality of the CKB itself. In the actual implementation of the CKB, we need to consider other factors including incentives and execution efficiency, and the data structure will be more complicated. We'll describe more details in other documents.

## Cell

Current public blockchain systems are designed as ledgers. Either with the UTXO model or the account model, they focus on expressing relationships between assets and their owners. The UTXO model defines ownerships based on the underlying assets and constructs transactions with states before and after the transactions. This makes the transaction entries more clear. However it doesn't have the concept of accounts and can't record the properties and states of accounts, therefore making smart contracts difficult. The account model records the amounts of assets based on their ownerships and constructs transactions based on change of the amounts. This makes it easy for identity management and authorizations, but makes it difficult to process transactions in parallel. In our opinion, the different data models have their own suitable scenarios, and users should be able to choose based on their own needs.

CKB uses the more abstract Cells to store common knowledge. Cells are the smallest data units in the CKB, and they include the following properties:

* type: type fo the cell (see [Type](#type))
* capacity: capacity of the cell. The limit of data that can be stored in the cell expressed in bytes.
* data: the actual binary data stored in the cell. This could be empty. The bytes of data stored should always be less than the cell's capacity.
* owner_lock: script to represent ownership of the cell. Owners of cells can transfer cells to others.
* data_lock: script to represent the user with right to use the cell. Cell users can update the data in the cell.

Cell's lock scripts are executed on CKB's VM. When updating data or transferring ownerships, users need to provide necessary proof as the inputs of the lock scripts. User authorization can be proved if the lock scripts return true, and the user is allowed to perform operations with the cell.

The lock scripts represent authorizations of the cells. The scripts can represent a single user, as well as a multisig or more complicated schemes. Cells have good privacy support. Users can manage their cells with pseudonym using different lock scripts. Cell's owners and rightful users can be the same or different users, which means users don't have to own cells to interact with the CKB. This lowers the barrier of entry of the system and encourages adoption.

### Type


CKB provides a type system for Cells and users can define their own Cell types. With the type system, we can define different kinds of common knowledge and their validation rules.

A new Cell type needs to define:

* Data Schema: defines the data structure of the type
* Validator: defines the validating function of the type

Data Schema and Validator themselves are common knowledge, stored in Cells. Each Cell has one and only one type, but multiple Cells could be of the same type.

The data schema defines the data structure of the Cell so that the validator can interpret and use the data stored in Cells. Validators are verifying programs that run on the nodes, in the virtual machine that the CKB provides. A validator uses the transaction's inputs and outputs as inputs, and returns a boolean value on whether the validation is successful. The creation, update and destroy of Cells can use different validators. 

### Index

Users can set up indexes when they define a data schema. The CKB provides more support for indexed properties, such as conditional query commands and aggregate functions in validators or owner_lock / data_lock scripts. For example, to start a capped crowd sale, the starter of the sale can create an Identity Cell (see Identity), and use conditional query and aggregate function to tell whether the crowd sale's goal has been achieved.

### Life Cycle

There are two phases in the life cycle of Cells. Newly created cells are in the first phase (“P1”). Cells are immutable data objects. Updates to cells are done through transactions. Transactions take P1 Cells to be updated as inputs, and new P1 Cells with new states produced by the Generator as outputs.

Every P1 Cell can and only can be used once - they can't be used as the inputs of two different transactions; after use, P1 cells enter the second phase in the Cell life cycle ("P2"). P2 Cells can't be used as transaction inputs. We call the set of all p1 Cells “P1 Cell Set (P1CS)”. The P1CS has all the current common knowledge of the CKB. We call the set of all P2 cells "P2 Cell Set (P2CS)". The P2CS has all the historical states of the CKB.

Full nodes on the CKB only needs P1CS to validate transactions. P2CS can be archived on Archive Nodes or distributed storage. CKB light clients only need to store block headers, and don't need to store P1CS or P2CS. 

## Identity

Identity is a system type. Users can create Identity Cells that belong to themselves. Identity Cells can be used for Cell's data_lock/owner_lock scripts. Cell's transfer and update need its Identity Cell's `data_lock` unlock script (see Figure 3)

Identity in the Nervos CKB is generalized identity that could represent any individuals or machines. Cell is the foundation of Nervos Identity Protocol, and can be used as an identity to store the metadata of that identity. Individuals can create multiple Identity Cells with different metadata if they want to, or out of privacy concerns. It's possible to give proof for association relationships for Identity Cells.

![Figure 3. Identity Cell](fig3.png)
> Figure 3. Identity Cell

## Transaction

Transactions express the creations and updates of Cells. Users can use transaction to create a Cell, or update one or more Cells. A transaction includes the following:

* deps: the set of dependencies, including the P1 cells needed for validation and the user inputs.
* inputs: the set of inputs, including all the transferred / updated P1 cells and their unlock scripts.
* outputs: the set of outputs, including all the newly created P1 cells.

The `deps` and `inputs` in CKB Transactions make it easier for nodes to determine the dependency relationships between transactions. (see figure 4). Transactions can include many types of Cells for atomic cross type operations. 

The design of CKB Cell model and transactions is friendly to light clients. Since all the states are in the blocks, the block synchronization also accomplishes state synchronization. Light clients only need to synchronize blocks, and don't need to perform state transition computations. If we only stored events in blocks, then we would've needed full nodes to support state synchronization. This can be difficult for large deployments, for the lack of incentives inside the blockchain protocol. In protocol state synchronization makes light clients and full nodes more on the same level, leading to a more robust and decentralized system. 

![Figure 4. Transaction Parallelism and Conflict Detection](fig4.png)
> Figure 4. Transaction Parallelism and Conflict Detection


## Generator

Generators are programs to create new Cells for given type definitions. Generators run on the client that starts a transaction. It uses user inputs and existing Cells as inputs, and create new Cells with new states. Transactions are comprised of the inputs and the outputs of generators, and the Cell unlock scripts. (see Figure 5)

Validator and Generator and use the same algorithms or different algorithms ([Overview](#overview)). Generator can take one of more types of Cells as inputs, and can generate one of more types of Cells as outputs.

Validators and Generators are pure functions. Their computation only depends on the inputs. There's no state in the functions.

By defining Data Schemas, Validators and Generators, we can implement any common knowledge's validation and storage in the CKB. For example, we can define a new type for `AlpacaCoin`:

```javascript
Data Schema = {amount: "uint"}

// pseudo code of checker check():
// 1. confirm all inputs have valid and unlocked data
// 2. Compute the sum of all AlpacaCoin amounts in inputs - IN
// 3. Compute the sum of all AlpacaCoin amounts in outputs - OUT
// 4. Compare the equality of IN and OUT and return the result

Validator = validate(context ctx, inputs, outputs)

// pseudo code of generator gen():
// 1. Find all Cells of the AlpacaCoin type that the user can spend 
// 2. Generate new AlpacaCoin type Cells that belong to the receiver and the change Cells back to the sender. 
// 3. Return a list of all used Cells and created Cells. Those Cells are going to be used to create the transaction.
Generator = gen(context ctx, address to, uint amount, ...)
```

![Figure 5. Transaction and Cell Generation/Validation](fig5.png)
<div align="center">Figure 5. Transaction and Cell Generation/Validation</div>

### Layered Network

In the Nervos network, CKB and the Generators form a layered network. The CKB stores the common knowledge, and the Generators generate the common knowledge. CKB only cares about new states from the Generators, and doesn't care about how they are generated. Therefore generators can be implemented in many different ways.

The layered architecture separates data and computation, giving each layer flexibility, extensibility and the option to use different consensus algorithms. The CKB is the bottom layer with the most consensus. It's the foundation of the Nervos network. Applications have their own scope for consensus. Forcing all applications to use CKB's consensus will lead to low efficiency. In the Nervos network, application participants can choose appropriate generators based on their scope of consensus. They only need to submit states to the CKB to gain global confirmation when they need to interact with other services outside of the local consensus.

* Client side:

    The generators run directly on the client's devices. The generation algorithms can be implemented with light client interfaces or client libraries in any programming languages.

* State services:

    Users can use centralized services to create new states with server side generation algorithms. All current Internet services can work with the CKB through state services, making the state data of the services more trustworthy and more liquid to trade. For example, game companies can use state services to run the game logics in centralized services to generate artifacts, and define rules such as all artifact types and their total amounts on the blockchain to register and notarize them.

    Combined with the Nervos Identity Protocol, information publishers can provide trustworthy Oracles based on identities, to provide necessary information for other services in the Nervos network.

* State channels:

    Two or more users can use peer to peer communication channels to create new states. Participants of the state channels can register on the CKB and obtain information of other participants. One participant can provide security deposit on the CKB, to gain the trust of other participants on the security of the state channel. The state channel and the participants can use threshold signatures, traditional distributed consensus, or secure multi-party computation technologies to create new states. 

* Application chains:

    A blockchain to generate new states on the CKB. Application chains can be public chains (such as any EVM blockchain) or permissioned chains (such as CITA or Hyperledger Fabric). Permissioned chains can limit state computation to protect privacy and gain better performance. In application chains, participants perform computation together and validate with each other, before they submit the new state into the CKB to become more accepted common knowledge.

![Figure 6. Layered Structure](fig6.png)
<div align="center">Figure 6. Layered Structure</div>

## Distributed Application

With the combination of Cell, Type, Validator, Generator and Identity, CKB implements a new distributed application paradigm different from smart contracts. We define the internal logic of distributed applications with Generators and Validators; We send data and validation logic to the CKB through Type'ed transactions; We use Generators to create transactions to update application states through their Cells, with the operations defined in the Types. Cell lock scripts and Identity provide a powerful authorization scheme for the contracts.

The components of CKB distributed applications are decoupled and orthogonal. Users can design applications for different use cases with greater flexibility combining the componnets provided by the CKB.


## Hybrid Consensus

Consensus algorithms aim to optimize correctness and performance in an distributed environment with network delay and faults on nodes. Correctness includes consistency (identical copy of data on each node) and availability (how fast the system responds to user's requests). Performance includes transaction latency (the time between the client submits the request and receives confirmation of the execution result) and transaction throughput (number of transactions the system is capable of process per second).

Public blockchains run in open, distributed networks where nodes can join and exit freely, and there's no certainty on when they're online. Those are difficult problems for traditional BFT consensus algorithms to solve. Public blockchain consensus algorithms use economic incentives and probability to solve these problems, therefore needing openness and and fairness to guarantee correctness. Openness allows nodes to join and exit the network freely, and fairness ensures nodes get fair returns for their effort to keep the network safe. Public blockchain consensus algorithms also need to consider operational cost as part of their performance metrics.

The Nakamoto Consensus, with Bitcoin's Proof of Work as an example, has excellent openness and availability. Nodes in the Bitcoin network can join and exit freely, and the network performance remains constant with the number of nodes increasing. However the Nakamoto Consensus has low throughput. The Bitcoin network's 7 transactions / second throughput can't handle the demands of typical business scenarios. Even with side channel technologies (like the lightening network) where most of the transactions can happen off chain, the opening and closing of channels are still constraint by the throughput of the main chain. The safety of side channels can be compromised when the main chain is crowded. The Nakamoto Consensus votes with blocks, and it takes longer (up to 10 minutes to an hour) to confirm transactions, leading to bad user experience. When there's a network partition, the Bitcoin network can continue to function, but can't guarantee whether the transactions will be confirmed, therefore won't be suitable for business scenarios requiring high degree of finality. 

After 30 years of research, the Byzantine Fault Tolerance consensus algorithms can achieve throughput and transaction confirmation speed on par with centralized systems. However, it's difficult for nodes to join or exit dynamically, and the network's performance decreases rapidly with the increased number of consensus participating nodes. Traditional BFT consensus algorithms don't tolerant network faults well. When the network partitions, nodes can't achieve consensus and the network loses liveliness, making it difficult to meet the availability requirements of public blockchains.

Through our own experience and research, we've come to realize that the traditional BFT algorithms functions well with simple logic in normal situations, but need complicated logic to deal with fault situations; Nakamoto Consensus algorithm functions with the same logic under either normal or fault situations, at the expense of happy path system performance. If we could combine the Nakamoto Consensus and traditional BFT consensus algorithms, the new hybrid Consensus algorithm can give the best balance in consistency, availability, fairness and operational cost [3][4].

We will design and implement our own hybrid consensus algorithm to provide validation for transactions. By combining the Nakamoto Consensus and the traditional BFT consensus, we can retain the system's openness and availability, and take advantage of the excellent of performance of traditional BFT consensus algorithms under normal conditions. This minimizes transaction latency and greatly improves throughput of the system.

The hybrid algorithm uses Cell Capacity as the token of participation. Nodes that wish to participate in the consensus process need to bond Cell Capacity as deposit. The system uses the bond Cell Capacity to calculate the weights of votes and block reward distribution. If byzantine behaviors are observed on consensus nodes, other nodes can submit proof to the blockchain, and the system will confiscate the deposit of the byzantine node. The deposit mechanism increases the cost of byzantine behaviors and increase the safety of the consensus algorithm.

Please see the CKB Consensus Paper for more details on the hybrid consensus.

## Economics

The economic model is the "soul" of a public blockchain project. Bitcoin solved the open network's consensus challenge for the first time with the introduction of economic incentives. Every blockchain network is an autonomous community bound together with economic incentives. A good well designed economic model can incentivize all participants to contribute to the success of the community and maximize the utility of the blockchain.

CKB's economic model aims to motivate users, developers and node operators to work towards the common goal of common knowledge formation and storage. CKB's economic model is designed with its focus on states, using Cell Capacity block rewards and transaction fees as incentives.

The creation and storage of states on the CKB incur cost. The creation of state needs to be validated by full nodes, which takes computation resources; the storage of state needs full nodes to keep providing storage space. The current public blockchains only charge one time transaction fees, and allow the data from the transactions to be saved forever on the nodes, occupying storage space.

In the CKB, Cells are the storage units for states. Unoccupied Cells are liquid and their ownerships can be transferred. Occupied Cells aren't liquid and their ownerships can't be changed. Therefore, Cell users pay for the cost of their state storage with Cell liquidity. The longer they use the Cells, the higher liquidity cost they pay. The advantage of paying with liquidity, instead of pre-payment, is that it avoids the problem that the system would have to recycle the Cells if their pre-payments were exhausted.

The price of Cell Capacity is the direct measurement of the common knowledge stored in the CKB. Note that Cells could have different owners and users, and owners can pay the liquidity cost on behalf of users. Transaction fees are needed to update the data in Cells or transfer ownership of Cells. Nodes can set the transaction fee levels that they're willing to accept. Transaction fees are determined by the market. Owners can also pay for transition fees for the users.

Another important reason why it's difficult for mainstream users to use blockchains is that transaction fees have to paid with native coins. This requires users to acquire the native coins before using the services of the blockchain, raising the barrier of adoption. On the other hand, users are familiar with the business model of free basic services and paid premium services. Requiring fees for all transactions makes it difficult for users to adopt the technology. By allowing Cell owners to pay for users, CKB solves both of the problems above, and opens up more business model choices to developers.

The majority of system transaction fees go to the block creating nodes. The rest of the fees go to an account managed by the Nervos Foundation, using on the research, development and operations of the Nervos network. The ratio of this transaction fee distribution is determined by the liquid voting ([Liquid Voting](#liquid_voting)) process.

In addition to paying for common knowledge's creation and storage, Cell Capacity can also be used for other purposes such as consensus deposit and liquid voting. The security of the CKB is directly related to the amount that full nodes deposit. The higher the total consensus deposit, the higher the cost will be for malicious behaviors, making the system as a whole more secure. Ensuring adequate consensus deposit, therefore system security, is one of the goals of Nervos' monetary policy. Adjusting inflation rate changes the risk free rate of return for consensus participants, in turn adjusting the participation rate of consensus nodes.

Please see the Nervos CKB Economic Paper for details of the economic model.

## Governance

As the foundation of the Nervos network, CKB has to evolve with the communities on top of it. It has to keep functioning while adjusting runtime parameters or performing bigger upgrades. We can see from history that innovation is stifled and the network becomes stagnant when the cost of achieving community agreement to upgrade the network is too high.

Therefore, CKB has built-in mechanisms for liquid voting and hot deployment, making the system a self evolving distributed network.

### Liquid Voting

The voting mechanism is important for the long term stability of the Nervos system. CKB's operation needs a set of system parameters. For example, CKB relies on a set of system parameters to function. While some of the parameters can be adjusted automatically, others may need voting. Fixing bugs or deploying new features may need voting.

CKB support liquid voting [5] (See figure 7). Every Cell owner, weighted by their Cell Capacity, can be part of the decisions that determine CKB's development. In liquid voting, users can set their own delegates. Delegates can also set their own delegates. Taking into account technicality and incentives, proposals can have different acceptance criteria, such as participation rates and support ratios.

Note that CKB's liquid voting is the tool to express community consensus, not to form consensus. Before the votes, the community should use various communication channels to study the proposals in detail and form rough consensus.

Please see the Nervos Governance Paper for the details of the liquid voting mechanism.

![Figure 7. Liquid Voting](fig7.png)
<div align="center">Figure 7. Liquid Voting</div>

### Neuron

Benefiting from the Cell data model's abstraction power, we can implement and store CKB's function modules in Cells. We call this type of Cells the Neuron. The users of the Neuron Cells are the CKB itself.

When system upgrade proposals are implemented as Neurons, the community vote on if they should be deployed with the liquid voting mechanism. After obtaining consensus from the community, new Neurons will be deployed to provide new features or fix bugs. Fine grained Neuron upgrades significantly lower the barrier of evolution for the CKB.

## Light Client

The blockchain architecture where nodes are equal peers is currently facing serious challenges. On public blockchains, the hardware performance of nodes varies. Equal peer architecture demands consistent and highly performant hardware, otherwise it won't maximize the full performance potential of the network. More users are giving up running full nodes and choosing to run light clients or centralized clients. Full nodes validate all blocks and transaction data, requiring minimum external trust. But they are costly and inconvenient to run. Centralized clients give up validations and rely entirely on the central servers to provide data. Light clients put trust on the full nodes to reduce the cost of validation and consensus, and provide better user experience.

Mobile devices are becoming the main way people access the Internet. Native applications are also becoming more popular. Mobile friendliness is one of the design principles of the CKB. Nervos applications should be able to run smoothly on mobile devices and integrate with mobile platforms.

CKB supports light clients. CKB uses verifiable data structure for the block headers, which substantially accelerates the synchronization of light clients. Benefiting from CKB's state centric design, light clients can obtain latest states (P1CS) without having to repeat the computation. Light clients can also only subscribe to a small subset of P1 Cells that they care about, minimizing local storage and bandwidth requirements. Nervos' light clients can provide excellent local user experience, allowing CKB queries, messaging and other functionality, allowing mobile applications benefiting from the blockchain technologies.

## Summary of Benefits

We believe Nervos CKB provides an exciting alternative to the current general purpose computing platform blockchains. We summarize here its benefits over the current leading platforms in scalability, available and multi-paradigm support.

### Scalability

Nervos CKB's design provides significant advantages on scalability, compared to a smart contract platform like Ethereum. We only concern ourselves with the scalability discussions on the full nodes here, since that's where the bottleneck would be for both systems.

- Reads
  - CKB's light clients have local state, therefore don't need to query full nodes for state. We believe this is crucial in the future where most clients are light clients on mobile devices.

- Transactions:
  - CKB uses a consensus algorithm that has very high throughput on happy path scenarios.
  - Validations on nodes can be processed in parallel, providing a scale-up path when computation becomes the bottleneck.
  - Easier to use sharding as a solution to scale transactions with the explicit dependency requirement
  - State generation can move to state channels or application chains and only settle on the main chain, providing a application semantics based scaling path.

- Data:
  - Nervos CKB's design to move P2CS to achive nodes and leave only P1CS on full nodes, allowing storage needs to scale with the size of current states, instead of all historical states
  - The economic model provides a marketplace solution to recycle low value Cells to make available for higher value applications.
  - Easier to use sharding as a solution to scale on-chain data with explicit dependency requirement.

### Latency and Availability

  - CKB's states are stored locally on the clients. This makes the data highly available to local applications with minimal latency.
  - Low latency and highly available local data allows "offline first DApps". In this scenario, applications can compute new states, validate them and generate transactions all locally. Then as soon as the transaction is created, the application can move to the next task, without having to wait for the transaction to be included in a block, providing a much more pleasant user experience. The actual synchronization can happen later on the background, or when there's stable network connection.

### Multi-paradigm

CKB's Cells, Types and transactions together provide the foundation for a versatile decentralized state machine. The Generators and Validators can be used to express any business rules. Identities can be used to bring in trust and bridge to real world applications. Together, they're a powerful combination of components that can be used to build different types of applications. For example:

- Digit assets and ledgers: put account or UTXO data in Cells, and provide a strict Validator to govern value transfer rules.
- Ethereum like smart contracts: define a "smart contract" Type, then create a transaction with contract code as validation code. On the client side, run symmetric generation function to generate new states.
- Trust base transactions: Identities can define who they're willing to trust, then application can interpret that trust relationship to facilitate transactions.
- Cross chain asset transfer: application chains generate digital assets backed by assets on other chains. The backed assets can then participate in transactions, or transfer to the main chain to gain more security. The assets can then be transferred to other chains or back to their original chain. Users who participate in the transaction need to express trust in the Identity of the operator of the bridge service.

## References

1. Alonzo Church, Lambda calculus, 1930s
2. Satoshi Nakamoto, “Bitcoin: A Peer-to-Peer Electronic Cash System”, 2008
3. Vitalik Buterin, Virgil Griffith, “Casper the Friendly Finality Gadget”, 2017
4. Rafael Pass, Elaine Shi, “Thunderella: Blockchains with Optimistic Instant Confirmation”, 2017
5. Bryan Ford, “Delegative Democracy”, 2002

-----------
Compared to the imperative, state transition procedure focused smart contracts, CKB separates new state computation and state mutation, allowing programmers to use composition of pure functions for the computation, and provide a set of built-in primitives for state transition.

Declarative State Transition



--------


## Motivation

“The various ways in which the knowledge on which people base their plan is communicated to them is the crucial problem for any theory explaining the economic process, and the problem of what is the best way to utilizing knowledge initially dispersed among all the people is at least one of the main problems of economic policy - or of designing an efficient economic system.” - Friedrich A. Hayek

??

?? The blockchain may be an answer. With the blockchain, algorithms and machines replace humans to automate the formation and dissipation of common knowledge. We believe blockchains can be seen as a new type of technology as the "Common Knowledge Base". The formation and dissipation of common knowledge is the core value of blockchains, and is also the reason there can be tokens and cryptoeconomics.

Nervos CKB is conceived based on this recognition: a new blockchain design, a **general purpose common knowledge base**. We hope Nervos CKB can solve problems in performance, privacy and usability that we see in the current generation of blockchains, to become the common knowledge base of 7.6 billion people.

## Common Knowledge Base

### Common Knowledge

Common Knowledge is knowledge that's accepted by everyone in a community. Participants in the community not only accept the knowledge themselves, but know that others in the community also accept the knowledge. Generally, by the way they are formed, there can be three types of common knowledge:

The first type of common knowledge can be independently verified with abstract algorithms. For example, the assertion that "11897 is a prime number" can be independently verified with a primality test algorithm. In this context, the statement can become a piece of common knowledge, regardless whether the person who makes the assertion can be trusted.

The second type of common knowledge relies on a delegated verification process, typically to a trusted authority. For example, science discoveries require empirical evidence, in the forms of peer review and result reproducibility, to be accepted as common knowledge of the science community.The general public doesn't have the ability on their own to verify the evidence, but delegates their trust to the science community.

The third type of common knowledge requires a trusted party, and it's pervasive in business transactions. For a piece of data to become common knowledge to facilitate transactions, the participants of transactions have to all trust the party that backs the data. For example, in a centralized exchange, transactions imply trust on the exchange, thereby the accuracy of its data feed and the fairness of its match making algorithm. In the credit card point of sale context, the consumer and the business can complete a transaction based on their mutual trust on the financial intermediaries such as banks and credit card companies.


### Blockchains are Common Knowledge Bases

??? In the past, the common knowledge is scattered in people's heads, and its formation requires repeated communications and confirmations. Today with the advancement of cryptography and distributed ledger technologies, algorithms and machine are replacing humans as the medium for the formation and storage of common knowledge. Every piece of data in the blockchain, including digital assets and smart contracts, is a piece of common knowledge. They've

**Blockchain systems** are common knowledge bases. Participating in a blockchain network implies accepting and helping validate the common knowledge in the network. Transactions are stored in the blockchain, together with their proofs. Users of the blockchain can trust the validity of the transactions, and know other users trust it too.

### General Purpose Common Knowledge Base

A general purpose common knowledge base that's suitable for generation and storage of all types of common knowledge should have the following features:

* State focused, not event focused
* Data model that's generic enough, with enough abstraction power that users can use to express the business domain
* The validation engine of common knowledge that's generic enough with enough abstraction power that users can use to express data validation rules.

If distributed ledgers are the "settlement layer" of digital assets, general purpose common knowledge bases are the "settlement layer" of all types of common knowledge. The goal of Nervos CKB is to become the common state layer of the entire Nervos Network as a general purpose common knowledge base. It provides the state foundation of upper layer applications, to facilitate transactions.
