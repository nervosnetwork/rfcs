---
Number: 0007
Category: Informational
Status: Draft
Author: Jinyang Jiang
Organization: Nervos Foundation
Created: 2018-10-02
---

# P2P Scoring System And Network Security

## Abstract

This document describes the scoring system of CKB P2P Networking layer and several networking security strategies based on it.


## Motivation

There were "Eclipse Attack" security issues in both Bitcoin network and Ethereum network，
The principle of Eclipse Attack is that the attacker would occupy all Peers connection slots of the victim node by manipulating malicious nodes, then filter the victim's view of the blockchain network.

Via "Eclipse Attack" the attacker can take down victim node with small costs, after the attack, the attacker can control victim's mining power for its nefarious purposes, or launch a double spent attack on victim node.

which described in the paper -- [Eclipse Attacks on Bitcoin’s Peer-to-Peer Network][2] 

There are several strategies introduced in the paper to prevent "Eclipse attack", part of them are implemented in the Bitcoin network, this document describes how to deploy these strategies to CKB network.

This document also describes the scoring system of CKB P2P Networking layer. We can take the sophisticated security strategies from the Bitcoin network and combine it with the scoring system to handling more generalized network security cases.

Based on the scoring system, we can follow several rules for handling bad peers:

1. Node should store peers information as more as possible
2. Node need scoring peers based on their good behavior or bad behavior
3. Node should keep good peers(high score) and evict bad peers(low score).

CKB client should implement the scoring system and following security strategies.


## Specification

### Terminology

* `Node`
* `Peer` - Other nodes we connected through the network
* `PeerInfo` - A data struct to describe information of `Peer`
* `PeerStore` - A component used to store `PeerInfo`
* `outbound peer` - describe a peer which we initiate a connection.
* `inbound peer` - describe a peer which the peer initiates a connection.
* `max_outbound` - Max number of outbound peers.
* `max_inbound` - Max number of inbound peers.
* `network group` - A concept we used to evict peers, calculate from the peer's IP address(prefix 16 bits of IPv4, prefix 32 bits of IPv6).

### Peer Store and Peer Info

PeerStore should be persisted storage, and store PeerInfos as more as possible.

PeerInfo should at least includes below fields:

```
PeerInfo { 
  NodeId,
  ConnectedIP,
  Direction,  // Inbound or Outbound
  LastConnectedAt, // Last time we success connected with this peer
  Score
}
```

### Scoring System

Scoring System required parameters:

* `PEER_INIT_SCORE` - the initial score of peers
* `BEHAVIOURS` - a set of peer's possible behaviors, such as: `UNEXPECTED_DISCONNECT`, `TIMEOUT`, `CONNECTED`
* `SCORING_SCHEMA` - a key-value pair describe scores of behaviours, such as: `{"TIMEOUT": -10, "CONNECTED": 10}`
* `BAN_SCORE` - peer will be ban when peer's score is lower than this value.

Network layer should provide the scoring interface, allow upper sub-protocols (such as: `sync`, `relay`) to report behaviors of a peer, and update peer's score based on `SCORING_SCHEMA`.

``` ruby
peer.score += BEHAVIOURS[i] * SCOREING_SCHEMA[BEHAVIORS[i]]
```

Peer's behaviors can be distinguished into three categories:

1. Correct behaviors which follow the specification:
    * For example, node downloads a new block from a peer; node success connects to a peer. Consider a bad peer may pretend like a good one before launch an attack, we should give the peer little positive score instead give a vast score at once to encourage peer to accumulate his credit by doing good behavior in a long time
2. Incorrect behaviors which may be caused by network exception:
    * For example, peer unexpected disconnect; node failed to connect to a peer; ping timeout. Since we can't distinguish these behaviors is intended bad behavior or caused by the network,  we should give the peer a little negative score to keep tolerant.
3. Incorrect behaviors which violent the specification:
    * For example, peer sent an illegal encoded content; peer sent an invalid block; peer sent an invalid transaction. We should give peer a vast negative score when we sure peer's behavior is violent the specification, and when peer's score is lower than `BAN_SCORE`, the peer should be banned

Example:

* Peer 1 connected successful, node report `CONNECTED` behavior and peer 1 get 10 score reward.
* Peer 2 connected timeout, node report `TIMEOUT` behavior and peer 2 get -10 score punishment.
* Peer 1 send duplicate `GET_BLOCK` messages, node report `DUPLICATED_REQUEST_BLOCK` behavior and peer 1 get -50 score punishment.
* Peer 1's score is lower than `BAN_SCORE`, node disconnect with peer 1 then ban the peer.

Parameters like `BEHAVIOURS`, `SCORING_SCHEMA` is not a part of consensus protocol, CKB client should tune these parameters depend on the actual situation of the network.

