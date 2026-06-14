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

After loading the package, `RpServer` registers itself with Pharo's `SessionManager` and starts automatically on each image startup — no explicit call is normally needed.

To start manually:

```smalltalk
RpServer default start.
```

The server binds to `127.0.0.1:8080` by default.

### 2. Customize settings

Ripple uses two settings objects:

- **`RpServerSettings`** — accessed via `server settings`; controls the HTTP/WebSocket server itself.
- **`RpRoomSettings`** — accessed via a handler's `settings`; controls per-room behaviour.

#### Server settings

```smalltalk
| server |
server := RpServer default.
server settings port: 9090.
server settings debugMode: true.
server settings assetsDir: '/path/to/my/assets'.
server start.
```

Server settings are backed by environment variables and have sensible defaults:

| Setting | Env var | Default |
|---------|---------|---------|
| `port` | `PHARO_RIPPLE_PORT` | `8080` |
| `debugMode` | `PHARO_RIPPLE_DEBUG_MODE` | `false` |
| `bindAddress` | `PHARO_RIPPLE_BIND_ADDRESS` | `127.0.0.1` |
| `assetsDir` | `PHARO_RIPPLE_ASSETS_DIR` | `<cwd>/assets` |

#### Room settings

Each room's handler exposes `RpRoomSettings` via its `settings` accessor:

| Setting | Default | Description |
|---------|---------|-------------|
| `allowClientPublish` | `false` | Allow clients to publish to arbitrary addresses |
| `maxErrorCount` | `5` | Network errors before a session is auto-unregistered |

Configure room settings by overriding `roomSettings` on your `RpRipple` subclass:

```smalltalk
MyRipple class >> roomSettings [
    ^ super roomSettings allowClientPublish: true; yourself
]
```

### 3. Define a handler

Subclass `RpRipple` and override `handleRequest:` and/or `handleSend:`:

```smalltalk
RpRipple subclass: #MyEchoRipple
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'MyApp'.

MyEchoRipple class >> roomName [
    ^ 'echo'
]

MyEchoRipple >> handleRequest: aMessage [
    self webSocket sendReply: aMessage body for: aMessage
]
```

### 4. Register the handler

Routes are registered **automatically** on image startup. When the image starts, `RpRipple autoPutAllRoutesToDefaultServer` is called and every `RpRipple` subclass whose `shouldAutoPutRoute` returns `true` (the default) is added to `RpServer default`.

No extra code is required for the common case. If you need to register a route manually — e.g. during a live session before restarting — you can still do so explicitly:

```smalltalk
MyEchoRipple putRouteToDefaultServer.

"Or to a specific server instance:"
MyEchoRipple putRouteTo: myServer.
```

To exclude a subclass from auto-registration (useful for test helpers), override `shouldAutoPutRoute`:

```smalltalk
MyEchoRipple class >> shouldAutoPutRoute [
    ^ false
]
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
| `RpWebSocket` | ZnWebSocket subclass; adds `sendReply:for:`, `sendPublish:to:`, `sendError:for:`, `sendPong`, `send:to:` |
| `RpMessage` | Pure value object parsed from incoming JSON |
| `RpMessageDispatcher` | Routes messages to the correct handler method by type |
| `RpRippleRoom` | Binds a URL path, ripple class, and event bus handler into a deployable unit |
| `RpRipple` | Per-session application logic; subclass to implement your handler |
| `RpError` | Typed error value object; serialises to JSON error frames |
| `RpLocalLogger` | Simple levelled logger (error/warn/debug) writing to Transcript |

Handler class hierarchy:

```
RpWebSocketBaseHandler        Connection registry (token → RpRipple); mutex-protected
  └─ RpWebSocketEventBusHandler   Pub/sub routing (subscriptionDict); token auto-register on connect
          ·····>* RpRippleRoom       Room config (name, rippleClass, settings); owns the handler
                    ·····>* RpRipple   Per-session instance (one per token); subclass per endpoint
```

## Integration Testing

The `Ripple-Core-Tests` package includes a ready-made test handler (`RpTestRipple`) and a browser-based UI (`test-assets/`) that exercises send, request, server publish, and client publish against a live server.

The test UI uses [ripple-st-client](https://github.com/mumez/ripple-st-client) — the official npm package for the Ripple protocol.

### 1. Build the client library

Install the npm package and copy its built output into `test-assets/js/`:

```bash
npm install
npm run build
```

`npm run build` copies `node_modules/ripple-st-client/dist/index.js` to `test-assets/js/ripple-st-client.js`. Re-run it whenever you update the package version.

### 2. Make the test UI accessible

`RpServer` serves static files from the `assets/` directory relative to the Pharo image. Copy or symlink `test-assets/` as `assets/` next to your image:

```bash
# symlink (recommended)
ln -s /path/to/Ripple/test-assets /path/to/pharo-image-dir/assets

# or copy
cp -r /path/to/Ripple/test-assets /path/to/pharo-image-dir/assets
```

### 3. Start the server with the test route

`addTestRoute` is provided by `Ripple-Core-Tests` and must be called explicitly — it is not registered by default.

```smalltalk
| server |
server := RpServer default.
server addTestRoute.
server start.
```

### 4. Open the test UI

Open `http://localhost:8080/assets/index.html` in one or more browser tabs.

Each tab connects with a unique session token and can independently trigger:

- **Send** — sends a message to the server; the server echoes it back with the session token
- **Request** — sends a request; the server replies with the session token
- **Start / Stop server publish** — the server broadcasts to all subscribed tabs every 2 seconds (one shared process regardless of how many tabs started it)
- **Publish from client** — requires `allowClientPublish: true` on the room's handler settings (enabled by default in `RpTestRipple`)

## License

MIT
