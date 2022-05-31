---
Number: "0001"
Category: Informational
Status: Final
Author: The Nervos Team
Created: 2019-09-12
---

# The Nervos Network Positioning Paper

## 1. Purpose of This Paper

The Nervos Network is made up of a number of protocols and innovations. It's important to have clear documentation and technical specifications on key protocol design and implementations - for which we utilize an [RFC](https://github.com/nervosnetwork/rfcs) (request for comment) process. However, we feel it's equally important that we help our communities to understand what we try to accomplish, the trade-offs we have made, and how we have arrived at our current design decisions.

We start this document with a detailed examination of the problems that public permissionless blockchains face today and the existing solutions attempting to solve them. We hope this provides the necessary context for our readers to understand our own rationale on how best to approach these challenges, and our underlying design decisions. We then provide a high-level walkthrough of all parts of the Nervos Network, with a focus on how they work together to support the overall vision of the network.

## 2. Background
 
Scalability, sustainability and interoperability are among the largest challenges public permissionless blockchains face today. While many projects claim to have solutions to these problems, it's important to understand where these problems come from and put solutions in the context of possible trade-offs.

### 2.1 Scalability

Bitcoin[1] was the first public permissionless blockchain, designed to be used as peer-to-peer electronic cash. Ethereum[2] made more use cases possible and created a general purpose decentralized computing platform. However, both of these platforms impose limitations on their transaction capabilities - Bitcoin caps its block size and Ethereum caps its block gas limit. These are necessary steps to ensure long-term decentralization, however they also limit the capabilities of both platforms. 

The blockchain community has proposed many scalability solutions in recent years. In general, we can divide these solutions into two categories: on-chain scaling and off-chain scaling.

On-chain scaling solutions aim to expand the throughput of the consensus process and create blockchains with native throughput that rivals centralized systems. Off-chain scaling solutions only use the blockchain as a secure asset and settlement platform, while moving nearly all transactions to upper layers.

#### 2.1.1 On-chain Scaling with a Single Blockchain

The most straightforward way to increase the throughput of a blockchain is to increase its supply of block space. With additional block space, more transactions can flow through the network and be processed. Increasing the supply of block space in response to increased transaction demand also allows for transaction fees to remain low.

Bitcoin Cash (BCH) adopts this approach to scale its peer-to-peer payment network. The Bitcoin Cash protocol began with a maximum block size of 8 MB, which was later increased to 32 MB, and which will continue to be increased indefinitely as transaction demand increases. For reference, following Bitcoin's (BTC) implementation of Segregated Witness in August 2017, the Bitcoin protocol now allows for an average block size of around 2 MB.

In the scope of a datacenter, the math works out. If 7.5 billion people each create 2 on-chain transactions per day, the network will require production of 26 GB blocks every 10 minutes, leading to a blockchain growth rate of 3.75 TB per day or 1.37 PB per year[3]. These storage and bandwidth requirements are reasonable for any cloud service today.

However, constraining node operation to a datacenter environment leads to a single viable network topology and forces compromises in security (the fork rate of the blockchain will increase as data transmission requirements across the network increase), as well as decentralization (the full node count will be reduced as the cost of consensus participation increases).

From an economic standpoint, an ever-increasing block size does alleviate fee pressure felt by users. Analysis of the Bitcoin network has shown that fees remain flat until a block is about 80% full, and then rise exponentially[4].

Though placing the burden of a growing network's costs on its operators may seem to be a reasonable decision, it could be short-sighted for two reasons: 

- Suppression of transaction fees forces miners to rely predominantly on compensation from new coin issuance (block rewards). Unless inflation is a permanent part of the protocol, new coin issuance will eventually stop (when the total coin hard-cap is reached), and miners will receive neither block rewards nor significant transaction fees. The economic impact of this will severely compromise the security model of the network.
- The cost of running a full node becomes prohibitively expensive. This removes the ability of regular users to independently verify a blockchain's history and transactions, forcing reliance on service providers such as exchanges and payment processors to ensure the integrity of the blockchain. This trust requirement negates the core value proposition of public permissionless blockchains as peer-to-peer, trustless distributed systems. 

Transaction cost optimized platforms such as Bitcoin Cash face significant competition from other blockchains (permissioned and permissionless), as well as traditional payment systems. Design decisions that improve security or censorship resistance will incur associated costs and in turn increase the cost of using the platform. Taking into account a competitive landscape, as well as the network's stated objectives, it is likely that lower costs will be the overarching goal of the network, at the expense of any other considerations.

This goal is consistent with our observations of transactional network usage. Users of these systems are indifferent to significant long-run trade-offs because they will only utilize the network for a short time. Once their goods or services have been received and their payment has been settled, these users no longer have any concern for the network's effective operation. The acceptance of these trade-offs is apparent in the widespread use of centralized crypto-asset exchanges, as well as more centralized blockchains. These systems are popular primarily for their convenience and transactional efficiency.

Some smart contract platforms have taken similar approaches to scaling blockchain throughput, allowing only a limited set of "super computer" validators to participate in the consensus process and independently validate the blockchain.

Though compromises in regard to decentralization and network security allow for cheaper transactions and may be convenient for a set of users, the compromised long-term security model, cost barrier to independently verify transactions, and the likely concentration and entrenchment of node operators lead us to believe that this is not a proper approach for scaling public blockchains.

#### 2.1.2 On-chain Scaling through Multiple Chains

On-chain scaling through multiple chains can be accomplished through sharding, as seen in Ethereum 2.0, or application chains, as seen in Polkadot. These designs effectively partition the global state and transactions of the network into multiple chains, allowing each chain to quickly reach local consensus, and later the entirety of the network to reach global consensus through the consensus of the "Beacon Chain" or the "Relay Chain".

These designs allow the multiple chains to utilize a shared security model, while allowing high throughput and fast transactions inside shards (Ethereum) or para-chains (Polkadot). Though each of these systems is a network of interconnected blockchains, they differ in regard to the protocols running on each chain. In Ethereum 2.0, every shard runs the same protocol, while in Polkadot, each para-chain can run a customized protocol, created through the Substrate framework.

In these multi-chain architectures, each dApp (or instance of a dApp) only resides on a single chain. Though developers today are accustomed to the ability to build dApps that seamlessly interact with any other dApp on the blockchain, design patterns will need to adapt to new multi-chain architectures. If a dApp is split across different shards, mechanisms will be required to keep state synced across different instances of the dApp (residing on different shards). Additionally, though layer 2 mechanisms can be deployed for fast cross-shard communication, cross-shard transactions will require global consensus and introduce confirmation latency. 

With these asynchronous transactions, the infamous "train-and-hotel" problem arises. When two transactions must be atomic (for example booking a train ticket and a hotel room on two different shards), new solutions are required. Ethereum introduces contract "yanking", in which a dependent contract is deleted on one shard, created on a second shard (that contains the other dependent contract), and both transactions are then executed on the second shard. However, the yanked contract would then be unavailable on the original shard, introducing usability issues, and again requiring new design patterns.

Sharding has its own advantages and challenges. If shards can be truly independent and cross-shard needs are minimal, a blockchain can linearly scale its throughput by increasing the number of shards. This is best suited for self-contained applications that don't require outside state or collaboration with other applications. 

A sharded architecture can be problematic for applications that are developed by composing together "building block" applications (this is known as the "composability problem"). Composability is especially relevant in the decentralized finance (DeFi) space, where more advanced products tend to be built on top of other building block products. 

On a more technical note, sharding typically requires a "1 + N" topology, in which N chains connect to one meta-chain, introducing an upper bound on the number of shards a meta-chain can support without itself running into scalability issues.

We observe significant value in a unified global state, allowing an ecosystem of interdependent applications to emerge and developers to innovate at the edges, similar to web developers' use of libraries for lower-level concerns and open APIs for service integration. A much simpler development experience is enabled when developers don't have to consider synchronicity (in cross-shard asset transfer or messaging passing), as well as a superior user experience, resulting from consistency in the architectural concerns of blockchain interactions.

We recognize that sharding is a promising scalability solution (in particular for less interdependent applications), however we believe it is beneficial to have a design that concentrates the most valuable state on a single blockchain, allowing composability. With this design, off-chain scaling approaches are utilized to allow for higher throughput.  

#### 2.1.3 Off-chain Scaling through Layer 2

In layer 2 protocols, the base layer blockchain acts as a settlement (or commitment) layer, while a second layer network routes cryptographic proofs that allow participants to "take delivery of" the cryptocurrency. All activities of the second layer are cryptographically secured by the underlying blockchain and the base layer is only used to settle amounts entering/exiting the second layer network, and for dispute resolution. These designs operate without delegation of custody (or risk of loss) of funds and enable instant, nearly free transactions. 

