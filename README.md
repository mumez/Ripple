# Ripple

A Pharo Smalltalk micro library for building WebSocket-based APIs easily — it's like "Teapot for WebSocket".

Ripple implements a publish/subscribe + request/reply event bus over WebSocket connections, sitting on top of [Teapot](https://github.com/zeroflag/teapot) and [Zinc](https://github.com/svenvc/zinc).

## Overview

Ripple lets you expose server-side Pharo objects to browser clients (or any WebSocket client) through a simple JSON message protocol. Each client identifies itself with a token and can:

- **request** messages to the server and receive a **reply** (correlated by UUID)
- **send** one-way events to the server (no reply)
- **publish** messages to a named address for broadcast delivery
- **register/unregister** subscriptions to addresses
- keep the connection alive with **ping/pong**

See [protocol.md](docs/protocol.md) for the full message protocol reference.

## Installation

Load Ripple into a running Pharo image via Metacello:

```smalltalk
Metacello new
    baseline: 'Ripple';
    repository: 'github://mumez/Ripple/src';
    load.
```

**Dependencies** (loaded automatically):
- [NeoJSON](https://github.com/svenvc/NeoJSON) — JSON serialization
- [Zinc WebSocket](https://github.com/svenvc/zinc) — WebSocket transport

## Quick Start

### 1. Start the server

```smalltalk
RpServer new start.
```

The server binds to `127.0.0.1:8080` by default.

### 2. Customize settings

```smalltalk
| server |
server := RpServer new.
server settings port: 9090.
server settings debugMode: true.
server settings assetsDir: '/path/to/my/assets'.
server start.
```

Settings are backed by environment variables and have sensible defaults:

| Setting | Env var | Default |
|---------|---------|---------|
| `port` | `PHARO_RIPPLE_PORT` | `8080` |
| `debugMode` | `PHARO_RIPPLE_DEBUG_MODE` | `false` |
| `bindAddress` | `PHARO_RIPPLE_BIND_ADDRESS` | `127.0.0.1` |
| `assetsDir` | `PHARO_RIPPLE_ASSETS_DIR` | `<cwd>/assets` |

### 3. Define a handler

Subclass `RpRipple` and override `handleRequest:` and/or `handleSend:`:

```smalltalk
RpRipple subclass: #MyEchoRipple
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'MyApp'.

MyEchoRipple class >> roomName [
    ^ '/ws/echo'
]

MyEchoRipple >> handleRequest: aMessage [
    self webSocket sendReply: aMessage body for: aMessage
]
```

### 4. Register the handler

```smalltalk
| server |
server := RpServer new.
server addRoomOf: MyEchoRipple.
server start.
```

### 5. Connect from the browser

```javascript
const bus = new Ripple('ws://localhost:8080/ws/echo?token=myToken');
bus.connect();

const reply = await bus.send('/greet', { name: 'World' });
console.log(reply);
```

A minimal vanilla-JS client (`Ripple.js`) is included in `test-assets/js/` for testing purposes.
A full client library will be published as a separate repository.

## Architecture

| Class | Role |
|-------|------|
| `RpServer` | HTTP server (Teapot wrapper); registers WebSocket routes |
| `RpWebSocketDelegate` | HTTP → WebSocket protocol upgrade |
| `RpWebSocketResponse` | Preserves original HTTP request through upgrade handshake |
| `RpWebSocket` | ZnWebSocket subclass; adds `sendReply:for:`, `sendPublish:to:`, `sendErrorFor:type:message:`, `sendPong` |
| `RpMessage` | Pure value object parsed from incoming JSON |
| `RpMessageDispatcher` | Routes messages to the correct handler method by type |
| `RpRipple` | Per-session application logic; subclass to implement your handler |

Handler class hierarchy:

```
RpWebSocketBaseHandler        Connection registry (token → RpRipple); mutex-protected
  └─ RpWebSocketEventBusHandler   Pub/sub routing (subscriptionDict); token auto-register on connect
          ·····>* RpRipple          Per-session instance (one per token); subclass per endpoint
```

## License

MIT
