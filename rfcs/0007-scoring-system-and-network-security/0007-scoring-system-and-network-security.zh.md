---
Number: 0007
Category: Informational
Status: Draft
Author: Jinyang Jiang
Organization: Nervos Foundation
Created: 2018-10-02
---

# P2P 评分系统和网络安全

## 简介

本篇 RFC 描述了 CKB P2P 网络层的评分系统，以及基于评分的网络安全策略。


## 目标

比特币网络[1]和以太坊网络[2]中曾有「日蚀攻击」的问题,
日蚀攻击的原理是攻击者通过操纵恶意节点占领受害者节点所有 Peers 的连接，以此控制受害者节点接受到的消息。
攻击者可以用极少成本实施攻击，完成双花, 分叉等等恶意行为。
参考论文 -- Eclipse Attacks on Bitcoin’s Peer-to-Peer Network

论文中同时提出了几种防范手段, 其中部分已经在比特币/以太坊主网应用，
本 RFC 参考比特币网络的实现，描述如何在 CKB 网络中正确应用这些措施。

RFC 同时描述了 CKB P2P 网络的评分机制，
结合 CKB 的评分机制，可以使用比特币中成熟的安全措施来处理更加通用的攻击场景。

基于 CKB 的评分机制，我们遵循几条规则来处理恶意 Peers：

1. 节点应尽可能的存储已知的 Peers 信息
2. 节点需要不断对 Peer 的好行为和坏行为进行评分
3. 节点应优先连接好的(分数高的) Peer，驱逐坏的(分数低) Peer

遵循这些规则不仅能够防范日蚀攻击，还可以防范更加通用的攻击场景。

RFC 描述了客户端应该实现的几种策略。


## Specification

### 术语

`Node` - 节点
`Peer` - 网络上的其他节点
`PeerStore` - 用于存储 Peer 信息的组件
`PeerInfo` - 保存在 Peer Store 中的信息
`Outbound Peer` - 连接由节点发起
`Inbound Peer` - 连接由 Peer 发起
`max_outgoing` - 节点主动连接的 Peers 上限
`max_incoming` - 节点被动接受的 Peers 上限


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

网络层应该提供评分接口，允许 `sync`, `relay` 等上层子协议报告 Peer 行为，
并根据 Peer 行为和 `SCORING_SCHEMA` 调整 Peer 的评分。

Peer 的评分是 CKB P2P 网络安全的重要部分，Peer 的行为可以分为如下三种：

1. 符合协议的行为:
  如: 从 Peer 获取了新的 Block、节点成功连接上 Peer 。
  当 Peer 作出符合协议的行为时，节点应上调对 Peer 评分，
但考虑恶意 Peer 有可能在攻击前进行伪装，
对好行为奖励的分数不应一次性奖励太多，
而是鼓励 Peer 长期进行好的行为来积累信用。

2. 可能由于网络异常导致的行为:
   如: Peer 异常断开、连接 Peer 失败、ping Timeout。
对这些行为我们采用宽容性的惩罚，下调对 Peer 的评分，但不会一次性下调太多。
3. 明显违反协议的行为:
   如: Peer 发送无法解码的内容、Peer 发送 Invalid Block, Peer 发送 Invalid Transaction。
当我们可以确定 Peer 存在明显的恶意行为时，对 Peer 打低分。

例子:
* Peer 1 连接成功，节点报告 Peer1 `CONNECTED` 行为，Peer 1 加 10 分
* Peer 2 连接超时，节点报告 Peer2 `TIMEOUT` 行为，Peer 2 减 10 分
* Peer 1 通过 `sync` 协议发送重复的请求，节点报告 Peer1 `DUPLICATED_REQUEST_BLOCK` 行为，Peer 1 减 50 分

`BEHAVIOURS` 和 `SCORING_SCHEMA` 不属于共识协议的一部分，CKB 实现应该根据网络实际的情况对这两个参数调整。


### 网络 Bootstrap 策略

论文中[1] 提到了比特币节点重启时的安全问题：

1. 攻击者事先利用比特币的节点发现规则填充受害节点的地址列表
2. 攻击者等待或诱发受害者节点重启
3. 受害节点重启时如果所有对外的连接都连接到了恶意 Peers 则攻击成功


在 CKB 节点启动时，节点利用 PeerStore 中存储的 Peer 分数和最后连接时间来避免该问题。

在初始化节点的网络时应该按照以下顺序尝试连接 Peers

1. 从 PeerStore 中挑选最后连接过的 `N` 个 Outbound Peer
2. 从中挑选分数最高的 `M` 个节点作为 Peers
3. 如果 Peers 数量小于 `outgoing_max`, 从 PeerStore 中随机挑选 `outgoing_max - M` 个 Inbound Peer 连接
4. 如果 Peers 数量小于 `outgoing_max`, 从 `boot_nodes` 配置列表中选择节点连接

按照该策略，最理想时可以从 PeerStore 的 Outbound PeerInfo 中找到足够的 Peers 用来主动连接，这种情况最为安全。而 Inbound Peer 有可能是恶意攻击者发起的伪装节点，所以只作为 fallback 使用。

### 逐出机制

比特币中当节点的被动 Peers 连满同时又有新 Peer 尝试连接时，节点会对已有 peers 进行逐出测试(详细请参考 bitcoin 源码[1])。

逐出测试的目的在于节点保留高质量 Peer 的同时，驱逐低质量的 Peer。

CKB 参考了比特币的逐出测试，步骤如下:

1. 对 `Inbound peers` 按照连接时的 address 进行分组，地址为IPv4 取 /16 Ipv6 取 /32 作为 `NetworkGroup`
2. 找到包含 Peers 数量最多的 `NetworkGroup`
3. 找到 group 中最低分
4. 和新 Peer 的分数对比，如果 Peer 分数较高，则在该 group 中随机驱逐一个最低分的节点，否则拒绝 Peer 连接

逐出测试使得恶意 Peer 必须伪装出比其他正常 Peer 更好的行为才会被接受。

### Feeler Connection

Feeler Connection 机制的目的在于：

* 测试 Peer 是否可以连接
* 发现更多的地址来填充 PeerStore

当节点的 Outbound peers 数量达到 `max_outgoing` 限制时，
节点会每隔一段时间(一般时几分钟)主动发起 feeler connection：

1. 从 PeerStore 中随机选出一个未连接的 Peer
2. 连接该 Peer
3. 执行节点发现协议
4. 断开连接

Feel Connection 选择 Peer 时应该从分数大于或略低于 `PEER_INIT_SCORE` 的 peers 中随机选择，feeler connection Peer 被假设为很快会 Disconnect

### PeerStore 清理

设置一些参数：
`PEER_STORE_LIMIT` - PeerStore 最多可以存储的 PeerInfo 数量
`PEER_NOT_SEEN_TIMEOUT` - 用于判断 PeerInfo 是否该被清晰，如该值设为 7 天，则表示最近 7 天内连接过的 Peer 不会被清理

PeerStore 中存储的 PeerInfo 数量达到 `PEER_STORE_LIMIT` 时需要清理，过程如下：

1. 找出包含最多节点的 `NetworkGroup`
2. 在 group 中搜索最近连接时间在 `PEER_NOT_SEEN_TIMEOUT` 之前的节点集合
3. 在该集合中分数最低的 PeerInfo 中随机删除一个
4. 如果上述步骤没有删除 PeerInfo 则不接受新增加的记录


## 参考

1. Bitcoin source code
2. Eclipse Attacks on Bitcoin’s Peer-to-Peer Network