These technologies demonstrate how a store of value network such as Bitcoin could be used for everyday payments. The most typical example of a layer 2 solution in practice is a payment channel between a customer and a coffee shop. Let's assume Alice visits the Bitcoin Coffee Shop every morning. At the beginning of the month, she deposits funds into a Lightning payment channel she has opened with the coffee shop. As she visits each day, she cryptographically signs the coffee shop's right to take some of the funds, in exchange for her coffee. These transactions happen instantly and are completely peer-to-peer, "off-chain", allowing for a smooth customer experience. The Lightning channel is trustless, Alice or the coffee shop can close the channel at any time, taking the funds they are owed at that time. 

Payment channel technologies such as Lightning are only one example of an off-chain scaling technique; there are many maturing technologies that can safely scale blockchain throughput in this way. While payment channels include off-chain agreements to channel balances between two parties, state channels include off-chain agreements to arbitrary state between channel participants. This generalization can be the basis of scalable, trustless, decentralized applications. A single state channel can even be utilized by multiple applications, allowing for even greater efficiency. When one party is ready to exit the channel, they can submit the agreed upon cryptographic proof to the blockchain, which will then execute the agreed state transitions.

A side-chain is another construction that allows for increased throughput, though via trusted third party blockchain operators. With a two-way peg to a blockchain with reliable, trustless consensus, funds can be moved back and forth between the main-chain and side-chain. This allows for a high volume of trusted transactions on the side-chain, with later net settlement on the main-chain. Side-chain transactions have minimal fees, fast confirmation and high throughput. Though side-chains offer a superior experience in some regard, they do compromise on security. There is however, a great deal of research into trustless side-chains, which can provide the same performance improvements without compromising security.

An example of a trustless side-chain technology is Plasma (covered in 5.4), a side-chain architecture that leverages a trust root on a blockchain with broad global consensus. Plasma chains offer the same performance improvements as centralized side-chains, however do so while offering security guarantees. In the event a Plasma chain operator is malicious or malfunctioning, users are provided a mechanism that allows them to safely withdraw their side-chain assets to the main-chain. This is done without the cooperation of the Plasma chain operator, offering users the convenience of side-chain transactions, as well as the security of a layer 1 blockchain.

Off-chain scaling allows for decentralization, security and scalability. By moving everything except settlement transactions and disputes off-chain, a public blockchain's limited global consensus is efficiently utilized. Diverse layer 2 protocols can be implemented based on application requirements, affording flexibility to developers and users. As more participants are added to the network, performance is not impacted and all parties can share the security guarantees offered by layer 1 consensus.

### 2.2 Sustainability

Sustaining the long-term operation of an autonomous, ownerless public blockchain presents quite the challenge. Incentives must be balanced among diverse stakeholders and the system must be designed in a way that allows for widespread full node operation and public verifiability. Hardware requirements must remain reasonable, while supporting an open, global network.

Additionally, once a public blockchain is in operation, it is very difficult to change the underlying rules governing the protocol. From the start, the system must be designed to be sustainable. In this interest, we have conducted a thorough inventory of the challenges in building sustainable, permissionless blockchains.

#### 2.2.1 Decentralization

One of the largest long-term threats public blockchains face is an ever-increasing barrier of independent participation and transaction verification, reflected in the cost of full node operation. Full nodes allow blockchain participants to independently verify the on-chain state/history, and hold miners or validators of the network accountable by refusing to route invalid blocks. As the cost of full nodes increases and their numbers decline, participants in the network are increasingly forced to rely on professional service operators to provide both history and current state, eroding the fundamental trust model of open and permissionless blockchains. 

For a full node to keep up with the progression of the blockchain, it must have adequate computational throughput to validate transactions, bandwidth throughput to receive transactions, and storage capacity to store the entire global state. To control a full node's operating cost, the protocol has to take measures to bound the throughput or capacity growth of all three of these resources. Most blockchain protocols bound their computational or bandwidth throughput, but very few bound the growth of the global state. As these chains grow in size and length of operation, full node operation costs will irreversibly increase.

#### 2.2.2 Economic Models

While there has been a lot of research into consensus protocols in recent years, we believe crypto-economics is an understudied field. Broadly speaking, current crypto-economic models for layer 1 protocols are primarily focused on incentives and punishments to ensure network consensus, and native tokens are mostly used to pay transaction fees or to satisfy staking requirements that provide Sybil resistance.

We believe that a well-designed economic model should go beyond the consensus process and ensure the long-term sustainability of the protocol as well. In particular, the economic model should be designed with the following goals:

- the network should have a sustainable way to compensate service providers (typically miners or validators), ensuring that the network remains sustainably secure
- the network should have a sustainable way to maintain a low barrier to participation, ensuring that the network remains decentralized over time
- the resources of the public network should be efficiently and fairly allocated
- the blockchain's native token must have intrinsic value

#### 2.2.3 Analysis of Bitcoin's Economic Model

The Bitcoin protocol caps the size of blocks and enforces a fixed block time. This makes the network's bandwidth throughput a scarce resource that users must bid on through transaction fees. Bitcoin Script doesn't allow loops, making the length of the script a good approximation of its computational complexity. In general, greater demand for block space translates into higher transaction fees for users. Additionally, the more inputs, outputs or computational steps that are involved in a transaction, the more a user will also pay in transaction fees.

