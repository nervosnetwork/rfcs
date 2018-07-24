# 链同步协议

术语说明

- Chain: 以创世块开头的，由连续的块组成的链表。
- Best Chain: 节点之间要达成最终一致的，满足共识验证条件的，PoW 累积工作量最高的，以共识的创世块开始的 Chain。
- Tip: Chain 最后一个块。Tip 可以唯一确定 Chain。
- Best Chain Tip: Best Chain 的最后一个块。

## 同步概览

块同步分阶段进行，采用 [Bitcoin Headers First](https://bitcoin.org/en/glossary/headers-first-sync) 的方式。

1. 连接块头 (Connect Header): 获得并验证块头，格式正确且 PoW 有效
2. 下载块 (Download Block): 获得并验证完整的块。这里的验证不包含需要链上下文的验证。
3. 采用块 (Accept Block): 在链上下文中验证块。

分阶段执行的主要目的是先用比较小的代价排除最大作恶的可能行。举例来说，第一步连接块头是在整个同步中的工作量可能只有 5%，但是完成后能有 95% 的可信度认为同步成功的块都是有效的。

按照已经执行的阶段，块可以处于以下 5 种状态：

1. Unknown: 在连接块头执行之前，块的状态是未知的。
  2. Invalid：任意一步中失败。当一个块标记为 Invalid，它的所有子孙节点也都标记为 Invalid。
3. Connected: 连接块头成功，且该块到创世块的所有祖先块都必须是 Connected, Downloaded 或 Accepted 的状态。
4. Downloaded: 下载块成功，且该块到创世块的所有祖先块都必须是 Downloaded 或者 Accepted 的状态。
 6. Accepted:  采用块成功，且该块到创世块的所有祖先块都必须是 Accepted 的状态。

块的状态是会沿着依赖传递的。按照上面的编号，子块的状态编号一定不会大于父块的状态编号。首先某个快是无效的，那依赖它的子孙快自然也是无效的。另外同步的每一步代价都远远高于前一步，且每一步都可能失败。如果子节点先于父节点进入下一阶段，而父节点被验证为无效，那子节点上的工作量就浪费了。而且子快验证是要依赖父块的信息的。

初始时创世块状态为 Accepted，其它所有块为 Unknown。

之后会使用以下图示表示不同状态的块：

![](../images/block-status.jpg "Block Status")

因为创世块必须相同，所有的块必然是组成由创世块为根的一颗树，如果块无法最终连接到创世块都可以丢弃不做处理。

参与同步的所有节点都会在本地构造这颗状态树，其中全部由 Accepted 块组成的工作量最大的链就是 Best Chain。

下图是节点 Alice 构建的状态树的示例，其中标记为 Alice 的块是该节点当前的 Best Chain Tip。

![](../images/status-tree.jpg "Status Tree by Alice")

## 连接块头

先同步 Headers 可以用最小的代价验证 PoW 有效。构造 PoW 但是放入无效的交易和放入有效的交易需要付出相同的代价，攻击者可以用其它更高性价比的方式进行攻击。所以可以认为当 PoW 有效时，整个块是有效的概率非常高。所以先同步 Headers 能避免浪费资源去下载和验证无效块。

因为代价小，同步 Headers 可以和所有的节点同时进行，在本地能构建出可信度非常高的，当前网络中所有分叉的全局图。这样可以对块下载进行规划，避免浪费资源在工作量低的分支上。

连接块头这一步的目标是，当节点 Alice 连接到节点 Bob 之后，Alice 让 Bob 发送所有在 Bob 的 Best Chain 上，但是不在 Alice 的 Best Chain 上的块头，进行验证并确定这些块的状态是 Connected 还是 Invalid。

![](../images/seq-connect-headers.jpg)

上图是一轮连接块头的流程。节点应该定时和连接节点进行一轮同步。如果收到对方节点的新块通知，块在本地状态是 Unknown，应该立即开始一轮同步。

以上图 Alice 从 Bob 同步为例，首先 Alice 将自己 Best Chain 中的块进行采样，将选中块的哈希作为消息内容发给 Bob。采样的基本原则是最近的块采样越密，越早的块越稀疏。比如可以取最后的 10 个块，然后从倒数第十个块开始按 2, 4, 8, … 等以 2 的指数增长的步长进行取样。下图中淡色处理的是没有被采样的块，一般创世块都会放到 Locator 当中。

![](../images/locator.jpg)

Bob 根据 Locator 和自己的 Best Chain 可以找出两条链的最后一个共同块。因为创世块相同，所以一定存在这样一个块。Bob 把共同块之后一个开始到 Best Chain Tip 为止的所有块头发给 Alice。

![](../images/connect-header-conditions.jpg)

上图中未淡出的块是 Bob 要发送给 Alice 的块头，金色高亮边框的是最后共同块。其中列举了同步会碰到的三种情况：

1. Bob 的 Best Chain Tip 在 Alice 的 Best Chain 中，最后共同块就是 Bob 的 Best Chain Tip，Bob 没有块头可以发送。
2. Alice 的 Best Chain Tip 在 Bob 的 Best Chain 中并且不等于 Tip，最后共同块就是 Alice 的 Best Chain Tip。
3. Alice 和 Bob 出现了分叉，最后共同块是发生发叉前的块。

如果要发送的块很多，需要做分页处理。Bob 先发送第一页，Alice 通过返回结果发现还有更多的块头就继续向 Bob 请求接下来的页。一个简单的分页方案是限制每次返回块头的最大数量，比如 2000。如果返回块头数量等于 2000，说明可能还有块可以返回，就接着请求之后的块头。

在同步的同时，Alice 可以观察到 Bob 当前的 Best Chain Tip，即在每轮同步是最后收到的块。在连接块头时可能会出现以下一些异常情况：

- Alice 观察到的 Bob Best Chain Tip 很长一段时间没有更新。因为只有 Bob 能提供 Alice 没有的块头才会发送，说明 Bob 很长一段时间都无法提供有同步价值的块，Alice 可以停止和 Bob 的同步。
- Alice 观察到的 Bob Best Chain Tip 很老，比如在 1 天前。这种情况一般是 Alice 和 Bob 出现了分叉。因为 Bob 并没有最新的块，Alice 可以停止和 Bob 的同步。
- Alice 观察到的 Bob Best Chain Tip 状态是 Invalid。这个判断不需要等到一轮 Connect Head 结束，任何一个分页发现有 Invalid 的块就可以停止接受剩下的分页了。因为 Bob 在一个无效的分支上，Alice 可以停止和 Bob 的同步，并将 Bob 加入到黑名单中。
- Alice 收到块头全部都在自己的 Best Chain 上，这有两种可能，一是 Bob 故意发送，二是 Alice 在 Connect Head 时 Best Chain 发生了变化，由于无法区分只能忽略，但是可以统计发送的块已经在本地 Best Chain 上的比例，高于一定阈值可以将对方加入到黑明单中。

在收到块头消息时可以先做以下格式验证。

- 消息中的块是连续的
- 所有块和第一个块的父块在本地状态树中的状态不是 Invalid
- 第一个块的父块在本地状态树中的状态不是 Unknown，即同步时不处理 Orphan Block。

然后验证块头满足共识规则，PoW 是有效的。因为不处理 Orphan Block，难度调整也可以在这里进行验证。

![](../images/connect-header-status.jpg)

上图是 Alice 和 Bob, Charlie, Davis, Elsa 等节点同步后的状态树情况和观测到的其它节点的 Best Chain Tip。

如果认为 Unknown 状态块是不在状态树上的话，在连接块头阶段，会在状态树的末端新增一些 Connected 或者 Invalid 状态的节点。所以可以把连接块头看作是拓展状态树，探路的阶段。

## 下载块

完成连接块头后，一些观测到的邻居节点的 Best Chain Tip 在状态树上的分支是以一个或者多个 Connected 块结尾的，即 Connected Chain，这时可以进入下载块流程，向邻居节点请求完整的块，进行除链上下文无关的验证。

因为有了状态树，可以对同步进行规划，避免做无用工作。一个有效的优化就是只有当观测到的邻居节点的 Best Chain 的累积工作量大于本地的 Best Chain 的累积工作量才进行下载块。而且可以按照 Connected Chain 累积工作量为优先级排序，优先下载累积工作量更高的分支，只有被验证为 Invalid 或者因为下载超时无法进行时才去下载优先级较低的分支。

下载某个分支时，因为块的依赖性，应该优先下载更早的块；同时应该并发从不同的节点去并发下载，充分利用带宽。可以使用滑动窗口解决。

假设分支第一个要下载的 Connected 状态块号时 M，滑动窗口长度是 N，那么只去下载 M 到 M + N - 1 这 N 个块。在块 M 下载并验证后，窗口往右移动到下一个 Connected 状态的块。如果块 M 验证失败，则分支剩余的块也就都是 Invalid 状态，不需要继续下载。如果窗口长时间没有向右移动，则可以判定为下载超时，可以尝试其它分支之后再进行尝试，或者该分支上有新增的 Connected 块时再尝试。

![](../images/sliding-window.jpg)

上图是一个长度为 8 的滑动窗口的例子。开始时可下载的块是从 3 到 10。块 3 下载后，因为 4 已经先下载好了，所以窗口直接滑动到从 5 开始。

因为通过连接块头已经观测到了邻居节点的 Best Chain，如果在对方 Best Chain 中且对方是一个全节点，可以认为对方是能够提供块的下载的。在下载的时候可以把滑动窗口中的块分成小块的任务加到任务队列中，在能提供下载的节点之间进行任务调度。

下载块可能会出现交易对不上 Merkle Hash Root 的情况，或者能对上但是有重复的交易 txid。这些情况并不能说明块是无效，只是没有下载到正确的块内容。可以将对方加入黑名单，但是不能标记块的状态为 Invalid。

在这一阶段可以进行除了链上下文无关的其它所有验证。链上下文相关的验证就是需要使用到祖先块中的信息才能进行的验证，包括任何需要交易 input 具体内容的验证，比如交易手续费，双花等。不进行链上下文相关验证保证了下载的兵法性。

可以进行的验证比如 Merkel Hash 验证，交易 txid 不能重复，交易列表不能为空，所有交易不能 inputs outputs 同时为空，只有第一个交易可以是 generation transaction 等等。

下载块会把状态树中工作量更高的 Connected Chain 中的 Connected 块变成 Downloaded 或者 Invalid。

## 采用块

在上一阶段中会产生一些以一个或多个 Downloaded 状态的块结尾的链，以下简称为 Downloaded Chain。如果这些链的累积工作量大于 Best Chain Tip 就可以进行该阶段完整的验证链的合法性。如果有多个这样的链，选取累积工作量最高的。

因为涉及到 UTXO (未消耗掉的交易 outputs) 的索引，这一步的验证开销是非常大的。为了简化系统，可以只保留一套 UTXO 索引，尝试将本地的 Best Chain Tip 进行必要回退然后将 Downloaded Chain 上的块一次验证然后添加到 Best Chain 上。如果中间有块验证失败则 Downloaded Chain 上剩余的块也就都是 Invalid 状态不需要再继续。这时 Best Chain Tip 甚至会低于之前的 Tip，可以采取以下的方案处理：

- 如果回退之前的 Best Chain 工作量比当前 Tip 更高，恢复之前的 Best Chain
- 如果有其它 Downloaded Chain 比回退之前的 Best Chain 工作量更高，可以继续使用下一个 Downloaded Chain 进行采用块的步骤。

采用块会将工作量更高的 Downloaded Chain 中的 Downloaded 状态块变成 Accepted 或者 Invalid，而累积工作量最高的 Downloaded Chain 应该成为本地的 Best Chain。

## 新块通知

当节点的 Best Chain Tip 发生变化时，应该通过 push 的方式主动去通知邻居节点。为了避免通知重复的块，和尽量一次性发送邻居节点没有的块，可以在每次发送新块通知，已经在同步时每次回复块头信息时记录下最后一个发送给对方的块是什么。当 Best Chain Tip 发生变化时，只用通知上次发送的块和 Best Chain Tip 的最后共同块开始 (不含) 到 Best Chain Tip (含) 的块。根据要同通知块的数量的不同，使用不同的通知机制：

- 数量为 1 且对方偏好使用 Compact Block，则使用 Compact Block
- 其它情况直接发送块头列表，但要限制发送块的数量不超过某个阈值，比如 8，如果有 8 个或更多的块要通知，只通知最新的 7 个块。

当收到新块通知时，会出现父块状态时 Unknown 的情况，即 Orphan Block，这个时候需要立即做一轮连接块头的同步。收到 Compact Block 且父块就是本地的 Best Chain Tip 的时候可以尝试用交易池直接恢复，如果恢复成功，直接可以将三阶段的工作合并进行，否则就当作收到的只是块头。

## 同步配置

- `GENESIS_HASH`: 创世块哈希
- `MAX_HEADERS_RESULTS`: 一条消息里可以发送块头的最大数量
- `MAX_BLOCKS_TO_ANNOUNCE`: 新块通知数量不可超过该阈值
- `BLOCK_DOWNLOAD_WINDOW`: 下载滑动窗口大小


## 消息定义

具体消息定义见参考实现，这里只列出同步涉及到的消息和必要的一些字段和描述。

Compact Block 需要使用到的消息 `cmpctblock` 和 `getblocktxn` 会在 Compact Block 相关文档中说明。

### getheaders

用于连接块头时向邻居节点请求块头。请求第一页，和收到后续页使用相同的 getheaders 消息，区别是第一页是给本地的 Best Chain Tip 生成 locator，而后续页是使用上一页的最后一个块生成 locator。

- `locator`: 对 Chain 上块采用，得到的哈希列表

### headers

用于回复 `getheaders` 和通知新块，处理逻辑没有区别，只是当块头数量小于 `MAX_BLOCKS_TO_ANNOUNCE` 时如果发现有 Orphan Block，因为可能是新块通知，所以需要做一次连接块同步。收到 `headers` 如果块头数量等于 `MAX_HEADERS_RESULTS` 表示还有更多的块需要请求。

- `headers`：块头列表

### getdata

用于下载块阶段

- `inventory`: 要下载对象列表，每个成员包含字段
	- `type`: 下载对象的类型，这里只用到块
	- `hash`: 使用对象哈希做标识符

### block

回复 `getdata` 的块下载请求

- `header` 块头
- `transactions` 交易列表


