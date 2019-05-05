---
Number: "0007"
Category: Standards Track
Status: Proposal
Author: Jinyang Jiang
Organization: Nervos Foundation
Created: 2018-10-02
---

# P2P 评分系统和网络安全

## 简介

本篇 RFC 描述了 CKB P2P 网络层的评分系统，以及基于评分的网络安全策略。


## 目标

CKB 网络被设计为开放的 P2P 网络，任何节点都能无需许可的加入网络，但网络的开放性同时使得恶意节点也能够加入并对 P2P 网络进行攻击。

同样采用开放性 P2P 网络的比特币和以太坊中都曾有「日蚀攻击」的安全问题。
日蚀攻击的原理是攻击者通过操纵恶意节点占领受害者节点所有的 Peers 连接，以此控制受害者节点可见的网络。

攻击者可以用极少成本实施日蚀攻击，攻击成功后可以操纵受害节点的算力做些恶意行为, 或欺骗受害节点进行双花交易。

参考论文 -- [Eclipse Attacks on Bitcoin’s Peer-to-Peer Network][2]

论文中同时提出了几种防范手段, 其中部分已经在比特币主网应用，
本 RFC 参考比特币网络的实现，描述如何在 CKB 网络中正确应用这些措施。

RFC 同时描述了 CKB P2P 网络的评分机制，
结合 CKB 的评分机制，可以使用比特币中成熟的安全措施来处理更加通用的攻击场景。

基于 CKB 的评分机制，我们遵循几条规则来处理恶意 Peers：

1. 节点应尽可能的存储已知的 Peers 信息
2. 节点需要不断对 Peer 的好行为和坏行为进行评分
3. 节点应保留好的(分数高的) Peer，驱逐坏的(分数低) Peer

RFC 描述了客户端应该实现的打分系统和下文的几种安全策略。


## Specification

### 术语

* `Node` - 节点
* `Peer` - 网络上的其他节点
* `PeerInfo` - 描述 Peer 信息的数据结构
* `PeerStore` - 用于存储 PeerInfo 的组件
* `outbound peer` - 连接由节点发起
* `inbound peer` - 连接由 Peer 发起
* `max_outbound` - 节点主动连接的 Peers 上限
* `max_inbound` - 节点被动接受的 Peers 上限
* `network group` - 驱逐节点时用到的概念，对 Peer 连接时的 IP 计算，IPv4 取前 16 位，Ipv6 取前 32 位


### PeerStore 和 PeerInfo

PeerStore 应该做到持久化存储, 并尽可能多的储存已知的 PeerInfo

PeerInfo 至少包含以下内容

```
PeerInfo { 
  NodeId, // Peer 的 NodeId
  ConnectedIP,  // 连接时的 IP
  Direction,  // Inbound or Outbound
  LastConnectedAt, // 最后一次连接的时间
  Score // 分数
}
```

### 评分系统

评分系统需要以下参数

* `PEER_INIT_SCORE` - Peers 的初始分数
* `BEHAVIOURS` - 节点的行为, 如 `UNEXPECTED_DISCONNECT`, `TIMEOUT`, `CONNECTED` 等
* `SCORING_SCHEMA` - 描述不同行为对应的分数, 如 `{"TIMEOUT": -10, "CONNECTED": 10}`
* `BAN_SCORE` - Peer 评分低于此值时会被加入黑名单

网络层应该提供评分接口，允许 `sync`, `relay` 等上层子协议报告 peer 行为，
并根据 peer 行为和 `SCORING_SCHEMA` 调整 peer 的评分。

``` ruby
peer.score += SCOREING_SCHEMA[BEHAVIOUR]
```

Peer 的评分是 CKB P2P 网络安全的重要部分，peer 的行为可以分为如下三种：

1. 符合协议的行为:
    * 如: 从 peer 获取了新的 block、节点成功连接上 peer 。 当 peer 作出符合协议的行为时，节点应上调对 peer 评分，
考虑恶意 Peer 有可能在攻击前进行伪装，
对好行为奖励的分数不应一次性奖励太多，
而是鼓励 peer 长期进行好的行为来积累信用。

2. 可能由于网络异常导致的行为:
    * 如: peer 异常断开、连接 peer 失败、ping timeout。
对这些行为我们采用宽容性的惩罚，下调对 peer 的评分，但不会一次性下调太多。

3. 明显违反协议的行为:
    * 如: peer 发送无法解码的内容、peer 发送 invalid block, peer 发送 invalid transaction。
当我们可以确定 peer 存在明显的恶意行为时，对 peer 打低分，如果 peer 评分低于 `BAN_SCORE` ，将 peer 加入黑名单并禁止连接。