The intrinsic value of Bitcoin comes almost entirely from its monetary premium (society's willingness to treat it as money) and in particular, the willingness to hold it as a store of value. Because miner income is denominated in BTC, this perception has to hold for Bitcoin's economic model to be sustainable. In other words, Bitcoin's security model is circular - it depends on the collective belief that the network is sustainably secure and can therefore be used as a monetary store of value.

Bitcoin's block size cap effectively sets the barrier for network participation - the lower the block size cap is, the easier it is for non-professionals to run full nodes. The Bitcoin global state is its UTXO set, with its growth rate also effectively capped by the block size limit. Users are incentivized to create and utilize UTXOs efficiently; creating more UTXO's translates into higher transaction fees. However, no incentives are provided to encourage combining of UTXOs and reduction of the size of the global state; once a UTXO is created, it will occupy the global state for free until it is spent.

Bitcoin's transaction fee-based economic model is a fair model to allocate its bandwidth throughput, the scarce resource imposed by the protocol. It's a suitable economic model for a peer-to-peer payment system, but is a poor choice for a true store of value platform. Bitcoin users that utilize the blockchain to store value pay transaction fees only once, but can then occupy state forever, enjoying ongoing security provided by miners, who are required to make continuous resource investments.

Bitcoin has a total supply hard-cap and its new issuance via block rewards will eventually drop to zero. This could cause two problems:

First, if Bitcoin continues to succeed as a store of value, the unit value of BTC will continue to increase, and the total value the network secures will also increase (as more monetary value moves on to the network). A store of value platform has to be able to raise its security budget as the value it protects increases over time, otherwise, it invites attackers to double spend and steal the assets of the network. 

When the cost to break protocol security is less than the profit they can earn acting honestly, attackers will always attack. This is analogous to a city that has to raise its military spending as the wealth inside the city increases. Without this investment, sooner or later the city will be attacked and looted. 

With the existence of block rewards, Bitcoin is able to scale security to the aggregate value it stores - if Bitcoin's price doubles, the income that miners receive from block rewards will also double, therefore they can afford to produce twice the hash rate, making the network twice as expensive to attack. 

This however changes when the predictable block rewards drop to zero. Miners will have to rely entirely on transaction fees; their income will no longer scale to the value of the Bitcoin asset, but will be determined by the transaction demand of the network. If transaction demand is not high enough to fill the available block space, total transaction fees will be minuscule. Since transaction fees are strictly a function of block space demand and independent from the price of a Bitcoin, this will have a profound impact on Bitcoin's security model. For Bitcoin to remain secure, we'd have to assume consistent, over-capacity transaction demand, that also scales to the price of Bitcoin. These are very strong assumptions. 

Second, when the predictable block rewards stop, variance in per block income for miners increases, and provides incentives for miners to fork, instead of advancing the blockchain. In the extreme case, when a miner's mempool is empty and they receive a block loaded with fees, their incentive is to fork the chain and steal the fees, as opposed to advancing the chain and producing a block with potentially no income[5]. This is known as the "fee sniping" challenge in the Bitcoin community, to which a satisfying solution has not yet been found, without removing Bitcoin's hard-cap.

#### 2.2.4 Analysis of the Economic Model of Smart Contract Platforms

The typical economic model of smart contract platforms faces even more challenges. Let's use Ethereum as an example. Ethereum's scripting allows loops, therefore the length of a script doesn't reflect the script's computational complexity. This is the reason Ethereum doesn't cap block size or bandwidth throughput, but computational throughput (expressed in the block gas limit).

To get their transactions recorded on the Ethereum blockchain, users bid on the per computation cost they're willing to pay in transaction fees. Ethereum uses the concept of "gas" as measurement of computational cost priced in ETH, and the "gas price" rate control ensures that the cost per step of computation is independent of price movements of the native token. The intrinsic value of the ETH token comes from its position as the payment token of the decentralized computation platform; it is the only currency that can be used to pay for computation on Ethereum.

Ethereum's global state is represented with the EVM's state trie, the data structure that contains the balances and internal state of all accounts. When new accounts or contract values are created, the size of the global state expands. Ethereum charges fixed amounts of gas for insertion of new values into its state storage and offers a fixed "gas stipend" that offsets a transaction's gas costs when values are removed. 

A "pay once, occupy forever" storage model doesn't match the ongoing cost structure of miners and full nodes, and the model provides no incentive for users to voluntarily remove state or remove state sooner. As a result, Ethereum has experienced rapid growth of its state size. A larger state size slows down transaction processing and raises the operating cost of full nodes. Without strong incentives to clear state, this is a trend that's bound to continue.

Similar to Bitcoin, Ethereum's demand-driven gas pricing is a fair model to allocate its computational throughput, the platform's scarce resource. The model also serves Ethereum's purpose as a decentralized computation system. However, its state storage fee model doesn't match its potential proposition as a decentralized state or asset storage platform. Without a cost for long-term state storage, it will always be in users' interests to occupy state forever for free. Without scarcity of state storage capacity, neither a market, nor supply and demand dynamics can be established. 

Unlike Bitcoin, which specifies the block size limit in its core protocol, Ethereum allows miners to dynamically adjust the block gas limit when they produce blocks. Miners with advanced hardware and significant bandwidth are able to produce more blocks, effectively dominating this voting process. Their interest is to adjust the block gas limit upward, raise the bar of participation and force smaller miners out of the competition. This is another factor that contributes to the quickly rising cost of full node operation.

Smart contract platforms like Ethereum are multi-asset platforms. They support issuance and transactions of all types of crypto-assets, typically represented as "tokens". They also provide security to not only their own native tokens, but the value of all crypto-assets on the platform. "Store of value" in a multi-asset context therefore refers to the value preservation property that benefits both the platform's native tokens and the crypto-assets stored on the platform.

With its block rewards, Bitcoin has an excellent "store of value" economic model. Miners are paid a fixed block reward denominated in BTC, and thus their income rises along with the price of BTC. Therefore, the platform has the ability to raise revenue for miners to increase security (measured by the cost of attack) while maintaining a sustainable economic model.

For multi-asset platforms, it becomes much more challenging to fulfill this requirement, because "value" can be expressed with crypto-assets beyond the native token. If the value of crypto-assets secured by the platform increases, but network security doesn't, it becomes more profitable to attack the platform's consensus process to double spend crypto-assets stored on the platform.

For a multi-asset smart contract platform to function as a store of value, proper incentives must be put in place to align in the growth in value of a network's assets with its underlying security. Or put another way, the platform's native token must be a good value capture of the platform's aggregate asset value. If the intrinsic value of a platform's native token is limited to transaction fee payment, its value would be determined solely by transaction demand, instead of the demand of asset storage.

Smart contract platforms that are not designed to function as a store of value have to rely on the native token's monetary premium (the willingness of people to hold the tokens beyond their intrinsic value) to support its ongoing security. This is only feasible if one platform dominates with unique features that can't be found elsewhere, or out-competes others by delivering the lowest possible cost of transactions.

Ethereum currently enjoys such dominance and can therefore maintain its monetary premium. However, with the rise of competing platforms, many designed for higher TPS and providing similar functionality, it's an open question as to whether reliance on a monetary premium alone can sustain a blockchain platform's security, especially if the native tokens are explicitly not designed or believed to be money. Furthermore, even if a platform can provide unique features, its monetary premium can be abstracted away by the user interface through efficient swaps (very likely when mass adoption of blockchain finally comes). Users would hold assets they're most familiar with, such as Bitcoin or stable coins, and acquire platform tokens just in time to pay for transaction fees. In either case, the foundation of a platform's crypto-economics would collapse.

Layer 1 multi-asset platforms have to provide sustainable security for all of the crypto-assets they secure. In other words, they have to have an economic model designed for a store of value.

#### 2.2.5 Funding of Core Protocol Development

Public permissionless blockchains are public infrastructure. Initial development of these systems requires a great deal of funding, and once they are in operation require ongoing maintenance and upgrades. Without dedicated people maintaining these systems, they run the risk of catastrophic bugs and sub-optimal operation. The Bitcoin and Ethereum protocols do not provide a native mechanism to ensure funding of ongoing development, thus rely on the continued engagement of businesses with aligned interests and altruistic open source communities. 

Dash was the first project to utilize a treasury to ensure ongoing development was funded in-protocol. While sustainably supporting the protocol's development, this design makes a compromise in regard to the sustainability of the value of the cryptocurrency. Like most blockchain treasuries, this model relies on inflation-based funding, which erodes the value of long-term holdings. 

The Nervos Network uses a treasury model that provides sustainable funding for core development. Treasury funds come from targeted inflation of short-term token holders, while the effects of this inflation are mitigated for long-term holders. More information about this mechanism is described in (4.6).

### 2.3 Interoperability

Interoperability across blockchains is an often-discussed topic, and many projects have been proposed specifically to address this challenge. With reliable transactions across blockchains, true network effects can be realized in the decentralized economy. 

The first example of blockchain interoperability was atomic swaps between Bitcoin and Litecoin. The trustless exchange of Bitcoin for Litecoin and vice-versa is made possible not through in-protocol mechanisms, but through a shared cryptographic standard (specifically usage of the SHA2-256 hash function).

Similarly, the design of Ethereum 2.0 allows for interconnection of many shard chains, all running the same protocol and utilizing the same cryptographic primitives. This uniformity will be valuable when customizing the protocol for inter-shard communication, however Ethereum 2.0 will not be interoperable with other blockchains that do not utilize the same cryptographic primitives.

Networks of blockchains such as Polkadot or Cosmos go one-step further, allowing blockchains built with the same framework (Cosmos SDK for Cosmos and Substrate for Polkadot) to communicate and interact with one another. These frameworks provide developers some flexibility in building their own protocols, and ensure the availability of identical cryptographic primitives, allowing each chain to parse one another's blocks and cross-validate transactions. However, both protocols rely on bridges or "pegging zones" to connect to blockchains that are not constructed with their own frameworks, introducing an additional layer of trust. To demonstrate: though Cosmos and Polkadot enable "networks of blockchains", the Cosmos and Polkadot networks are not designed to be interoperable with each other. 

The crypto-economics of cross-chain networks may need further study as well. For both Cosmos and Polkadot, native tokens are used for staking, governance and transaction fees. Putting aside the crypto-economic dynamics introduced by staking, which can't alone give a native token intrinsic value (discussed in 4.2.4), reliance on cross-chain transactions to capture ecosystem value can be a weak model. In particular, cross-chain transactions are a weakness, not a strength of multi-chain networks, just as cross-shard transactions are a weakness of sharded databases. They introduce latency, as well as the loss of atomicity and composability. There is a natural tendency for applications that need to interact with each other to eventually move to reside on the same blockchain to reduce cross-chain overhead, reducing the demand for cross-chain transactions and therefore demand for the native token.

Cross-chain networks benefit from network effects - the more interconnected chains there are in a network, the more valuable the network is, and the more attractive it is to potential new participants in the network. Ideally, such value would be captured by the native token and used to further encourage the growth of the network. However, in a pooled security network such as Polkadot, higher cost of network participation becomes a deterrent for the network to accrue further value. In a loosely connected network like Cosmos, if we assume same cross-chain transaction demand and fees, higher cost of staking participation lowers the expected return for validators, discouraging further staking participation.

With its layered approach, the Nervos Network is also a multi-chain network. Architecturally, Nervos uses the cell model and a low-level virtual machine to support true customization and user-created cryptographic primitives, enabling interoperability across heterogeneous blockchains (covered in 4.4.1). Crypto-economically, the Nervos Network concentrates value (instead of message passing) to its root chain. This mechanism raises the network's security budget as the aggregate value secured by the network rises. This is covered in detail in (4.4).

## 3. Core Principles of the Nervos Network

Nervos is a layered network built to support the needs of the decentralized economy. There are several reasons that we believe a layered approach is the right way to build a blockchain network. There are many well known trade-offs in building blockchain systems, such as decentralization vs. scalability, neutral vs. compliant, privacy vs. openness, store of value vs. transaction cost and cryptographic soundness vs. user experience. We believe that all of these conflicts arise because of attempts to address completely opposing concerns with a single blockchain. 

We believe that the best way to construct a system is not to build an all-encompassing single layer, but rather to decouple concerns and address them at different layers. By doing this, the layer 1 blockchain can focus on being secure, neutral, decentralized and open public infrastructure, while smaller, layer 2 networks can be specially-designed to best suit the context of their usage.

In the Nervos Network, the layer 1 protocol (the Common Knowledge Base) is the value preservation layer of the entire network. It is philosophically inspired by Bitcoin and is an open, public and proof of work-based blockchain, designed to be maximally secure and censorship-resistant, to serve as a decentralized custodian of value and crypto-assets. Layer 2 protocols leverage the security of the layer 1 blockchain to provide unbounded scalability and minimal transaction fees, and also allow for application-specific trade-offs in regard to trust models, privacy and finality.

Here are the core principles that led to the design of the Nervos Network:

- A sustainable, multi-asset layer 1 blockchain has to be crypto-economically designed to be a store of value.
- Layer 2 offers the best scaling options, bringing nearly unlimited transactional capabilities, minimal transaction costs and an improved user experience. Layer 1 blockchains should be designed to complement, not compete with layer 2 solutions.
- Proof of Work as a Sybil resistance method is essential for layer 1 blockchains.
- The layer 1 blockchain must provide a generic programming model for interactive protocols and blockchain interoperability, and to allow the protocol to be maximally customizable and easy to upgrade.
- To best allocate resources and avoid the "tragedy of the commons", state storage has to have a clear and fine-grained ownership model. To deliver consistent long-term rewards to miners (regardless of transaction demand), state occupation must have an ongoing cost.

## 4. The Nervos Common Knowledge Base

### 4.1 Overview

"Common knowledge" is defined as knowledge that is known by everyone or nearly everyone, usually with reference to the community in which the term is used. In the context of blockchains in general, and the Nervos Network in particular, "common knowledge" refers to state verified by global consensus and accepted by all in the network.

The properties of common knowledge allow us to collectively treat the cryptocurrency stored on public blockchains as money. For example, the balances and history of all addresses on Bitcoin are common knowledge for Bitcoin users, because they are able to independently replicate the shared ledger, verify the global state since the genesis block, and know that anyone else can do the same. This common knowledge allows people to transact completely peer-to-peer without putting trust in any third party.

The Nervos Common Knowledge Base (CKB) is designed to store all kinds of common knowledge, not limited to money. For example, the CKB could store user-defined crypto-assets, such as fungible and non-fungible tokens, as well as valuable cryptographic proofs that provide security for higher-layer protocols, such as payment channels (5.2) and commit chains (5.4).

Both Bitcoin and the Nervos CKB are common knowledge storage and verification systems. Bitcoin stores its global state as the UTXO set, and verifies state transitions through hard-coded rules and scripts embedded in transactions. The Nervos CKB generalizes Bitcoin's data structure and scripting capabilities, stores global state as the set of active programmable cells, and verifies state transitions through user-defined, Turing-complete scripts that run in a virtual machine.

While the Nervos CKB has full smart contract capabilities like those of Ethereum and other platforms, its economic model is designed for common knowledge preservation, instead of payment for decentralized computation.

### 4.2 Consensus

Bitcoin's Nakamoto Consensus (NC) is well-received due to its simplicity and low communication overhead. However, NC suffers from two drawbacks: 1) its transaction processing throughput is far from satisfactory, and 2) it is vulnerable to selfish mining attacks, in which attackers can gain additional block rewards by deviating from the protocol's prescribed behavior.

The CKB consensus protocol is a variant of NC that raises its performance limit and selfish mining resistance while keeping its merits. By identifying and eliminating the bottleneck in NC's block propagation latency, our protocol supports very short block intervals without sacrificing security. A shortened block interval not only increases throughput, but also lowers transaction confirmation latency. By incorporating all valid blocks into the difficulty adjustment calculation, selfish mining is no longer profitable in our protocol.

#### 4.2.1 Increasing Throughput

Nervos CKB increases the throughput of PoW consensus with a consensus algorithm derived from Nakamoto Consensus. The algorithm uses the blockchain's orphan rate (the percentage of valid blocks that are not part of the canonical chain) as a measurement of connectivity across the network.

The protocol targets a fixed orphan rate. In response to a low orphan rate target difficulty is lowered (increasing the rate of block production) and when the orphan rate crosses a defined threshold, target difficulty is increased (decreasing the rate of block production).

This allows for utilization of the network's entire bandwidth capabilities. A low orphan rate indicates that the network is well-connected and can handle greater data transmission; the protocol then increases throughput under these conditions.

#### 4.2.2 Eliminating the Block Propagation Bottleneck

The bottleneck in any blockchain network is block propagation. The Nervos CKB consensus protocol eliminates the block propagation bottleneck by modifying transaction confirmation into a two step process: 1) propose and 2) commit.

