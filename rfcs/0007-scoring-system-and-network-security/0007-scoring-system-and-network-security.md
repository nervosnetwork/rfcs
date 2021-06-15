---
Number: "0007"
Category: Standards Track
Status: Proposal
Author: Jinyang Jiang
Organization: Nervos Foundation
Created: 2018-10-02
---

# P2P Scoring System And Network Security

## Abstract

This document describes the scoring system of CKB P2P Networking layer and several networking security strategies based on it.


## Motivation

CKB network is designed as an open peer-to-peer network and any node can join the network without permission. This openness, however, also makes it possible for malicious nodes to join and attack the peer-to-peer network.

There were "Eclipse Attack" security issues in both Bitcoin network and Ethereum network, which also designed as the open peer-to-peer network.
The principle of Eclipse Attack is that the attacker would occupy all Peers connection slots of the victim node by manipulating malicious nodes, then filter the victim's view of the blockchain network.

Via "Eclipse Attack" the attacker can take down a victim node with low cost. After that, the attacker could control the victim's mining power for its nefarious purposes, or cheat this victim node to launch a double spent attack.

Reference paper -- [Eclipse Attacks on Bitcoin’s Peer-to-Peer Network][2] 

There are several strategies to prevent "Eclipse attack" introduced in this paper and parts of them have already been implemented in the Bitcoin network. That is to say, this document will describe how to deploy these strategies to CKB network.

In addition, this document also describes the scoring system of CKB P2P Networking layer and we want to handle more generalized network security cases by combining it with more sophisticated security strategies from the Bitcoin network.

Based on the scoring system, we can follow several rules below to handle malicious peers:

1. Nodes should store peers information as much as possible.
2. Nodes need to score Peers' good and bad behavior continuously.
3. Nodes should retain good (high-score) peers and evict bad (low-score) peers out.

CKB client should implement the scoring system and following security strategies.


## Specification

### Terminology

* `Node`
* `Peer` - Other nodes connected through the network
* `PeerInfo` - A data struct used for describing information of `Peer`
* `PeerStore` - A component used to store `PeerInfo`
* `outbound peer` - describe a peer which initiates a connection.
* `inbound peer` - describe a peer which accepts a connection.
* `max_outbound` - Max number of outbound peers.
* `max_inbound` - Max number of inbound peers.
* `network group` - A concept which used when to evict out peers, calculating from the peer's IP address(prefix 16 bits of IPv4 and prefix 32 bits of IPv6).

### Peer Store and Peer Info

PeerStore should be persistent storage and store PeerInfos as more as possible.

PeerInfo should include fields below at least:

```
PeerInfo { 
  NodeId,
  ConnectedIP,
  Direction,  // Inbound or Outbound
  LastConnectedAt, // The time of the last connection 
  Score
}
```

### Scoring System

Parameters below are required in Scoring System:

* `PEER_INIT_SCORE` - the initial score of peers
* `BEHAVIOURS` - a set of peer's possible behaviors, such as: `UNEXPECTED_DISCONNECT`, `TIMEOUT`, `CONNECTED`
* `SCORING_SCHEMA` - describe different scores corresponding to different behaviors, such as: `{"TIMEOUT": -10, "CONNECTED": 10}`
* `BAN_SCORE` - a peer will be banned when its score is lower than this value.

Network layer should provide the scoring interface, allow upper sub-protocols (such as: `sync`, `relay`) to report behaviors of a peer, and update peer's score based on `SCORING_SCHEMA`.

``` ruby
peer.score += SCOREING_SCHEMA[BEHAVIOUR]
```

Peer's behaviors can be distinguished into three categories:

1. Correct behaviors which follow the specification:
    * For example, a node downloads a new block from a peer; a node connects to a peer successfully. Considering a bad peer may pretend like a good one before launching an attack, we should give the peer a relatively low positive score instead of giving a high score at once to encourage the peer to accumulate his credit by performing good behaviors for a long time.
2. Incorrect behaviors which may be caused by network exception:
    * For example, a peer disconnect unexpectedly; a node failed to connect to a peer; ping timeout. Since we can't tell whether these behaviors are intentional bad behavior or caused by the network,  we should give the peer a little negative score to keep tolerant.
3. Incorrect behaviors which violate the protocol:
    * For example, a peer sends an illegal encoded content; a peer sends an invalid block; a peer sends an invalid transaction. We should give a peer a negative score when we can be pretty sure its behavior is malicious, and when a peer's score is lower than `BAN_SCORE`, this peer should be banned.

Examples:

