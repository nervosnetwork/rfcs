---
Number: 0008
Category: Standards Track
Status: Draft
Author: Ian Yang
Organization: Nervos Foundation
Created: 2018-12-17
---

# Serialization

CKB use two major serialization format, CFB and JSON.

[CFB][cfb] (Canonical FlatBuffers) is a restricted variant of FlatBuffers for producing unequivocal transfer syntax. Since CFB generated binary is still valid FlatBuffers, any FlatBuffers reader can parse the serialized messages, but only CFB builder can serialize messages into valid binary.

CFB is in the proposal stage, and is not ready yet. Now plain FlatBuffers is
used to serialize P2P messages.

[JSON][json] is used in node RPC service via [JSON-RPC][jsonrpc].

[cfb]: https://github.com/nervosnetwork/rfcs/pull/47
[json]: https://www.json.org
[jsonrpc]: https://www.jsonrpc.org/specification