A transaction must first be proposed in the "proposal zone" of a block (or one of its uncles). The transaction will then be committed if it appears in a block's "commitment zone" within a defined window following its proposal. This design eliminates the block propagation bottleneck, as a new block's committed transactions will have already been received and verified by all nodes when proposed.

#### 4.2.3 Mitigating Selfish Mining Attacks

One of the most fundamental attacks on Nakamoto Consensus is selfish mining. In this attack, malicious miners gain unfair block rewards by deliberately orphaning blocks mined by others.

Researchers observe that the unfair profit opportunity is rooted in the difficulty adjustment mechanism of Nakamoto Consensus, which neglects orphaned blocks when estimating the network's computing power. This leads to lower mining difficulty and higher time-averaged block rewards.

The Nervos CKB consensus protocol incorporates uncle blocks into the difficulty adjustment calculation, making selfish mining no longer profitable. This holds regardless of attack strategy or duration; a miner is unable to gain unfair rewards through any combination of honest and selfish mining.

Our analysis shows that with a two-step transaction confirmation process, de facto selfish mining is also eliminated via a limited attack time window.

For a detailed understanding of our consensus protocol, please read [here](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0020-ckb-consensus-protocol/0020-ckb-consensus-protocol.md).

#### 4.2.4 Proof of Work vs Proof of Stake

Proof of Work (PoW) and Proof of Stake (PoS) systems are both vulnerable to concentrations of power, however the qualities of the systems provide very different operating realities for those in power.

PoW mining incurs real-world expenses that can exceed mining proceeds without diligent cost supervision. Those in power are required to stay innovative, pursue sound business strategies and continue to invest in infrastructure to remain dominant. Mining equipment, mining pool operations and access to cheap energy are all subject to changes from technological innovation. It is difficult to maintain monopolization of all three over long periods of time.

In contrast, block creators in PoS systems are rewarded in a deterministic way, based on amount staked, with very low operational capital requirements. As the system grows, the impact of natural advantages provided to first moving businesses and individuals will grow. In a PoS system, it is possible that power concentrates in the hands of a few stakers. Though PoW systems have a similar problem with mining concentration, the cost to remain in power in a PoS system is significantly lower.

In addition, PoS validators have one unique power: control of the validator set. Acceptance of a transaction that allows a validator to join the consensus group is in the hands of existing validators. Colluding efforts to influence the validator set through transaction censorship and ordering manipulation would be difficult to detect, as well as difficult to punish. Conversely, consensus participation in PoW systems is truly open and isn't subject to the current power structure. Advantages are not given to early participants of the system.

Regarding token economics, while it is believed that staking can attract capital looking to earn yield (and therefore increase demand for the native token), this is not the whole picture. All PoS projects will eventually see their staking rate stabilize, and capital entering and leaving the pool of staked capital would then be roughly the same. The staking mechanism by itself will not increase demand for the native token. In other words, though the introduction of staking provides demand for the native token in the initial phase of a project (as the staking rate rises), staking alone can't provide long-term demand for the native token and therefore can't be a native token's only intrinsic value.

Long-term token holders in a PoS system have 3 options: they can 1) manage infrastructure and run a validating node on their own to receive new issuance, 2) delegate their tokens to a third party and trust their integrity and infrastructure, or 3) have the value of their tokens diluted by ongoing issuance. None of these options are particularly attractive to long-term, store of value oriented token holders.

We believe that PoW's permissionless participation is a requirement for infrastructure at the foundation of global economic activity. The foremost goal of layer 1 is to ensure that the blockchain is as decentralized, secure and neutral as possible. While PoS systems have a role to play in the decentralized economy, in our opinion they do not meet the requirements of a truly open and decentralized layer 1.

#### 4.2.5 Proof of Work Function

Nervos CKB blocks can be proposed by any node, provided that 1) the block is valid; and 2) the proposer has solved a computationally difficult puzzle called the proof-of-work. The proof-of-work puzzle is defined in terms of the block that is being proposed; this guarantees that the solution to the puzzle uniquely identifies a block.