* Peer 1 connected successfully. A node reported this peer's `CONNECTED` behavior and peer 1 got a 10 score rewarded.
* Peer 2 gets a connection timeout. A node reports `TIMEOUT` behavior and peer 2 get a -10 score as punishment.
* Peer 1 sent repetitive `GET_BLOCK` messages. A node reported `DUPLICATED_REQUEST_BLOCK` behavior and peer 1 got a -50 score as punishment.
* Peer 1's score is lower than `BAN_SCORE`, node disconnect with peer 1 then ban the peer.

Parameters like `BEHAVIOURS`, `SCORING_SCHEMA` are not a part of consensus protocol, so CKB client should tune these parameters according to the actual situation of the network.

### Outbound peers selection

The "Eclipse Attack" paper describes a critical security issue during Bitcoin node restarting process:

1. The attacker tries to fit the victim node's addrman(Bitcoin's peer store) with attacker's bad nodes' addresses.
2. The attacker waits the victim node to restart (or use several methods to force it).
3. After the restart, the victim node will select some address from addrman to connect.
4. The attack successes if all outbound connections of the victim node are connected to the attacker's bad nodes.

CKB should avoid this problem when initialize the network.

#### The process of initializing outbound peers

Required parameters:

* `TRY_SCORE` - We only try to connect a peer when its score is higher than this value.
* `ANCHOR_PEERS` - the number of anchor peers should be less than `max_outbound`, such as `2`

Required variables:

* `try_new_outbound_peer` - network component checks this variable to decide whether to connect to extra outbound peers or not.

The process of choosing an outbound peer:

1. Execute step 2 if currently connected outbound peers less than `ANCHOR_PEERS`, otherwise execute step 3.
2. Choose an "anchor peer":
    1. Choose recently connected outbound peers from peer store(can select by `LastConnectedAt` field of peer info).
    2. Execute step 3, if `recent_peers` is empty; otherwise, we choose the peer which has got the highest score from `recent_peers` and return it as the new outbound peer.
3. Choose peer info randomly which must have a higher score than `TRY_SCORE` and have different `network group` from all currently connected outbound peers from PeerStore, return it as the new outbound peer and if we can't find anyone, then execute step 4.
4. Choose peer info randomly from boot nodes.

In step 1, we choose an anchor peer if the node has zero or only a few connected outbound peers. This behavior refers to "Anchor Connection" strategy which described in the [Eclipse Attack][2] paper.

Pseudocode:

``` ruby
# return our new outbound peer
def find_outbound_peer
  connected_outbound_peers = connected_peers.select{|peer| peer.outbound? && !peer.feeler? }
  # step 1
  if connected_outbound_peers.length < ANCHOR_PEERS
    find_anchor_peer() || find_random_peer() || random_boot_node()
  else
    find_random_peer() || random_boot_node()
  end
end

# step 2
def find_anchor_peer
  last_connected_peers = peer_store.sort_by{|peer| -peer.last_connected_at}.take(max_outbound)
  # return the higest scored peer info
  last_connected_peers.sort_by(&:score).last
end

# step 3
def find_random_peer
  connected_outbound_peers = connected_peers.select{|peer| peer.outbound? && !peer.feeler? }
  exists_network_groups = connected_outbound_peers.map(&:network_group)
  candidate_peers = peer_store.select do |peer| 
    peer.score >= TRY_SCORE && !exists_network_groups.include?(peer.network_group)
  end
  candidate_peers.sample
end

# step 4
def random_boot_node
  boot_nodes.sample
end
```

The node should repeat this process until the number of connected outbound peers is equal to or greater than  `max_outbound` and `try_new_outbound_peer` is `false`.

``` ruby
check_outbound_peers_interval = 15
# continually check the number of outbound peers
loop do
  sleep(check_outbound_peers_interval)
  connected_outbound_peers = connected_peers.select{|peer| peer.outbound? && !peer.feeler? }
  if connected_outbound_peers.length >= max_outbound && !try_new_outbound_peer 
    next
  end
  new_outbound_peer = find_outbound_peer()
  connect_peer(new_outbound_peer)
end
```

`try_new_outbound_peer` variable is used for some situation where a node can't get any useful messages in a duration time. Then we will set `try_new_outbound_peer` to `true` and allow the node to connect to more extra outbound peers. This strategy would be introduced later.

Under this strategy, the attacker must achieve the following conditions to apply an eclipse attack:

1. The attacker needs to have `n` malicious peers (`n == ANCHOR_PEERS`) to be the victim node's outbound peers and these peers must have the highest scores.
2. The attacker needs to prepare at least `max_outbound - ANCHOR_PEERS` bad peers' addresses in PeerStore. At the same time, the attacker must make sure that the randomly selected `max_outbound - ANCHOR_PEERS` outbound peers are all camouflage nodes of the attacker.


