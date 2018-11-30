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
* 节点版本号包含在 `GetNodeInfos` 消息中
* 我们使用 `multiaddr` 作为节点地址的格式


## 节点发现的手段
### DNS 获取地址
第一次启动的时候，如果需要节点发现服务，客户端会尝试向内置的 DNS 服务器发送 DNS 请求来获取种子服务器地址。

### 硬编码的"种子"地址
客户端会硬编码一些"种子"节点地址，这些地址只有在 DNS 获取地址失败的时候被使用。当通过这些种子节点获取了足够多的地址后需要断开这些链接，防止它们过载。

这些"种子"地址也的时间戳被甚至为 0 所以不会加入到 `GetNodeInfos` 请求的返回值中。

### 协议消息

#### `GetNodeInfos` 消息
当满足一定条件时，客户端会发送一个 `GetNodeInfos` 请求：

  1. 这个连接是对方主动发起的
  2. 对方的版本号大于一个预设的值
  3. 当前存储的地址数量小于 1000 个

#### `NodeInfos` 消息

当客户端收到一个 `GetNodeInfos` 请求时，满足一定条件下会返回一个 `NodeInfos` 消息。`NodeInfos` 消息也有可能被节点主动发出。

#### NodeInfos 转发
当客户端收到 NodeInfos 消息时，会将满足某些条件的地址转发给其他节点：

  1. 这个地址是不大于 10 分钟之前被处理的
  2. `NodeInfos` 包含的地址数不能超过 10 个
  3. 这个 `NodeInfos` 是之前 `GetNodeInfos` 请求的返回值
  4. 这个地址是[可路由][1]的


#### 广播自己的地址
客户端会每隔 24 小时将自己的地址通过 `NodeInfos` 消息广播给当前连接的所有节点。

## 流程图
![flow diagram](Discovery.png)

## 相关数据结构
我们使用 [FlatBuffers][2] 作为数据序列化格式，以下为相关数据结构的 schema:

```
table DiscoveryMessage {
    Payload: DiscoveryPayload;
}

union DiscoveryPayload {
    GetNodeInfos,
    NodeInfos
}

table GetNodeInfos {
    version: uint32;
    count: uint32;
}

table NodeInfos {
    infos: [NodeInfo];
}

table NodeInfo {
    node_key: Bytes;
    addresses: [Bytes];
}
```

[0]: https://en.bitcoin.it/wiki/Satoshi_Client_Node_Discovery
[1]: https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
[2]: https://google.github.io/flatbuffers/