Bitcoin's proof-of-work requires finding a valid nonce such that the result of applying a hash function on the block header satisfies a certain level of difficulty. For Bitcoin, the hash function is twice-iterated SHA2–256. While SHA2 was a good choice for Bitcoin, the same is not true for cryptocurrencies that come after it. A large amount of dedicated hardware has been developed to mine Bitcoin, a great deal of which sits idle, having been rendered obsolete by efficiency improvements. 

A new cryptocurrency utilizing the same proof-of-work puzzle would make this deprecated hardware useful once again. Even up-to-date hardware can be rented and re-purposed to mine a new coin. The distribution of mining power for a SHA2-based coin would be very difficult to predict and susceptible to sudden and large changes. This argument also applies to algorithmic optimizations tailored to SHA2, which have been developed to make software computation of the function cheaper as well.

For a new cryptocurrency, it makes sense to define the proof-of-work puzzle in terms of a function that has not yet been used by other cryptocurrencies. For Nervos CKB, we went a step further and chose to define it in terms of a proof-of-work function that could not have been the subject of premature optimization, because it is new.

However, the intended unavailability of mining hardware is only the case initially. In the long run, deployments of dedicated mining hardware are beneficial, significantly increasing the challenges of attacking the network. Therefore, in addition to being new, an ideal proof-of-work function for a new cryptocurrency is also simple, significantly lowering the barrier for hardware development.

Security is the obvious third design goal. While a known vulnerability could be exploited by all miners equally, and would merely result in a higher difficulty, an undisclosed vulnerability could lead to a mining optimization that provides the discoverer(s) an advantage in excess of their contributed mining power share. The best way to avoid this situation is to make a strong argument for invulnerability.

#### 4.2.6 Eaglesong

Eaglesong is a new hash function developed specifically for Nervos CKB proof-of-work, but is also suitable in other use cases in which a secure hash function is needed. The design criteria were exactly as listed above: novelty, simplicity and security. We wanted a design that was simultaneously novel enough to constitute a small step forward for science, as well as close enough to existing designs to make a strong security argument. 

To this end, we chose to instantiate the sponge construction (as used in Keccak/SHA3) with a permutation built from ARX operations (addition, rotation, and xor); the argument for its security is based on the wide trail strategy (the same argument underlying AES).

To the best of our knowledge, Eaglesong is the first hash function (or function, for that matter) that successfully combines all three design principles.