例子:
* peer 1 连接成功，节点报告 peer1 `CONNECTED` 行为，peer 1 加 10 分
* peer 2 连接超时，节点报告 peer2 `TIMEOUT` 行为，peer 2 减 10 分
* peer 1 通过 `sync` 协议发送重复的请求，节点报告 peer 1 `DUPLICATED_REQUEST_BLOCK` 行为，peer 1 减 50 分
* peer 1 被扣分直至低于 `BAN_SCORE`, 被断开连接并加入黑名单

`BEHAVIOURS`、 `SCORING_SCHEMA` 等参数不属于共识协议的一部分，CKB 实现应该根据网络实际的情况对参数调整。


### 节点 outbound peers 的选择策略

[日蚀攻击论文][2]中提到了比特币节点重启时的安全问题：

1. 攻击者事先利用比特币的节点发现规则填充受害节点的地址列表
2. 攻击者等待或诱发受害者节点重启
3. 重启后，受害者节点会从 addrman (类似 peer store) 中选择一些地址连接
3. 受害节点的所有对外的连接都连接到了恶意 peers 则攻击者攻击成功

CKB 在初始化网络时应该避免这些问题

#### Outbound peers 连接流程

参数说明: 
* `TRY_SCORE` - 设置一个分数，仅当 PeerInfo 分数高于 `TRY_SCORE` 时节点才会去尝试连接
* `ANCHOR_PEERS` - 锚点 peer 的数量，值应该小于 `max_outbound` 如 `2`

变量:
* `try_new_outbound_peer` - 设置节点是否该继续发起新的 Outbound 连接

选择一个 outbound peer 的流程:

1. 如果当前连接的 outbound peers 小于 `ANCHOR_PEERS` 执行 2， 否则执行 3
2. 选择一个锚点 peer:
    1. 从 PeerStore 挑选最后连接过的 `max_bound` 个 outbound peers 作为 `recent_peers`
    2. 如果 `recent_peers` 为空则执行 3，否则从 `recent_peers` 中选择分数最高的节点作为 outbound peer 返回
3. 在 PeerStore 中随机选择一个分数大于 `TRY_SCORE` 且 `NetworkGroup` 和当前连接的 outbound peers 都不相同的 peer info，如果找不到这样的 peer info 则执行 5，否则将这个 peer info 返回
4. 从 `boot_nodes` 中随机选择一个返回

伪代码

``` ruby
# 找到一个 outbound peer 候选
def find_outbound_peer
  connected_outbound_peers = connected_peers.select{|peer| peer.outbound? && !peer.feeler? }
  if connected_outbound_peers.length < ANCHOR_PEERS
    find_anchor_peer() || find_random_peer() || random_boot_node()
  else
    find_random_peer() || random_boot_node()
  end
end

def find_anchor_peer
  last_connected_peers = peer_store.sort_by{|peer| -peer.last_connected_at}.take(max_bound)
  # 返回最高分的 peer info
  last_connected_peers.sort_by(&:score).last
end

def find_random_peer
  connected_outbound_peers = connected_peers.select{|peer| peer.outbound? && !peer.feeler? }
  exists_network_groups = connected_outbound_peers.map(&:network_group)
  candidate_peers = peer_store.select do |peer| 
    peer.score >= TRY_SCORE && !exists_network_groups.include?(peer.network_group)
  end
  candidate_peers.sample
end

def random_boot_node
  boot_nodes.sample
end
```


节点应该重复以上过程，直到节点正在连接的 outbound peers 数量大于等于 `max_outbound` 并且 `try_new_outbound_peer` 为 `false`。

``` ruby
check_outbound_peers_interval = 15
# 每隔几分钟检查 outbound peers 数量
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

`try_new_outbound_peer` 的作用是在一定时间内无法发现有效消息时，允许节点连接更多的 outbound peers，这个机制在后文介绍。

该策略在节点没有 Peers 时会强制从最近连接过的 outbound peers 中选择，这个行为参考了[日蚀攻击论文][2]中的 Anchor Connection 策略。

攻击者需要做到以下条件才可以成功实施日蚀攻击

1. 攻击者有 `n` 个伪装节点(`n == ANCHOR_PEERS`) 成为受害者节点的 outbound peers，这些伪装节点同时要拥有最高得分
2. 攻击者需要准备至少 `max_outbound - ANCHOR_PEERS` 个伪装节点地址在受害者节点的 PeerStore，并且受害者节点的随机挑选的 `max_outbound - ANCHOR_PEERS` 个 outbound peers 全部是攻击者的伪装节点。

#### 额外的 outbound peers 连接和驱逐

网络组件应该每隔几分钟检测子协议中的主要协议如 `sync` 协议是否工作

``` ruby
def sync_maybe_stale
  now = Time.now
  # 可以通过上次 Tip 更新时间，出块间隔和当前时间判断 sync 是否正常工作
  last_tip_updated_at < now - block_produce_interval * n
