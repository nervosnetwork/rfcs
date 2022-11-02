---
Number: "0020"
Category: Informational
Status: Draft
Author: Ren Zhang <@nirenzang>
Created: 2019-6-19
---
# CKB Consensus Protocol

* [Abstract](#Abstract)
* [Motivation](#Motivation)
* [Technical Overview](#Technical-Overview)
  * [Eliminating the Bottleneck in Block Propagation](#Eliminating-the-Bottleneck-in-Block-Propagation)
  * [Utilizing the Shortened Latency for Higher Throughput](#Utilizing-the-Shortened-Latency-for-Higher-Throughput)
  * [Mitigating Selfish Mining Attacks](#Mitigating-Selfish-Mining-Attacks)
* [Specification](#Specification)
  * [Two-Step Transaction Confirmation](#Two-Step-Transaction-Confirmation)
  * [Dynamic Difficulty Adjustment Mechanism](#Dynamic-Difficulty-Adjustment-Mechanism)

<a name="Abstract"></a>
## Abstract

Bitcoin's Nakamoto Consensus (NC) is well-received due to its simplicity and low communication overhead. However, NC suffers from two kinds of drawback: first, its transaction processing throughput is far from satisfactory; second, it is vulnerable to a selfish mining attack, where attackers can gain more block rewards by deviating from the protocol's prescribed behavior.

The CKB consensus protocol is a variant of NC that raises its performance limit and selfish mining resistance while keeping its merits. By identifying and eliminating the bottleneck in NC's block propagation latency, our protocol supports very short block interval without sacrificing security. The shortened block interval not only raises the throughput, but also lowers the transaction confirmation latency. By incorporating all valid blocks in the difficulty adjustment, selfish mining is no longer profitable for a large range of parameters in our protocol.

We provide only the gist of our design in this document. The detailed background and supporting evidence---experiments, performance evaluation, and security proof---can be found in two academic publications:

> Ren Zhang, Dingwei Zhang, Quake Wang, Shichen Wu, Jan Xie, Bart Preneel. NC-Max: Breaking the Security-Performance Tradeoff in Nakamoto Consensus. In *the Network and Distributed System Security Symposium (NDSS) 2022*.

Paper on [Eprint](https://eprint.iacr.org/2020/1101). Short talk (15 min) on [Youtube](https://www.youtube.com/watch?v=mYS-A1CK6zc). Full talk (23 min) on [Youtube](https://www.youtube.com/watch?v=WwD9ZvuI9J8), [Bilibili](https://www.bilibili.com/video/BV1XP411n7qV/).

> A paper in submission by Roozbeh Sarenche, Ren Zhang, Svetla Nikova, Bart Preneel.

We will publish it as soon as the paper is accepted.

<a name="Motivation"></a>
## Motivation

Although a number of non-NC consensus mechanisms have been proposed, NC has the following threefold advantage comparing with its alternatives. First, its security is carefully scrutinized and well-understood [[1](https://www.cs.cornell.edu/~ie53/publications/btcProcFC.pdf), [2](https://eprint.iacr.org/2014/765.pdf), [3](https://fc16.ifca.ai/preproceedings/30_Sapirshtein.pdf), [4](https://eprint.iacr.org/2016/454.pdf), [5](https://eprint.iacr.org/2016/1048.pdf), [6](https://eprint.iacr.org/2018/800.pdf), [7](https://eprint.iacr.org/2018/129.pdf), [8](https://arxiv.org/abs/1607.02420)], whereas alternative protocols often open new attack vectors, either unintentionally [[1](http://fc19.ifca.ai/preproceedings/180-preproceedings.pdf), [2](https://www.esat.kuleuven.be/cosic/publications/article-3005.pdf)] or by relying on security assumptions that are difficult to realize in practice [[1](https://arxiv.org/abs/1711.03936), [2](https://arxiv.org/abs/1809.06528)]. Second, NC minimizes the consensus protocol's communication overhead. In the best-case scenario, propagating a 1 MB block in Bitcoin is equivalent to broadcasting a compact block message of roughly 13 KB [[1](https://github.com/bitcoin/bips/blob/master/bip-0152.mediawiki), [2](https://www.youtube.com/watch?v=EHIuuKCm53o)]; valid blocks are immediately accepted by all honest nodes. In contrast, alternative protocols often demand a non-negligible communication overhead to certify that certain nodes witness a block. For example, [Algorand](https://algorandcom.cdn.prismic.io/algorandcom%2Fa26acb80-b80c-46ff-a1ab-a8121f74f3a3_p51-gilad.pdf) demands that each block be accompanied by 300 KB of block certificate. Third, NC's chain-based topology ensures that a transaction global order is determined at block generation, which is compatible with all smart contract programming models. Protocols adopting other topologies either [abandon the global order](https://allquantor.at/blockchainbib/pdf/sompolinsky2016spectre.pdf) or establish it after a long confirmation delay [[1](https://eprint.iacr.org/2018/104.pdf), [2](https://eprint.iacr.org/2017/300.pdf)], limiting their efficiency or functionality.

Despite NC's merits, a scalability barrier hinders it from processing more than a few transactions per second. Two parameters collectively cap the system's throughput: the maximum block size and the expected block interval. For example, Bitcoin enforces a roughly 1 MB block size upper bound and targets a 10-minute block interval and  with its **difficulty adjustment mechanism**, translating to roughly ten transactions per second (TPS). Increasing the block size or reducing the block interval leads to longer block propagation latency or more frequent block generation events, respectively; both approaches raise the fraction of blocks generated during other blocks' propagation, thus raising the fraction of competing blocks. As at most one block among the competing ones contributes to transaction confirmation, the nodes' bandwidth on propagating other **orphaned blocks** is wasted, limiting the system's effective throughput. Moreover, raising the orphan rate downgrades the protocol's security by lowering the difficulty of double-spending attacks [[1](<https://fc15.ifca.ai/preproceedings/paper_30.pdf>), [2](<https://fc15.ifca.ai/preproceedings/paper_101.pdf>)].

Moreover, the security of NC is undermined by a [**selfish mining attack**](https://www.cs.cornell.edu/~ie53/publications/btcProcFC.pdf), which allows attackers to gain unfair block rewards by deliberately orphaning blocks mined by other miners. Researchers observe that the unfair profit roots in NC's difficulty adjustment mechanism, which neglects orphaned blocks when estimating the network's computing power. Through this mechanism, the increased orphan rate caused by selfish mining leads to lower mining difficulty, enabling the attacker's higher time-averaged block reward [[1](https://eprint.iacr.org/2016/555.pdf), [2](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-100.md), [3](https://arxiv.org/abs/1805.08281)].

In this RFC, we present the CKB consensus protocol, a consensus protocol that raises NC's performance limit and selfish mining resistance while keeping all NC's merits. Our protocol supports very short block interval by reducing the block propagation latency. The shortened block interval not only raises the blockchain's throughput, but also minimizes the transaction confirmation latency without decreasing the level of confidence, as the orphan rate remains low. Selfish mining is no longer profitable for a large range of parameters as we incorporate all blocks, including uncles, in the difficulty adjustment when estimating the network's computing power, so that the new difficulty is independent of the orphan rate.

<a name="Technical-Overview"></a>
## Technical Overview

Our consensus protocol makes three changes to NC.

<a name="#Eliminating-the-Bottleneck-in-Block-Propagation"></a>
### Eliminating the Bottleneck in Block Propagation

[Bitcoin's developers identify](https://www.youtube.com/watch?v=EHIuuKCm53o) that when the block interval decreases, the bottleneck in block propagation latency is transferring **fresh transactions**, which are newly broadcast transactions that have not finished propagating to the network when embedded in the latest block. Nodes that have not received these transactions must request them before forwarding the block to their neighbors. The resulted delay not only limits the blockchain's performance, but can also be exploited in a **de facto selfish mining attack**, where attackers deliberately embed fresh transactions in their blocks, hoping that the longer propagation latency gives them an advantage in finding the next block to gain more rewards.

Departing from this observation, our protocol eliminates the bottleneck by decoupling NC's transaction confirmation into two separate steps: **propose** and **commit**. A transaction is proposed if its truncated hash, named `txpid`, is embedded in the **proposal zone** of a blockchain block or its **uncles**---orphaned blocks that are referred to by the blockchain block. Newly proposed transactions affect neither the block validity nor the block propagation, as a node can start transferring the block to its neighbors before receiving these transactions. The transaction is committed if it appears in the **commitment zone** in a window starting several blocks after its proposal. This two-step confirmation rule eliminates the block propagation bottleneck, as committed transactions in a new block are already received and verified by all nodes when they are proposed. The new rule also effectively mitigates de facto selfish mining by limiting the attack time window.

<a name="Utilizing-the-Shortened-Latency-for-Higher-Throughput"></a>
### Utilizing the Shortened Latency for Higher Throughput

Our protocol prescribes that blockchain blocks refer to all orphaned blocks as uncles. This information allows us to estimate the current block propagation latency and dynamically adjust the expected block interval, increasing the throughput when the latency improves. Accordingly, our difficulty adjustment targets a fixed orphan rate to utilize the shortened latency without compromising security. The protocol hard-codes the upper and lower bounds of the interval to defend against DoS attacks and avoid overloading the nodes. In addition, the block reward is adjusted proportionally to the expected block interval within an epoch, so that the expected time-averaged reward is independent of the block interval.

<a name="Mitigating-Selfish-Mining-Attacks"></a>
### Mitigating Selfish Mining Attacks

Our protocol incorporate all blocks, including uncles, in the difficulty adjustment when estimating the network's computing power, so that the new difficulty is independent of the orphan rate, following the suggestion of [Vitalik](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-100.md), [Grunspan and Perez-Marco](https://arxiv.org/abs/1805.08281).

In addition, we prove that selfish mining is no longer profitable for a large range of parameters in our protocol. This prove is non-trivial in two aspects. First, Vitalik, Grunspan and Perez-Marco's informal arguments do not rule out the possibility that the attacker adapts to the modified mechanism and still gets unfair block reward. For example, the attacker may temporarily turn off some mining gears in the first epoch, causing the modified difficulty adjustment algorithm to underestimate the network's computing power, and starts selfish mining in the second epoch for a higher overall time-averaged reward. We prove that in our defense works regardless of how the attacker divides its mining power among honest mining, selfish mining and idle, and how many epochs the attack involves. Second, it is always possible that the attacker may invalidate the last few honest blocks in an epoch, preventing these blocks from being incorporated in the difficulty adjustment. We quantify the upper bound of the damage caused by this "orphan exclusion attack" in our proof, which will be released later.

<a name="Specification"></a>
## Specification

<a name="Two-Step-Transaction-Confirmation"></a>
### Two-Step Transaction Confirmation

In our protocol, we use a two-step transaction confirmation to eliminate the aforementioned block propagation bottleneck, regardless of how short the block interval is. We start by defining the two steps and the block structure, and then introduce the new block propagation protocol. 

#### Definitions

> **Definition 1:** A transaction’s proposal id `txpid` is defined as the first *l* bits of the transaction hash `txid`.

In our protocol, `txpid` does not need to be as globally unique as `txid`, as a `txpid` is used to identify a transaction among several neighboring blocks. Since we embed `txpid`s in both blocks and compact blocks, sending only the truncated `txid`s could reduce the bandwidth consumption. 

When multiple transactions share the same `txpid`s, all of them are considered proposed. In practice, we can set *l* to be large enough so that the computational effort of finding a collision is non-trivial.

> **Definition 2:** A block *B*<sub>1</sub> is considered to be the *uncle* of another block *B*<sub>2</sub> if all of the following conditions are met:
>​	(1) *B*<sub>1</sub> and *B*<sub>2</sub> are in the same epoch, sharing the same difficulty;
>​	(2) height(*B*<sub>2</sub>) > height(*B*<sub>1</sub>);
>​	(3) *B*<sub>2</sub> is the first block in its chain to refer to *B*<sub>1</sub>. 

Our uncle definition is different from [that of Ethereum](https://github.com/ethereum/wiki/wiki/White-Paper#modified-ghost-implementation), in that we do not consider how far away the two blocks' first common ancestor is, as long as the two blocks are in the same epoch.

> **Definition 3:** A transaction is *proposed* at height *h*<sub>p</sub> if its `txpid` is in the proposal zone of the main chain block with height *h*<sub>p</sub> and this block’s uncles. 

It is possible that a proposed transaction is previously proposed, in conflict with other transactions, or even malformed. These incidents do not affect the block’s validity, as the proposal zone is used to facilitate transaction synchronization.

> **Definition 4:** A non-coinbase transaction is *committed* at height *h*<sub>c</sub> if all of the following conditions are met: 
> ​	(1) the transaction is proposed at height *h*<sub>p</sub> of the same chain, and *w<sub>close</sub>  ≤  h<sub>c</sub> − h*<sub>p</sub>  ≤  *w<sub>far</sub>*
> ​	(2) the transaction is in the commitment zone of the main chain block with height *h*<sub>c</sub>; 
> ​	(3) the transaction is not in conflict with any previously-committed transactions in the main chain. 
> The coinbase transaction is committed at height *h*<sub>c</sub> if it satisfies (2).

*w<sub>close</sub>* and *w<sub>far</sub>* define the closest and farthest on-chain distance between a transaction’s proposal and commitment. We require *w<sub>close</sub>*  to be large enough so that *w<sub>close</sub>* block intervals are long enough for a transaction to be propagated to the network. 

These two parameters are also set according to the maximum number of transactions in the proposed transaction pool of a node’s memory. As the total number of proposed transactions is limited, they can be stored in the memory so that there is no need to fetch a newly committed transaction from the hard disk in most occasions. 

A transaction is considered embedded in the blockchain when it is committed. Therefore, a receiver that requires σ confirmations needs to wait for at least *w<sub>close</sub>* +σ blocks after the transaction is broadcast to have confidence in the transaction. 

In practice, this *w<sub>close</sub>* - block extra delay is compensated by our protocol’s shortened block interval, so that the usability is not affected.

#### Block and Compact Block Structure

A block in our protocol includes the following fields:

| Name            | Description                          |
| :-------------- | :----------------------------------- |
| header          | block metadata                       |
| commitment zone | transactions committed in this block |
| proposal zone   | `txpid`s proposed in this block      |
| uncle headers   | headers of uncle blocks              |
| uncles’ proposal zones   | `txpid`s proposed in the uncles              |

Similar to NC, in our protocol, a compact block replaces a block’s commitment zone with the transactions’ `shortid`s, a salt and a list of prefilled transactions. All other fields remain unchanged in [the compact block](https://github.com/bitcoin/bips/blob/master/bip-0152.mediawiki).

Additional block structure rules:

- The total size of the first four fields should be no larger than the hard-coded **block size limit**. The main purpose of implementing a block size limit is to avoid overloading public nodes' bandwidth. The uncle blocks’ proposal zones do not count in the limit as they are usually already synchronized when the block is mined. Since [RFC31], the new field `extension` is also counted in the total size.
- The number of `txpid`s in a proposal zone also has a hard-coded upper bound.

[RFC31]: ../0031-variable-length-header-field/0031-variable-length-header-field.md

Two heuristic requirements may help practitioners choose the parameters. First, the upper bound number of `txpid`s in a proposal zone should be no smaller than the maximum number of committed transactions in a block, so that even if *w<sub>close</sub>=w<sub>far</sub>*, this bound is not the protocol's throughput bottleneck. Second, ideally the compact block should be no bigger than 80 KB. According to [a 2016 study by Croman et al.](https://fc16.ifca.ai/bitcoin/papers/CDE+16.pdf), messages no larger than 80 KB have similar propagation latency in the Bitcoin network; larger messages propagate slower as the network throughput becomes the bottleneck. This number may change as the network condition improves.

#### Block Propagation Protocol

In line with [[1](https://www.cs.cornell.edu/~ie53/publications/btcProcFC.pdf), [2](https://arxiv.org/abs/1312.7013), [3](https://eprint.iacr.org/2014/007.pdf)], nodes should broadcast all blocks with valid proofs-of-work, including orphans, as they may be referred to in the main chain as uncles. Valid proofs-of-work cannot be utilized to pollute the network, as constructing them is time-consuming. 

Our protocol’s block propagation protocol removes the extra round trip of fresh transactions in most occasions. When the round trip is inevitable, our protocol ensures that it only lasts for one hop in the propagation. This is achieved by the following three rules: 

**R1: non-blocking transaction query.**
As soon as the commitment zone is reconstructed, a node forwards the CBs to its downstream peers and queries the newly-proposed transactions from its upstream peers simultaneously.

The block propagation will not be affected by these transaction queries as long as they are answered before the next $w_{\rm close}$-th block is mined.
Transactions are validated as soon as their full content is received.
The `txpid`s and their block heights are stored in the memory until they are no longer in the proposal window, regardless of whether their corresponding transactions are missing or invalid.
This will not become a DoS attack vector as the maximum sizes of the proposal window and the proposal zone are hard-coded.

To prevent the attacker from launching memory exhaustion attacks with large-sized transactions, an additional upper limit is prescribed on the total size of all newly-proposed transactions in a proposal zone.
Once this limit is reached, the node (1) deletes all large-sized transactions that appear only in this proposal zone from its memory pool, and (2) blacklists the upstream peer that contributes the most to these large-sized transactions.
The threshold for tagging large-sized transactions is not a consensus parameter, and thus can be set locally, as, e.g., twice the average size of transactions confirmed in the ten most recent blocks.

**R2: missing transactions, now or never.**
If certain committed transactions are unknown to a CB receiver, the receiver queries the sender with a short timeout.
Failure to send these transactions in time leads to the receiver turning off the HB mode (following the notations of [Compact Blocks](https://bitcoincore.org/en/2016/06/07/compact-blocks-faq/)) for the sender and turning on the HB mode for the next fastest peer.
If the downgraded sender was an outgoing connection, the receiver establishes a new connection to a random node.
Moreover, the incomplete block will not be propagated further before receiving these transactions from another peer.
No punishment is prescribed to upstream peers who do not respond to the queries on newly-proposed transactions, as it is difficult to locate the responsible parties for the delay.

Proposed-but-not-received transactions are committed either (1) in a successful transaction withholding attack, or (2) when $w_{\rm close}$ consecutive blocks are mined before the transactions proposed in the first one are synchronized.
If the upstream peer is honest, as in (2), a short timeout is adequate to transfer the missing transactions, as an honest upstream peer must not send the CBs before receiving these transactions.
In the case of (1), the attacker cannot delay the first hop of the block propagation more than the timeout value without the block being discarded.
In practice, we set the timeout to be 3.5 seconds, which is adequate for the round trip in 95\% of the cases according to our measurement (see the academic paper).

**R3: transaction push.**
If certain committed transactions are previously unknown to a CB sender, they will be embedded in the prefilled transaction list of the outgoing CBs.

This rule removes the round trip if the sender and the receiver share the same list of proposed-but-not-broadcast transactions.
In a transaction withholding attack or a `txpid` collision, this rule ensures that the secret transactions are only queried in the first hop of the block's propagation, and then pushed directly to the receivers in subsequent hops.

<a name="Dynamic-Difficulty-Adjustment-Mechanism"></a>
### Dynamic Difficulty Adjustment Mechanism

Our two-step mechanism enables us to lower the expected block interval.
The next challenge is to locate the interval that best utilizes the nodes' bandwidth without affecting security.
To tackle this challenge, we introduce an accurate dynamic DAM that exploits the bandwidth utilization to the limit of the real-time network condition.
Our goal is twofold: (**G1**) to render selfish mining unprofitable; (**G2**) to dynamically adjust the throughput based on the network's bandwidth and latency.
Meanwhile, to maximize compatibility and attack resistance, our DAM needs to satisfy four constraints, in line with NC:

**C1**. All epochs have the same target duration $L_{\rm ideal}$.

**C2.** The maximum block reward issued in an epoch $R(i)$ depends only on the epoch number $i$ so that the rewards are distributed at a predetermined rate.

**C3.** The hash rate estimation of the last epoch does not change too fast, to prevent attackers from [manipulating the DAM and forging a blockchain](https://arxiv.org/abs/1312.7013), even if some miners' network is temporarily controlled by the attacker.

**C4.** The expected block interval should abide by predetermined upper and lower bounds.
The upper bound guarantees service availability; the lower bound guarantees that NC-Max does not generate more traffic than most nodes' capacity, thus ensuring decentralization.

To achieve **G1**, NC-Max incorporates all blocks, instead of only the main chain, in calculating the *hash rate estimation* of the last epoch, and then applies a dampening factor to the estimation so that the adjusted output conforms to **C3**.
This output determines the computing efforts required in the next epoch for each reward unit.
To achieve **G2**, our DAM targets a fixed orphan rate $o_{\rm ideal}$, rather than a fixed block interval as in NC.
As our two-step confirmation ensures a relatively stable block propagation process, we can solve the expected block interval matching the target orphan rate with the last epoch's duration, orphan rate, and the main chain block number.
As the target epoch duration is fixed (**C1**), we can solve the next epoch's main chain block number, block reward, and difficulty target after applying several dampening factors and upper/lower bounds to safeguard **C2** and **C4**.

Combined with the two-step mechanism, targeting a fixed orphan rate allows us to pipeline the synchronization of previously-proposed transactions and the confirmation of recently-committed transactions, reducing NC's long idle time.

#### Notations

Similar to Nakamoto Consensus , our protocol’s difficulty adjustment algorithm is executed at the end of every epoch. It takes four inputs:

| Name            | Description                          |
| :-------------- | :----------------------------------- |
| *T*<sub>*i*</sub>          | Last epoch’s target                       |
| *L*<sub>*i*</sub> | Last epoch’s duration: the timestamp difference between epoch *i* and epoch (*i* − 1)’s last blocks |
| *C*<sub>*i*,m</sub>   | Last epoch’s main chain block count      |
| *C*<sub>*i*,o</sub>   | Last epoch’s orphan block count:  the number of uncles embedded in epoch *i*’s main chain         |

Among these inputs, *T<sub>i</sub>* and *C*<sub>*i*,m</sub> are determined by the last iteration of difficulty adjustment; *L*<sub>*i*</sub> and *C*<sub>*i*,o</sub> are measured after the epoch ends. The orphan rate *o*<sub>*i*</sub> is calculated as *C*<sub>*i*,o</sub> / *C*<sub>*i*,m</sub>. We do not include *C*<sub>*i*,o</sub> in the denominator to simplify the equation. As some orphans at the end of the epoch might be excluded from the main chain by an attack, *o*<sub>*i*</sub> is a lower bound of the actual number. However, [the proportion of deliberately excluded orphans is negligible](https://eprint.iacr.org/2014/765.pdf) as long as the epoch is long enough, as the difficulty of orphaning a chain grows exponentially with the chain length. Yet we still quantify the effect of these blocks on our defense in our second academic paper.

The algorithm outputs three values:

| Name            | Description                          |
| :-------------- | :----------------------------------- |
| *T*<sub>*i*+1</sub>          | Next epoch’s target                       |
| *C*<sub>i+1,m</sub> | Next epoch’s main chain block count |
| *r*<sub>*i*+1</sub>   | Next epoch’s block reward     |

If the network hash rate and block propagation latency remains constant, *o*<sub>*i*+1</sub> should reach the ideal value *o*<sub>ideal</sub>, unless *C*<sub>*i*+1,m</sub> is equal to its upper bound *C*<sub>m</sub><sup>max</sup>  or its lower bound *C*<sub>m</sub><sup>min</sup> . Epoch *i* + 1 ends when it reaches *C*<sub>*i*+1,m</sub> main chain blocks, regardless of how many uncles are embedded.

#### Computing the Adjusted Hash Rate Estimation

The adjusted hash rate estimation, denoted as $\hat{H}\_i$ is computed by applying a dampening factor τ to the last epoch’s actual hash rate $\hat{H}\_i'$. The actual hash rate is calculated as follows:

$$
\hat{H}\_i'
= \frac{\rm HSpace}{T_i}\cdot (C_{i,{\rm m}}+C_{i,{\rm o}})/L_i \enspace, ~~(4)
$$

where:

- HSpace is the size of the entire hash space, e.g., $2^{256}$ in Bitcoin,
- HSpace/*T<sub>i</sub>* is the expected number of hash operations to find a valid block, and 
- *C*<sub>*i*,m</sub> + *C*<sub>*i*,o</sub> is the total number of blocks in epoch *i*

$\hat{H}_i'$ is computed by dividing the expected total hash operations with the duration *L<sub>i</sub>*.

Note that (4) is the equation number. We choose not to start from (1) in order to be consistent with a prior version of the academic paper.

Now we apply the dampening filter:

$$
\hat{H}\_i =
	\left\lbrace
	\begin{array}{ll}
		{\hat{H}}\_{i-1} \cdot\frac{1}{\tau\_1}, &\hat{H}\_i'<\hat{H}\_{i-1}\cdot\frac{1}{\tau\_1}\\
		{\hat{H}}\_{i-1}\cdot \tau\_1, &\hat{H}\_i'>{\hat{H}}\_{i-1}\cdot \tau\_1\\
		{\hat{H}\_i'}, & \text{otherwise}\\
	\end{array}
	\right.\enspace ,
 $$

where ${\hat{H}}\_{i-1}$ denotes the adjusted hash rate estimation output by the last iteration of the difficulty adjustment algorithm. The dampening factor ensures that the adjusted hash rate estimation does not change more than a factor of $\tau\_1$ between two consecutive epochs. This adjustment is equivalent to the Nakamoto Consensus application of a dampening filter. Bounding the adjustment speed prevents the attacker from arbitrarily biasing the difficulty and forging a blockchain, even if some victims’ network is temporarily controlled by the attacker.

#### Modeling the Block Propagation

It is difficult, if not impossible, to model the detailed block propagation procedure, given that the network topology changes constantly over time. Luckily, for our purpose, it is adequate to express the influence of block propagation with two parameters, which will be used to compute *C*<sub>*i*+1,m</sub>  later.

We assume all blocks follow a similar propagation model, in line with [[1](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.395.8058&rep=rep1&type=pdf), [2](https://fc16.ifca.ai/bitcoin/papers/CDE+16.pdf)]. In the last epoch, it takes *d* seconds for a block to be propagated to the entire network, and during this process, the average fraction of mining power working on the block’s parent is *p*. Therefore, during this *d* seconds, $\hat{H}\_i'\times dp$ hash operations work on the parent, thus not contributing to extending the blockchain. 
Consequently, in the last epoch, the total number of hashes that do not extend the blockchain is $\hat{H}\_i'\times dp \times C\_{i,{\rm m}}$.

On the other hand, the number of hash operations working on observed orphaned blocks is ${\rm HSpace}/T_i\times C_{i,{\rm o}}$.
When the orphan rate is relatively low, we can ignore the rare event that more than two competing blocks are found at the same height. Therefore we have

$$
	\hat{H}\_i'\times dp \times C\_{i,{\rm m}}={\rm HSpace}/T_i\times C_{i,{\rm o}}\enspace.~~(5)
$$

If we combine Eqn. (4) and (5), we can solve $dp$:

$$
	dp=\frac{{\rm HSpace}/T_i\times C_{i,{\rm o}}}{\hat{H}\_i' \times C\_{i,{\rm m}}}=\frac{o_i\times L_i}{(1+o_i)C_{i,{\rm m}}}\enspace,~~(6)
$$

#### Computing the Outputs

**Main Chain Block Count.**
If the next epoch's block propagation situation is identical to the last epoch's, the value $dp$ should remain unchanged.
In order to achieve the ideal orphan rate $o_{\rm ideal}$ and **C1**---the ideal epoch duration $L_{\rm ideal}$, following the same reasoning with Eqn. (6), we should have

$$
	dp=\frac{o_{\rm ideal}\times L_{\rm ideal}}{(1+o_{\rm ideal})C_{i+1,{\rm m}}'}\enspace,~~(7)
$$

where $C_{i+1,{\rm m}}'$ is the number of main chain blocks in the next epoch, if our only goal is to achieve $o_{\rm ideal}$ and $L_{\rm ideal}$.

By combining Eqn. (6) and (7), when $o_i\neq 0$, we can solve $C_{i+1,{\rm m}}'$:

$$
	C_{i+1,{\rm m}}'=\frac{o_{\rm ideal}(1+o_i)\times L_{\rm ideal}\times C_{i,{\rm m}}}{o_i(1+o_{\rm ideal})\times L_i}\enspace.~~(8)
$$

Now in order to achieve **C4**, we can apply the upper and lower bounds to $C_{i+1,{\rm m}}'$ and get $C_{i+1,{\rm m}}$:

$$
	C_{i+1,{\rm m}} =
	\left\lbrace
	\begin{array}{ll}
		\min\lbrace C_{\rm m}^{\rm max}, \tau_2 C_{i, {\rm m}}\rbrace, &\\
		~~o_i=0~\text{or}~C_{i+1,{\rm m}}'>\min\lbrace C_{\rm m}^{\rm max}, \tau_2 C_{i, {\rm m}}\rbrace\\
		\max\lbrace C_{\rm m}^{\rm min}, C_{i, {\rm m}}/\tau_2\rbrace, &\\
		~~C_{i+1,{\rm m}}'<\max\lbrace C_{\rm m}^{\rm max}, C_{i, {\rm m}}/\tau_2\rbrace\\
		C_{i+1,{\rm m}}', & \text{otherwise}\\
	\end{array}
	\right.\enspace .~~(9)
$$

Equation (9) also covers the case of $o_i=0$.
When $L_{\rm ideal}$ is fixed (**C1**), a lower bound on $C_{i+1,{\rm m}}$ is equivalent to an upper bound on the expected block interval $\overline{t_{\rm in}}$, and vice versa.
The dampening factor $\tau_2$, also instantiated as 2 in Nervos CKB, serves both **C3** and **C4**, preventing the main chain block number from changing too fast.

**Target.**
To compute the target, we introduce an adjusted orphan rate estimation $o_{i+1}'$:

$$
	o_{i+1}' =
	\left\lbrace
	\begin{array}{ll}
		0, & o_i=0\\
		o_{\rm ideal}, & C_{i+1,{\rm m}}=C_{i+1,{\rm m}}'\\
		1/(\frac{(1+o_i)\cdot L_{\rm ideal}\cdot C_{i,{\rm m}}}{o_i\cdot L_i\cdot C_{i+1,{\rm m}}}-1), & \text{otherwise}\\
	\end{array}
	\right.\enspace .
$$

Using $o_{i+1}'$ instead of $o_{\rm ideal}$ prevents some undesirable situations when $C_{i+1,{\rm m}}$ reaches its upper or lower bound. Now we can compute $T_{i+1}$:

$$
	T_{i+1} ={\rm HSpace}/\frac{{\hat{H}\_i} \cdot L\_{\rm ideal}}{(1+o_{i+1}')\cdot C_{i+1,{\rm m}}}
	\enspace,~~(10)
$$

where ${\hat{H}\_i}\cdot L\_{\rm ideal}$ is the total number of hashes, $(1+o_{i+1}')\cdot C_{i+1,{\rm m}}$ is the total number of blocks.
The denominator in Eqn. (10) is the number of hashes required to find a block.

Note that if none of the edge cases is triggered, i.e., $\hat{H}\_i=\hat{H}\_i'$ and $C\_{i+1,{\rm m}}=C\_{i+1,{\rm m}}'$, we can combine Eqn. (4), (8), (10) and get $T_{i+1}' =T_i \times o_{\rm ideal}/o_i$.
This result is consistent with our intuition.
On the one hand, if $o_i$ is larger than the ideal value $o_{\rm ideal}$, the target lowers, increasing the difficulty of finding a block and raising the block interval if the hash rate is unchanged. Therefore, the orphan rate is lowered as it is more unlikely to find a block during another block's propagation.
On the other hand, the target increases if the last epoch's orphan rate is lower than the ideal value, decreasing the block interval and raising the system's throughput.

#### Computing the Reward for Each Block

Now we can compute the reward for each block:

$$
r_{i+1}=\min\left\lbrace\frac{R(i+1)}{C_{i+1,{\rm m}}}, \frac{R(i+1)}{C_{i+1,{\rm m}}'}\cdot \frac{T_{i+1}'}{T_{i+1}}\right\rbrace\enspace,~~(11)
$$

The two cases differ only in the edge cases. The first case guarantees that the total reward issued in epoch *i* + 1 will not exceed R(*i* + 1).