You can read more about Eaglesong [here](https://medium.com/nervosnetwork/the-proof-of-work-function-of-nervos-ckb-3cc8364464d9).


### 4.3 Cell Model

Nervos CKB utilizes the Cell Model, a new construction that can provide many of the benefits of the Account model (utilized in Ethereum), while preserving the asset ownership and proof-based verification properties of the UTXO model (utilized in Bitcoin).

The cell model is focused on state. Cells contain arbitrary data, which could be simple, such as a token amount and an owner, or more complex, such as code specifying verification conditions for a token transfer. The CKB's state machine executes scripts associated with cells to ensure the integrity of a state transition.

In addition to storing data of their own, cells can reference data in other cells. This allows for user-owned assets and the logic governing them to be separated. This is in contrast to account-based smart contract platforms, in which state is internal property of a smart contract and has to be accessed through smart contract interfaces. On Nervos CKB, cells are independent state objects that are owned, and can be referenced and passed around directly. Cells can express true "bearable assets", belonging to their owners (just as UTXOs are bearable assets to Bitcoin owners), while referencing a cell that holds logic ensuring the integrity of state transitions.

Cell model transactions are also state transition proofs. A transaction's input cells are removed from the set of active cells and output cells are added to the set. Active cells comprise the global state of the Nervos CKB, and are immutable: once cells have been created, they cannot be changed. 

The Cell model is designed to be adaptable, sustainable, and flexible. It can be described as a generalized UTXO model and can support user-defined tokens, smart contracts and diverse layer 2 protocols.

For deeper understanding of the Cell Model, please see [here](https://medium.com/nervosnetwork/https-medium-com-nervosnetwork-cell-model-7323fca57571).


### 4.4 Virtual Machine

While many next-generation blockchain projects utilize WebAssembly as the foundation of a blockchain virtual machine, Nervos CKB includes the unique design choice of a virtual machine (CKB-VM) based on the RISC-V instruction set.

RISC-V is an open-source RISC instruction set architecture that was created in 2010 to facilitate development of new hardware and software, and is a royalty-free, widely understood and widely audited instruction set.

We have found numerous advantages to using RISC-V in a blockchain context:

- Stability: The RISC-V core instruction set has been finalized and frozen, as well as widely implemented and tested. The core RISC-V instruction set is fixed and will never require an update.
- Open and Supported: RISC-V is provided under a BSD license and supported by compilers such as GCC and LLVM, with Rust and Go language implementations under development. The RISC-V Foundation includes more than 235 member organizations furthering the instruction set's development and support.
- Simplicity and Extensibility: The RISC-V instruction set is simple. With support for 64-bit integers, the set contains only 102 instructions. RISC-V also provides a modular mechanism for extended instruction sets, enabling the possibility of vector computing or 256-bit integers for high-performance cryptographic algorithms.
- Accurate Resource Pricing: The RISC-V instruction set can be run on a physical CPU, providing an accurate estimation of the machine cycles required for executing each instruction and informing virtual machine resource pricing.

CKB-VM is a low-level RISC-V virtual machine that allows for flexible, Turing-complete computation. Through use of the widely implemented ELF format, CKB-VM scripts can be developed with any language that can be compiled to RISC-V instructions.

#### 4.4.1 CKB-VM and the Cell Model

Once deployed, existing public blockchains are more or less fixed. Upgrading foundational elements, such as cryptographic primitives, involve multi-year undertakings or are simply not possible.

CKB-VM takes a step back, and moves primitives previously built into custom VMs to cells on top of the virtual machine. Though CKB scripts are more low-level than smart contracts in Ethereum, they carry the significant benefit of flexibility, enabling a responsive platform and foundation for the progressing decentralized economy.

Cells can store executable code and reference other cells as dependencies. Almost all algorithms and data structures are implemented as CKB scripts stored within cells. By keeping the VM as simple as possible and offloading program storage to cells, updating key algorithms is as simple as loading the algorithm into a new cell and updating existing references.

#### 4.4.2 Running Other Virtual Machines on the CKB-VM

Thanks to the low-level nature of the CKB-VM and the availability of tooling in the RISC-V community, it's easy to compile down other VMs (such as Ethereum's EVM) directly into the CKB-VM. This has several advantages: 

- Smart contracts written in specialized languages running on other virtual machines can be easily ported to run on the CKB-VM. (Strictly speaking, they'd be running on their own VM that's compiled to run inside of the CKB-VM.)
- The CKB can verify dispute resolution state transitions of layer 2 transactions, even if the rules of the state transitions are written to run in a virtual machine other than CKB-VM. This is one of the key requirements to support trustless layer 2 general purpose side-chains. 

For a technical walkthrough of the CKB-VM, please see [here](https://medium.com/nervosnetwork/an-introduction-to-ckb-vm-9d95678a7757).

### 4.5 Economic Model

The native token of the Nervos CKB is the "Common Knowledge Byte", or CKByte for short. CKBytes entitle a token holder to occupy part of the total state storage of the blockchain. For example, by holding 1000 CKBytes, a user is able to create a cell of 1000 bytes in capacity or multiple cells adding up to 1000 bytes in capacity. 

Using CKBytes to store data on the CKB creates an opportunity cost to CKByte owners; they will not be able to deposit occupied CKBytes into the NervosDAO to receive a portion of the secondary issuance. CKBytes are market priced, and thus an economic incentive is provided for users to voluntarily release state storage to meet the high demand of expanding state. After a user releases state storage, they will receive an amount of CKBytes equivalent to the size of state (in bytes) their data was occupying.

The economic model of the CKB allows issuance of the native token to bound state growth, maintaining a low barrier of participation and ensuring decentralization. As CKBytes become a scarce resource, they can be priced and allocated most efficiently.

The genesis block of the Nervos Network will contain 33.6 billion CKBytes, of which 8.4 billion will be immediately burned. New issuance of CKBytes includes two parts - base issuance and secondary issuance. Base issuance is limited to a finite total supply (33.6 billion CKBytes), with an issuance schedule similar to Bitcoin. The block reward halves approximately every 4 years, until reaching 0 new issuance. All base issuance is awarded to miners as incentives to protect the network. The secondary issuance has a constant issuance rate of 1.344 billion CKBytes per year and is designed to impose an opportunity cost for state storage occupation. After the base issuance stops, there will only be secondary issuance.

Nervos CKB includes a special smart contract called the NervosDAO, which functions as an "inflation shelter" against the effects of the secondary issuance. CKByte owners can deposit their tokens into the NervosDAO and receive a portion of secondary issuance that exactly offsets inflationary effects from secondary issuance. For long-term token holders, as long as they lock their tokens in the NervosDAO, the inflationary effect of secondary issuance is only nominal. With the effects of secondary issuance mitigated, these users are effectively holding hard-capped tokens like Bitcoin.

While CKBytes are being used to store state, they cannot be used to earn secondary issuance rewards through the NervosDAO. This makes the secondary issuance a constant inflation tax, or "state rent" on state storage occupation. This economic model imposes state storage fees proportional to both the space and time of occupation. It is more sustainable than the "pay once, occupy forever" model used by other platforms, and is more feasible and user-friendly than other state rent solutions that require explicit payments.

Miners are compensated with both block rewards and transaction fees. For block rewards, when a miner mines a block, they would receive the block's full base issuance reward, and a portion of secondary issuance. The portion is based on state occupation, for example: if half of all native tokens are being used to store state, a miner would receive half of the secondary issuance reward for the block. Additional information about the distribution of secondary issuance is included in the next section (4.6). In the long term, when base issuance stops, miners will still receive "state rent" income that's independent of transactions, but tied to the adoption of the Nervos Common Knowledge Base.

In an analogy, CKBytes can be thought of as land, while crypto-assets stored on the CKB can be thought of as houses. Land is required to build a house, and CKBytes are required to store assets on the CKB. As demand to store assets on CKB rises, demand for CKBytes rises as well. As the value of assets stored rises, the value of CKBytes rises as well.

The Nervos CKB is designed to translate demand for a multitude of assets into demand for a single asset, and use it to compensate the miners to secure the network.

For more detailed explanation on the economic model, please see [here](https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0015-ckb-cryptoeconomics/0015-ckb-cryptoeconomics.md). 


### 4.6 Treasury

The portion of secondary issuance that doesn't go to 1) miners or 2) long-term holders with tokens locked in the NervosDAO, will go toward a treasury fund. To demonstrate: if 60% of issued CKBytes are used to store state and 30% of the CKBytes are deposited into the NervosDAO, miners will receive 60% of the secondary issuance, the NervosDAO (long-term holders) will receive 30% of the secondary issuance, and 10% of the secondary issuance will go to the treasury. 

The treasury fund will be used to fund ongoing research and development of the protocol, as well as building the ecosystem of the Nervos Network. The use of the treasury funds will be open, transparent and on-chain for everyone to see. Compared to an inflation-based treasury funding model, this model doesn't dilute long-term token holders (who have deposited their tokens into the NervosDAO). Funding of protocol development is strictly derived from the opportunity cost to short-term token holders.

The treasury won't be activated immediately upon the main-net launch of the Nervos Common Knowledge Base. With the community's approval, it will be activated with a hard-fork later, only after the Nervos Foundation has exhausted the Ecosystem Fund, included in the Genesis block. Prior to activation of the treasury, this portion of the secondary issuance will be burned.


### 4.7 Governance

Governance is how society or groups within it organize to make decisions. Every relevant party with an interest in the system should be involved in this process. In regard to a blockchain, this should include not only users, holders, miners, researchers and developers, but also service providers such as wallets, exchanges and mining pools as well. Various stakeholder groups have diverse interests and it is almost impossible to align everyone's incentives. This is why blockchain governance is a complicated and controversial topic. If we consider a blockchain as a large social experiment, governance requires a more sophisticated design than any other part of the system. After ten years of evolution, we still haven't identified general best practices or sustainable processes for blockchain governance.

Some projects conduct governance via a "benevolent dictator for life" (such as Linus Torvalds to Linux). We acknowledge that this makes a project highly efficient, cohesive, and also charming: people love heroes; however, this is contradictory to decentralization, the core value of blockchain. 

Some projects entrust a distinguished off-chain committee with far-reaching decision-making power, such as the ECAF (EOSIO Core Arbitration Forum) on EOS. However, these committees lack the essential power to guarantee participants will abide by their decisions, which could have played a role in the decision to shut down the ECAF earlier this year. 

Some projects, such as Tezos, go further, and implement on-chain governance to ensure all participants abide by voted upon decisions. This also avoids any impacts of discord between developers and miners (or full node users). Note that on-chain governance is different from a simple on-chain vote, if a proposed feature or patch has acquired enough votes through on-chain governance, the chain code will be updated automatically, miners or full nodes do not have any means of controlling this change. Polkadot takes an even more sophisticated approach to on-chain governance, utilizing an elected council, referendum process for stake-weighted voting and positive/negative bias mechanisms to account for voter turnout. 

However, despite its straightforwardness, on-chain governance in practice is not as elegant as it is presented. First of all, votes only reflect the interest of token holders, while simply ignoring all other parties. Secondly, a low voting rate is a long-standing problem in both the blockchain world and real world. How can results be in the best interest of the majority if only a minority vote? Last but most importantly, a hard fork should always be considered as final recourse for all stakeholders. Given the excellent data availability provided by the wide replication of a permissionless blockchain, forking away from the existing chain with full data preservation and without interruption should always be an option. A hard fork could never be implemented via on-chain governance.

There are not yet viable answers to the questions of governance, so for Nervos Network we will take an evolving approach. We expect the community to develop organically in the early days and over time, as more tokens are mined, mining becomes more distributed, and more developers are engaged, governance responsibilities will gradually become more decentralized. Over the long term, community-based governance will manage the protocol upgrade process and resource allocation from the treasury.

Nervos CKB is designed to be decentralized autonomous infrastructure that could last for hundreds of years, which means there are certain things that demand our best effort as a community to hold true, no matter how this network evolves. The 3 core invariants are:

- Issuance schedule is completely fixed, thus shall never change.
- State/data stored in cells shall not be tampered with.
- Existing scripts' semantics shall not be changed.

Community-based governance for blockchains is a very new field and there are many worthy on-going experiments. We recognize that this is not a trivial topic, and time is required to fully study, observe, and iterate to arrive at an optimal approach. We're taking a conservative approach to community-based governance in the short-term, while remaining fully committed to this direction in the long run.

## 5. Overview of Layer 2 Solutions

### 5.1 What is Layer 2?

A blockchain network's layer 1 is defined by constraints. An ideal layer 1 blockchain makes no compromises on security, decentralization and sustainability, however, this creates challenges related to scalability and transaction costs. Layer 2 solutions are built on top of layer 1 protocols, allowing computation to be moved off-chain with mechanisms to securely settle back to the layer 1 blockchain.

This is similar to net settlement in today's banking system or SEC-mandated regulatory filings. By reducing the amount of data requiring global consensus, the network can serve more participants and facilitate more economic activity than it would have been able to otherwise, while still maintaining the properties of decentralization.

Layer 2 users depend on security provided by the layer 1 blockchain, and utilize this security when moving assets between layers or settling a dispute. This function is similar to a court system: the court doesn't have to monitor and validate all transactions, but only serves as a place to record key evidence and to settle disputes. Similarly, in a blockchain context, the layer 1 blockchain allows participants to transact off-chain, and in the case of a disagreement provides them with the ability to bring cryptographic evidence to the blockchain and penalize dishonesty. 

### 5.2 Payment and State Channels

Payment channels are created between two parties that transact often. They provide a low-latency, immediate payment experience that transactions done directly on a global blockchain could never provide. Payment channels function similar to a bar tab - you can open a tab with a bartender and keep ordering drinks, but only settle the tab and pay the final amount when you're ready to leave the bar. In the operation of a payment channel, participants exchange messages containing cryptographic commitments to their balances and can update these balances an unlimited number of times off-chain, before they're ready to close the channel and settle balances back on the blockchain.

Payment channels can be unidirectional or bidirectional. Unidirectional payment channels flow from Party A to Party B, similar to the bar tab example above. Party A deposits the maximum amount they might spend with Party B, and then slowly signs over funds as they receive goods or services.

Bidirectional payment channels are more complicated, but start to show the scope of possibilities for layer 2 technologies. In these payment channels, funds flow back and forth between parties. This allows for "rebalancing" of payment channels and opens up the possibility of payments across channels through a shared counterparty. This enables networks of payment channels, such as Bitcoin's Lightning Network. Funds can be transferred from Party A to Party B without a direct channel between them, as long as Party A can find a path through an intermediary with connections open to both parties.

Just as payment channels can scale on-chain payments, state channels can scale any on-chain transactions. While a payment channel is limited to managing balances between two parties, a state channel is an agreement on arbitrary state, enabling everything from a game of trustless chess to scalable decentralized applications.

Similar to a payment channel, the parties open a channel, exchange cryptographic signatures over time and submit a final state (or result) to an on-chain smart contract. The smart contract will then execute based on this input, settling the transaction according to rules encoded in the contract.
 
A "generalized state channel" is a powerful state channel construction, allowing a single state channel to support state transitions across multiple smart contracts. This reduces the state bloat inherent in a "one channel per application" architecture and also allows for easy on-boarding with the ability to utilize state channels users already have open. 

### 5.3 Side-chains

A side-chain is a separate blockchain that's attached to a trustless blockchain (main-chain) with a two-way peg. To utilize the side-chain, a user would send funds to a specified address on the main-chain, locking these funds under control of the side-chain operators. Once this transaction is confirmed and a safety period has passed, a proof can be communicated to side-chain operators detailing the deposit of funds. The operators will then create a transaction on the side-chain, distributing the appropriate funds. These funds can then be spent on the side-chain with low fees, fast confirmation and high throughput.

The main drawback of side-chains is that they require additional security mechanisms and security assumptions. The simplest side-chain construction, a federated side-chain, places trust in a multi-signature group of operators. On smart contract platforms, security models can be fine-tuned with token incentives or bonding/challenging/slashing economic games. 

Compared to other off-chain general purpose scaling solutions, side-chains are easier to understand and implement. For types of applications that allow creation of a trust model that's acceptable to their users, side-chains can be a practical solution.

### 5.4 Commit-chains

On commit-chains[6], such as Plasma[7], a layer 2 chain is constructed that leverages a trust root on a layer 1 blockchain (root-chain) with broad global consensus. These commit-chains are secure; in the event a chain operator is malicious or dysfunctional, users can always withdraw their assets through a mechanism on the root-chain.

A commit-chain operator is trusted to execute transactions correctly and publish periodic updates to the root-chain. Under all conditions, except for a prolonged censorship attack on the root-chain, assets on the commit-chains will remain safe. Similar to federated side-chains, commit-chain designs offer a superior user experience compared to trustless blockchains. However, they do so while maintaining stronger security guarantees.
  
The commit-chain is secured by a set of smart contracts running on the root-chain. Users deposit assets into this contract and the commit-chain operator then provides them assets on the commit-chain. The operator will periodically publish commitments to the root-chain, which users can later utilize to prove asset ownership through Merkle proofs, an "exit", in which commit-chain assets are withdrawn to the root-chain.

This describes the general notion of commit-chain designs, the basis of an emerging family of protocols including Plasma. The Plasma white paper[7] released by Vitalik Buterin and Joseph Poon in 2017 lays out an ambitious vision. Though all Plasma chains are currently asset-based, and can only store fungible and non-fungible token ownership (and transfers), trustless code execution (or smart contracts) is an active area of research.

### 5.5 Verifiable Off-Chain Computations

Cryptography provides a tool seemingly tailored to the dynamics of expensive on-chain verification and inexpensive off-chain computation: interactive proof systems. An interactive proof system is a protocol with two participants, the Prover and the Verifier. By sending messages back and forth, the Prover will provide information to convince the Verifier that a certain claim is true, whereas the Verifier will examine what is provided and reject false claims. Claims that the Verifier cannot reject are accepted as true.

The principal reason why the Verifier does not simply verify the claim naïvely on his own is efficiency — by interacting with a Prover, the Verifier can verify claims that would be prohibitively expensive to verify otherwise. This complexity gap can come from a variety of sources: 1) the Verifier may be running lightweight hardware that can support only space-bounded or time-bounded (or both) computations, 2) naïve verification may require access to a long sequence of nondeterministic choices, 3) naïve verification may be impossible because the Verifier does not possess certain secret information. 