#### Extra outbound peers and eviction

Network component should check the main protocol (for example: `sync` protocol in CKB) status every few minutes.

``` ruby
def sync_maybe_stale
  now = Time.now
  # use block product time to detect network status
  # we consider network maybe stale if block not produced within a predicted time
  last_tip_updated_at < now - block_produce_interval * n
end
```

The network component should set `try_new_outbound_peer` to `true` when `sync` protocol doesn't work and set back to `false` when `sync` protocol puts back.

``` ruby
check_sync_stale_at = Time.now
loop_interval = 30
check_sync_stale_interval = 15 * 60 # 15 minutes

loop do
  sleep(loop_interval)
  # try evict
  evict_extra_outbound_peers()
  now = Time.now
  if check_sync_stale_at >= now
    # update try_new_outbound_peer
    set_try_new_outbound_peer(sync_maybe_stale())
    check_sync_stale_at = now + check_sync_stale_interval
  end
end
```

CKB network will try to connect to extra outbound peers continually when `try_new_outbound_peer` is `true`, and try to evict useless extra peers every few minutes to prevent too many connections.

``` ruby
# eviction logic
def evict_extra_outbound_peers
  connected_outbound_peers = connected_peers.select{|peer| peer.outbound? && !peer.feeler? }
  if connected_outbound_peers.length <= max_outbound
    return
  end
  now = Time.now
  # here use last_block_anoncement_at to evict peers, we assume the oldest one is useless for us
  evict_target = connected_outbound_peers.sort_by do |peer|
    peer.last_block_announcement_at
  end.first
  if evict_target
    if now - evict_target.last_connected_at > MINIMUM_CONNECT_TIME && !is_downloading?(evict_target)
      disconnect_peer(evict_target)
      # prevent connect to too many peers
      set_try_new_outbound_peer(false)
    end
  end
end
```

### The process of accepting inbound peers

In Bitcoin, a node will try to evict connected inbound peers if the number of connected inbound peers reaches `max_inbound` and another new inbound connection tries to connect. (check [Bitcoin source code][1] for details)

This eviction behavior is intended to keep high-quality peers and evict low-quality peers.

CKB refers to Bitcoin's eviction test and steps are as follows:

1. Consider currently connected inbound peers as `candidate_peers`.
2. Protect peers(`N` represent the number of peers to protect in each step):
    1. Delete `N` peers from `candidate_peers` which has the highest score.
    2. Delete `N` peers from `candidate_peers` which has the lowest ping.
    3. Delete `N` peers from `candidate_peers` which most recently sent us messages.
    4. Delete `candidate_peers.size / 2` peers from `candidate_peers` which have the longest connection time.
3. Group `candidate_peers` according to `network group` field.
4. Find out the group which contains the most peers.
5. Evict the lowest scored peer from the group found in step 4 if it is not empty. Otherwise, reject the connection from the new peer.

We protect some peers from eviction based on characteristics that an attacker is hard to simulate or manipulate, to enhence the security of the network.

### Feeler Connection

Feeler Connection is intended to test a peer is connectable or not.

Node will start a feeler connection every few minutes after outbound peers reach `max_outbound` limit.

1. Pick out peer info from PeerStore randomly which we never connected to
2. Connect to this peer
3. Run handshake protocol
4. Disconnect

Feeler peers would be assumed to disconnect soon.

### Delete peer info from PeerStore

Required parameters:

* `PEER_STORE_LIMIT` - max number of PeerInfo in PeerStore
* `PEER_NOT_SEEN_TIMEOUT` - used for protecting peers which recently connected. Only peer info over `last_connected_to` would be deleted. 

When the number of peer info reaches `PEER_STORE_LIMIT`:

1. Group all PeerInfos in PeerStore according to `network group` field
2. Find out the group which contains the most peer infos
3. Search peers have not been connected recently from this group: `peer.last_connected_at < Time.now - PEER_NOT_SEEN_TIMEOUT`
4. Find out the lowest scored peer info as `candidate_peer_info`
5. if `candidate_peer_info.score < new_peer_info.score` then we delete `candidate_peer_info` and add `new_peer_info`, otherwise we do not accept `new_peer_info`

## References

1. [Bitcoin source code][1]
2. [Eclipse Attacks on Bitcoin’s Peer-to-Peer Network][2]

[1]: https://github.com/bitcoin/bitcoin
[2]: https://eprint.iacr.org/2015/263.pdf