### Outbound peers selection

The "Eclipse Attack" paper describes a critical security issue during Bitcoin node restarting process:

1. The attacker tries to fit the victim node's addrman(Bitcoin's peer store) with attacker's bad nodes' addresses.
2. Attacker waits for the victim node to restart (or use several methods to force it).
3. After the restart, the victim node will select some address from addrman to connect.
4. The attack success if all outbound connection of the victim node's is connected to the attacker's bad nodes.

CKB node should avoid this when initialized network peers.

#### The process of initializing outbound peers

Required parameters:

* `TRY_SCORE` - We only try to connect a peer when it's score is higher than this value.
* `ANCHOR_PEERS` - the number of anchor peers, this value should less than `max_outbound`, such as `2`

Required variables:

* `try_new_outbound_peer` - network component checks this variable to decide whether to connect to extra outbound peers or not.

The process of choosing an outbound peer:

1. Execute step 2 if currently connected outbound peers less than `ANCHOR_PEERS`, otherwise execute step 3.
2. Choice an "anchor peer":
    1. Choice recent connected outbound peers from peer store(can select by `LastConnectedAt` field of peer info).
    2. Execute step 3 if `recent_peers` is empty; otherwise, we find the highest peer from `recent_peers` and return it as the new outbound peer.
3. Randomly pick peer info from peer store which must have a higher score than `TRY_SCORE` and have different `network group` with all currently connected outbound peers, return it as the new outbound peer if we can find one.
4. Randomly pick peer info from boot nodes.

In step 1 we choice an anchor peer if the node has zero or only a few connected outbound peers, this behavior refer to "Anchor Connection" strategy which the [Eclipse Attack][2] paper described.

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

Node should repeat this process until connected outbound peers reach `max_outbound` and `try_new_outbound_peer` is `false`.

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

`try_new_outbound_peer` variable is used for some situation when a node can't get any usage messages in a duration time, we set `try_new_outbound_peer` to `true` and allow the node to connect to more extra outbound peers, we'll introduce this strategy later.

Under this strategy, the attacker must achieve the following conditions to apply an eclipse attack:

1. Attacker have `n` bad peers (`n == ANCHOR_PEERS`) become victim node's outbound peers and these peers must have the highest scores.
2. Attacker need have at least `max_outbound - ANCHOR_PEERS` bad peer infos in peer store, and at least `max_outbound - ANCHOR_PEERS` of them be randomly selected as outbound peers.


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

The network component should set `try_new_outbound_peer` to `true` when detect `sync` protocol stale and set back to `false` when detect protocol is recovery.

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

CKB network will to continually try to connect to extra outbound peers when `try_new_outbound_peer` is `true`, and check outbound peers number every few minutes and trying to evict useless extra peers to prevent we have too many connections.

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

### The process of accept inbound peers

In Bitcoin, a node will try to evict connected inbound peers if the number of connected inbound peers reach `max_inbound` and another new inbound connection detected. (check [Bitcoin source code][1] for detail)

This eviction behavior is intended to keep high-quality peer and evict low-quality peer.

CKB should implement the eviction as the following steps:

1. group connected inbound peers by `network group` field
2. find the group which contains most peers
3. find the lowest score in the group, evict the lowest scored peer if new inbound peer's score is higher than this; otherwise, we disconnect the new peer

### Feeler Connection

Feeler Connection is intended to：

* Test a peer is connectable or not
* Discovery more address to fill the peer store

Node will start a feeler connection every few minutes after outbound peers reach `max_outbound` limit.

1. Randomly choice peer info from peer store which score should higher than `TRY_SCORE`
2. Connect to peer
3. Run node discovery protocol with the peer
4. Disconnect

Feeler peers should be assumed to be disconnected soon.

### delete peer info from peer store

Required parameters:

* `PEER_STORE_LIMIT` - max number of peer info in peer store
* `PEER_NOT_SEEN_TIMEOUT` - used to protect peers which we recently connected, we only delete peer info which `last_connected_to` is older than this value. 

When the number of peer info reach `PEER_STORE_LIMIT`:

1. group all peer infos in peer store by `network group` field
2. find the group which contains most peer infos
3. find peers we have not seen recently from this group: `peer.last_connected_at < Time.now - PEER_NOT_SEEN_TIMEOUT`
4. find lowest scored peer info as `candidate_peer_info`
5. if `candidate_peer_info.score < new_peer_info.score` than we delete `candidate_peer_info` and add `new_peer_info`, otherwise we do not accept `new_peer_info`

## References

1. [Bitcoin source code][1]
2. [Eclipse Attacks on Bitcoin’s Peer-to-Peer Network][2]

[1]: https://github.com/bitcoin/bitcoin
[2]: https://eprint.iacr.org/2015/263.pdf