While the secrecy of important information is certainly a relevant constraining factor in the context of cryptocurrencies, a more relevant constraining factor in the context of scalability is the cost of on-chain verification, especially in contrast to relatively cheap off-chain computation.

In the context of cryptocurrencies, significant attention has been directed towards zk-SNARKs (zero-knowledge, succinct non-interactive arguments of knowledge). This family of non-interactive proof systems revolves around the arithmetic circuit, which encodes an arbitrary computation as a circuit of additions and multiplications over a finite field. For instance, the arithmetic circuit can encode "I know a leaf in this Merkle tree".

zk-SNARK proofs are constant-size (hundreds of bytes) and verifiable in constant time, although this Verifier-efficiency comes at a cost: a trusted setup and a structured reference string are required, in addition to pairing-based arithmetic (of which concrete cryptographic hardness remains an object of concern). 

Alternative proof systems provide different trade-offs. For instance, Bulletproofs have no trusted setup and rely on the much more common discrete logarithm assumption, however have logarithmic-size proofs (though still quite small) and linear-time Verifiers. zk-STARKs provide an alternative to zk-SNARKs in terms of scalability, without a trusted setup and rely only on rock-solid cryptographic assumptions, although the produced proof is logarithmic in size (and quite large: hundreds of kilobytes).

In the context of a multi-layer cryptocurrency ecosystem such as the Nervos Network, interactive proofs offer the ability to offload expensive Prover-side computations to layer 2 while requiring only modest Verifier-side work from layer 1. This intuition is captured, for instance, in Vitalik Buterin's ZK Rollup protocol[8]: a permissionless relayer gathers transactions off-chain and periodically updates a Merkle root stored on chain. Every such root update is accompanied by a zk-SNARK that shows that only valid transactions were accumulated into the new Merkle tree. A smart contract verifies the proof and allows the Merkle root to be updated only if the proof is valid.

The construction outlined above should be able to support more complex state transitions beyond simple transactions, including DEX's, multiple tokens, and privacy-preserving computation.

### 5.6 Economic Model of Layer 2 Solutions

While layer 2 solutions provide impressive scalability, the token economics of these systems may pose design challenges.

Layer 2 token economics may involve compensation for critical infrastructure (such as validators and watchtowers), as well as application-specific incentive design. Critical layer 2 infrastructure tends to work better with a duration-based, subscription model. In the Nervos Network, this pricing structure can be easily implemented through the CKB's opportunity cost-based payment method. Service providers can collect fees on their users' "deposits" through the NervosDAO. Layer 2 developers can then focus token economic models on incentives specific to their applications.

In a way, this pricing model is exactly how users pay for state storage on the CKB as well. They're essentially paying a subscription fee to miners with the distribution of their inflation rewards issued by the NervosDAO.

## 6. The Nervos Network

### 6.1 Layer 1 as a Multi-asset Store of Value Platform

We believe that a layer 1 blockchain has to be built as a store of value. To maximize long-term decentralization, it has to be based on proof of work consensus with an economic model designed around state storage occupation, instead of transaction fees. The Common Knowledge Base (CKB) is a proof of work-based, multi-asset, store of value blockchain with both its programming and economic models designed around state.

The CKB is the base layer of the Nervos Network, with the highest security and highest degree of decentralization. Owning and transacting assets on the CKB comes with the highest cost, however provides the most secure and accessible asset storage in the network and allows for maximum composability. The CKB is best suited for high value assets and long-term asset preservation.

The Common Knowledge Base is the first layer 1 blockchain built specifically to support layer 2 protocols:

- The CKB is designed to complement layer 2 protocols, focusing on security and decentralization, instead of overlapping layer 2 priorities such as scalability.
- The CKB models its ledger around state, instead of accounts. Cells are essentially self-contained state objects that can be referenced by transactions and passed around between layers. This is ideal for a layered architecture, where the objects referenced and passed between layers are pieces of state, instead of accounts.
- The CKB is designed as a generalized verification machine, instead of computation engine. This allows the CKB to serve as a cryptographic court, that verifies off-chain state transitions.
- The CKB allows developers to easily add custom cryptographic primitives. This future-proofs the CKB, allowing for verification of proofs generated by a variety of layer 2 solutions.

The Common Knowledge Base aims to be the infrastructure to store the world's most valuable common knowledge, with the best-in-class layer 2 ecosystem providing the most scalable and efficient blockchain transactions.

### 6.2 Scale with Layer 2 Solutions

With its layered architecture, the Nervos Network can scale on layer 2 to any number of participants, while still maintaining the vital properties of decentralization and asset preservation. Layer 2 protocols can make use of any type of layer 1 commitment or cryptographic primitive, enabling great flexibility and creativity in designing transactional systems to support a growing layer 2 user base. Layer 2 developers can choose their own trade-offs in regard to throughput, finality, privacy and trust models that work best in the context of their applications and users.

In the Nervos Network, layer 1 (CKB) is used for state verification, while layer 2 is responsible for state generation. State channels and side-chains are examples of state generation, however any type of generate-verify pattern is supported, such as a zero-knowledge proof generation cluster. Wallets also operate at layer 2, running arbitrary logic, generating new state and submitting state transitions to the CKB for validation. Wallets in the Nervos Network are very powerful because they are state generators, with full control over state transitions.