end
```

当我们发现 `sync` 协议无法正常工作时，应该设置 `try_new_outbound_peer` 变量为 `true`，当发现 `sync` 协议恢复正常时设置 `try_new_outbound_peer` 为 `false`

``` ruby
check_sync_stale_at = Time.now
loop_interval = 30
check_sync_stale_interval = 15 * 60 #(15 minutes)

loop do
  sleep(loop_interval)
  # try evict
  evict_extra_outbound_peers()
  now = Time.now
  if check_sync_stale_at >= now
    set_try_new_outbound_peer(sync_maybe_stale())
    check_sync_stale_at = now + check_sync_stale_interval
  end
end
```

当 `try_new_outbound_peer` 为 `true` 时 CKB 网络将会持续的尝试连接额外的 outbound peers，并每隔几分钟尝试逐出没有用的额外 outbound peers，这个行为防止节点有过多的连接。

``` ruby
def evict_extra_outbound_peers
  connected_outbound_peers = connected_peers.select{|peer| peer.outbound? && !peer.feeler? }
  if connected_outbound_peers.length <= max_outbound
    return
  end
  now = Time.now
  # 找出连接的 outbound peers 中 last_block_announcement_at 最老的 peer
  evict_target = connected_outbound_peers.sort_by do |peer|
    peer.last_block_announcement_at
  end.first
  if evict_target
    # 至少连接上这个 peer 一段时间，且当前没有从这个 peer 下载块
    if now - evict_target.last_connected_at > MINIMUM_CONNECT_TIME && !is_downloading?(evict_target)
      disconnect_peer(evict_target)
      # 防止连接过多的 outbound peer
      set_try_new_outbound_peer(false)
    end
  end
end
```


### 节点 inbound peers 接受机制

比特币中当节点的被动 peers 连满同时又有新 peer 尝试连接时，节点会对已有 peers 进行驱逐测试(详细请参考 [Bitcoin 源码][1])。

驱逐测试的目的在于节点保留高质量 peer 的同时，驱逐低质量的 peer。

CKB 参考了比特币的驱逐测试，步骤如下:

1. 找出当前连接的所有 inbound peers 作为 `candidate_peers`
2. 保护 peers (`N` 代表每一步中我们想要保护的 peers 数量):
    1. 从 `candidate_peers` 找出 `N` 个分数最高的 peers 删除
    2. 从 `candidate_peers` 找出 `N` 个 ping 最小的 peers 删除
    3. 从 `candidate_peers` 找出 `N` 个最近发送消息给我们的 peers 删除
    4. 从 `candidate_peers` 找出 `candidate_peers.size / 2` 个连接时间最久的 peers 删除
3. 按照 `network group` 对剩余的 `candidate_peers` 分组
4. 找出包含最多 peers 的组
5. 驱逐组中分数最低的 peer，找不到 peer 驱逐时则拒绝新 peer 的连接

我们基于攻击者难以模拟或操纵的特征来保护一些 peers 免受驱逐，以增强网络的安全性。

### Feeler Connection

Feeler Connection 机制的目的在于测试 Peer 是否可以连接。

当节点的 outbound peers 数量达到 `max_outbound` 限制时，
节点会每隔一段时间(一般是几分钟)主动发起 feeler connection：

1. 从 PeerStore 中随机选出一个未连接过的 peer info
2. 连接该 peer
3. 执行握手协议
4. 断开连接

Feeler peer 会被假设为很快断开连接

### PeerStore 清理

设置一些参数：
`PEER_STORE_LIMIT` - PeerStore 最多可以存储的 PeerInfo 数量
`PEER_NOT_SEEN_TIMEOUT` - 用于判断 peer info 是否该被清理，如该值设为 15 天，则表示最近 15 天内连接过的 peer 不会被清理

PeerStore 中存储的 PeerInfo 数量达到 `PEER_STORE_LIMIT` 时需要清理，过程如下：

1. 按照 `network group` 给 PeerStore 中的 PeerInfo 分组
2. 找出包含最多节点的组
3. 在组中搜索最近没有连接过的 peers `peer.last_connected_at < Time.now - PEER_NOT_SEEN_TIMEOUT`
4. 在该集合中找到分数最低的 PeerInfo `candidate_peer_info`
5. 如果 `candidate_peer_info.score < new_peer_info.score` 则删掉 `candidate_peer_info` 并插入 `new_peer_info`，否则不接受 `new_peer_info`


## 参考

1. [Bitcoin source code][1]
2. [Eclipse Attacks on Bitcoin’s Peer-to-Peer Network][2]

[1]: https://github.com/bitcoin/bitcoin
[2]: https://eprint.iacr.org/2015/263.pdf
