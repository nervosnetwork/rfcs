---
Number: 6
Category: Informational
Status: Draft
Author: Linfeng Qian / JinYang Jiang
Organization: Nervos Foundation
Created: 2018-11-28
---

# CKB 节点发现协议

CKB 节点发现协议主要参考了[比特币的协议][0]。不同点如下:
* 节点版本号包含在 `GetNodes` 消息中
* 我们使用 `multiaddr` 作为节点地址的格式 (没有 `/p2p/` 段，如果违反会被打低分)


## 节点发现的手段
### DNS 获取地址
第一次启动的时候，如果需要节点发现服务，客户端会尝试向内置的 DNS 服务器发送 DNS 请求来获取种子服务器地址。DNS 服务器地址可以通过命令行参数手工指定。

### 硬编码的「种子」地址
客户端会硬编码一些「种子」节点地址，这些地址只有在 DNS 获取地址失败的时候被使用。当通过这些种子节点获取了足够多的地址后需要断开这些链接，防止它们过载。「种子」节点地址列表可以通过命令行参数手工指定。

这些「种子」地址的时间戳被设置为 0 所以不会加入到 `GetNodes` 请求的返回值中。

### 协议消息

#### `GetNodes` 消息
当满足以下条件时，客户端会发送一个 `GetNodes` 请求：

  1. 这个连接是对方主动发起的 (防御[指纹攻击][3])
  2. 对方的版本号大于一个预设的值
  3. 当前存储的地址数量小于 1000 个

#### `Nodes` 消息

当客户端收到一个 `GetNodes` 请求时，满足一定条件下会返回一个 `Nodes` 消息。`Nodes` 消息也有可能被节点主动发出。`Nodes` 消息中的每个 `Node` 中的 `addresses` 的数量不能超过 `3` 个。

#### Nodes 转发
当客户端收到 `Nodes` 消息时，会将满足以下条件的地址转发给其他节点：

  1. 这个地址是最近 10 分钟内*被处理*的
  2. `Nodes` 包含的节点数(即 `Node`)不能超过 10 个
  3. 这个 `Nodes` 是之前 `GetNodes` 请求的返回值
  4. 这个地址是[可路由][1]的

上述所指的*地址*为之前 `Nodes` 消息中的地址。一个地址*被处理*, 是指一个地址被加入到已知地址列表中。

#### 广播自己的地址
客户端会每隔 24 小时将自己的地址通过 `Nodes` 消息广播给当前连接的所有节点。

## 流程图
![](images/node-discovery.png)

## 相关数据结构
我们使用 [FlatBuffers][2] 作为数据序列化格式，以下为相关数据结构的 schema:

```
table DiscoveryMessage {
    Payload: DiscoveryPayload;
}

union DiscoveryPayload {
    GetNodes,
    Nodes
}

table GetNodes {
    version: uint32;
    count: uint32;
}

table Nodes {
    infos: [Node];
}

table Node {
    node_id: Bytes;
    addresses: [Bytes];
}
```

[0]: https://en.bitcoin.it/wiki/Satoshi_Client_Node_Discovery
[1]: https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
[2]: https://google.github.io/flatbuffers/
[3]: https://arxiv.org/pdf/1410.6079.pdf