Side-chains are developer-friendly and provide a good user experience. They do however, rely on the honesty of their validators. If the validators behave maliciously, users are in danger of losing their assets. Nervos Network provides an open-source and easy-to-use side-chain stack for launching side-chains on the CKB, consisting of a Proof-of-Stake blockchain framework called "Muta" and a side-chain solution based on it called "Axon".

Muta is a highly customizable, high-performance blockchain framework designed to support Proof-of-Stake, BFT consensus and smart contracts. It features a high throughput and low latency BFT consensus "Overlord", and supports various virtual machines including CKB-VM, EVM and WASM. Different virtual machines can be used in a single Muta blockchain simultaneously, with cross-VM interoperability. Muta greatly lowers the barrier for developers to build high performance blockchains, while still allowing maximum flexibility to customize their protocols.

Axon is a complete solution built with Muta to provide developers a turnkey side-chain on top of the Nervos CKB, with a practical security and token economic model. Axon solutions use the CKB for secure asset custody, and use token-based governance mechanism to manage the side-chain validators. Cross-chain protocols for interactions between an Axon side-chain and the CKB, as well as between Axon side-chains will also be built-in. With Axon, developers can focus on building applications, instead of building infrastructure and cross-chain protocols. 

Both Muta and Axon are currently under heavy development. We'll open source the frameworks soon, and RFCs for both Muta and Axon are also on the way.

Layer 2 protocols are a flourishing area of research and development. We foresee a future in which all layer 2 protocols are standardized and seamlessly interoperate. However, we acknowledge that layer 2 solutions are still maturing, and we're often still pushing the boundaries of what they can do, as well as finding their acceptable trade-offs. We've seen early promising solutions, but there's still plenty of research to conduct on subjects such as interoperability, security and economic models in layer 2 designs.

### 6.3 Sustainability

In the interest of long-term sustainability, the Nervos Common Knowledge Base bounds state, imposes a cost on on-chain storage and provides incentives for users to clear their state storage. A bounded state keeps the requirements for full node participation low, ensuring nodes can be run on low-cost hardware. Robust full node participation increases decentralization and in turn, security.

By imposing a time-proportional "state-rent" cost on state storage, the Nervos Common Knowledge Base mitigates the tragedy of the commons faced by many blockchains in a "pay once, store forever" paradigm. Implemented through "targeted inflation", this state rent mechanism provides a smooth user experience while imposing a cost on state storage.

This inflation cost can be targeted because users own the consensus space their data occupies. This model also includes a native mechanism for users to remove their state from the consensus space. Coupled with the economic incentives of state rent, this ensures that state size will always be moving toward the minimum amount of data required by network participants.

Individually owned state also significantly reduces developers' costs. Instead of being required to purchase CKBytes for the state requirements of all their users, developers only have to purchase enough CKBytes to store the verification code required by their application. Each user would use their own cells to store their tokens and would be fully responsible for their assets.

Finally, state rent provides an ongoing reward to miners through new token issuance. This predictable income incentivizes miners to advance the blockchain, instead of forking profitable blocks to take the transaction fees.

### 6.4 Aligned Incentives

The economic model of the Common Knowledge Base is designed to align incentives for all participants in the ecosystem.

The Nervos Common Knowledge Base is built explicitly for secure value preservation, instead of cheap transaction fees. This critical positioning will attract store of value users, similar to the user community of Bitcoin, instead of medium of exchange users.

Medium of exchange use cases have a tendency to always push a blockchain network toward centralization, in pursuit of greater efficiency and low fees. Without significant fee income for infrastructure operators that secure the network (miners or validators), security must be funded through monetary inflation, or is simply under-funded. Monetary inflation is detrimental to long-term holders, and under-funded security is detrimental to any stakeholder of the network.

Store of value users however, have strong demands for censorship resistance and asset security. They rely on miners to provide this, and in turn compensate them for their role. In a store of value network, these parties have aligned interests.

By aligning the incentives of all participants, a united Nervos community can grow, and the aligned economic system of the network is also expected be hard-fork resistant.

### 6.5 Value Capture and Value Generation

For any blockchain to remain secure as the value of assets secured by the platform increases, the system must have a mechanism to capture value as the value of assets secured grows. By bounding state, the CKB makes the state space a scarce and market-priced resource. As demand for asset storage on the network rises, the system is expected to better compensate the miners for securing such assets.

As a value preserving platform, the intrinsic value of the CKB as a platform is determined by the amount of security it provides to the assets it preserves. As the value of assets secured rises, the value capture mechanism of the CKB economic model is able to automatically raise the CKB's security budget to attract more mining resources, making the platform more secure. Not only is this important to make the platform sustainable, it also provides a path of growth for the platform's intrinsic value - as the platform becomes more secure, it also becomes more attractive to higher-value assets, generating more demand. Obviously, this is bound by the overall aggregate value that will eventually move to the blockchain space.

Over time, we expect the economic density of the CKB to increase. CKBytes will be used for high-value asset storage and low-value assets will to move to blockchains connected to the CKB, such as layer 2 side-chains. Instead of directly securing assets, the CKB can be used as a trust root to secure an entire side-chain’s ecosystem through, for example,  a few hundred bytes of cryptographic proofs. The economic density of such proofs is extraordinarily high, further supporting the demand curve of storage space: analogous to a small parcel of land significantly increasing its economic density by supporting a skyscraper.

Finally, through the design of the NervosDAO and its "inflation shelter" function, long-term token holders will always retain a fixed percentage of total issuance, making the native token itself a robust store of value.

### 6.6 Bridging the Regulatory Gap

Permissionless blockchains allow total decentralization in asset issuance and transaction. This is what makes them valuable, but is also the reason they aren't compatible with real-world financial and judicial systems.

The emergence of a layered architecture provides the opportunity to create regulatory compliant portions of an unregulated, permissionless blockchain. For example, users can store their decentralized assets on layer 1, enjoy absolute property ownership of these assets, and can also process real-world business on layer 2, where they are subject to regulatory and legal constraints.

Take for example cryptocurrency exchanges - countries such as Japan and Singapore have issued licenses to exchanges and created regulatory requirements. A compliant exchange or a branch of a global exchange could build a layer 2 trading chain, import user identities and assets and then conduct legal business in accordance with local regulatory requirements.

Issuance and transaction of real-world assets become possible within a layered blockchain construction. Real-world assets can flow to the blockchain ecosystem through a regulated layer 2 side-chain to the permissionless layer 1 blockchain, allowing these assets access to the largest ecosystem of composable, decentralized financial services.

In the future, it is expected that the Nervos Network will also use layer 2 side-chains and applications as the foundation of large-scale user adoption, in cooperation with leading companies in this space.

# References

[1] Satoshi Nakamoto. "Bitcoin: A Peer-to-Peer Electronic Cash System". 31 Oct 2008, https://bitcoin.org/bitcoin.pdf

[2] Vitalik Buterin. "Ethereum White Paper: A Next Generation Smart Contract & Decentralized Application Platform". Nov 2013 http://blockchainlab.com/pdf/Ethereum_white_paper-a_next_generation_smart_contract_and_decentralized_application_platform-vitalik-buterin.pdf 

[3] With an average Bitcoin transaction size of 250 bytes:
(2 * 250 * 7,500,000,000) / (24 * 6) = 26,041,666,666 byte blocks (every 10 minutes); 
26,041,666,666 * (24 * 6) = 3,750,000,000,000 bytes (blockchain growth each day);
3,750,000,000,000 * 365.25 = 1,369,687,500,000,000 bytes (blockchain growth each year)

[4] Gur Huberman, Jacob Leshno, Ciamac C. Moallemi. "Monopoly Without a Monopolist: An Economic Analysis of the Bitcoin Payment System". Bank of Finland Research Discussion Paper No. 27/2017. 6 Sep 2017, https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3032375

[5] Miles Carlsten, Harry Kalodner, S. Matthew Weinberg, Arvind Narayanan. "On the Instabiliity of Bitcoin Without the Block Reward". Oct 2016, https://www.cs.princeton.edu/~smattw/CKWN-CCS16.pdf

[6] Lewis Gudgeon, Perdo Moreno-Sanchez, Stefanie Roos, Patrick McCorry, Arthur Gervais. "SoK: Off The Chain Transactions". 17 Apr 2019, https://eprint.iacr.org/2019/360.pdf

[7] Joseph Poon, Vitalik Buterin. "Plasma: Scalable Autonomous Smart Contracts". 11 Aug 2017, https://plasma.io/plasma.pdf

[8] Vitalik Buterin. "On-chain scaling to potentially ~500 tx/sec through mass tx validation". 22 Sep 2018, https://ethresear.ch/t/on-chain-scaling-to-potentially-500-tx-sec-through-mass-tx-validation/3477
