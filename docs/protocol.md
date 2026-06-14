# Ripple WebSocket Protocol

All messages are UTF-8 encoded JSON objects transmitted over a single WebSocket connection. Every message must include a `type` field.

## Connection

Connect to a Ripple endpoint by opening a WebSocket with a `token` query parameter:

```
ws://host:port/ws/<path>?token=<your-token>
```

The token identifies the session. By default, any non-empty string is accepted. To enforce custom validation (e.g. JWT verification), override `validateToken:` on your `RpRippleRoom` subclass. The server responds with the WebSocket upgrade using the subprotocol header:

```
Sec-WebSocket-Protocol: ripple-st.0
```

On connect, the server automatically registers the token as a subscription address, enabling direct server-to-client delivery. On disconnect, the token address and all other subscriptions are cleaned up automatically.

## Message Format

All messages share the same JSON envelope:

```json
{
  "type": "request",
  "address": "user.login",
  "headers": { "locale": "en" },
  "body": { "username": "alice" },
  "correlationId": "550e8400-e29b-41d4-a716-446655440000"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Message type (required on all messages) |
| `address` | string | Target or reply address |
| `headers` | object | Application-defined metadata; not interpreted by the framework (optional) |
| `body` | any | Message payload (optional) |
| `correlationId` | string | UUID linking a `request` to its `reply` or `err` |

## Client → Server Messages

### `request` — Request/Reply

Send a message to an address and expect a `reply` back. The client generates a UUID for `correlationId`; the server echoes it in the response.

```json
{
  "type": "request",
  "address": "/greet",
  "body": { "name": "World" },
  "correlationId": "550e8400-e29b-41d4-a716-446655440000"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `address` | yes | Destination address |
| `correlationId` | yes | Client-generated UUID |
| `body` | no | Request payload |
| `headers` | no | Application metadata |

---

### `send` — One-Way Event

Send a message to the server with no reply expected.

```json
{
  "type": "send",
  "address": "/log",
  "body": { "text": "something happened" }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `address` | yes | Destination address |
| `body` | no | Payload |
| `headers` | no | Application metadata |

---

### `publish` — Broadcast

Publish a message to all subscribers of an address.

```json
{
  "type": "publish",
  "address": "/chat/room1",
  "body": { "text": "Hello!" }
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `address` | yes | Target address |
| `body` | yes | Payload |

---

### `register` — Subscribe

Subscribe to an address to receive `publish` messages sent to it.

```json
{
  "type": "register",
  "address": "/chat/room1"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `address` | yes | Address to subscribe to |

---

### `unregister` — Unsubscribe

Remove a subscription previously added with `register`.

```json
{
  "type": "unregister",
  "address": "/chat/room1"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `address` | yes | Address to unsubscribe from |

---

### `ping` — Keep-Alive

Send a ping to prevent the connection from timing out. The server responds with a `pong` JSON message.

```json
{ "type": "ping" }
```

## Server → Client Messages

### `reply` — Reply to a Request

Delivered to the originating socket in response to a `request` message.

```json
{
  "type": "reply",
  "address": "/greet",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "body": { "greeting": "Hello, World!" }
}
```

| Field | Description |
|-------|-------------|
| `address` | The address from the original `request` |
| `correlationId` | Echoed from the original `request` |
| `body` | Response payload |

---

### `send` — Server-Initiated One-Way Event

Sent directly to a client (via its token address) without a prior request. Internally implemented as a `publish` to the token's subscription address.

```json
{
  "type": "send",
  "address": "<token>",
  "body": { "event": "session-expired" }
}
```

---

### `publish` — Broadcast Delivery

Delivered to all clients registered to the address.

```json
{
  "type": "publish",
  "address": "/chat/room1",
  "body": { "text": "Hello!" }
}
```

| Field | Description |
|-------|-------------|
| `address` | The address the message was published to |
| `body` | Payload |

---

### `pong` — Keep-Alive Reply

Sent in response to a client `ping`.

```json
{ "type": "pong" }
```

---

### `err` — Error

Sent when a `request` or `send` cannot be handled.

```json
{
  "type": "err",
  "failureType": "NoSession",
  "failureCode": 404,
  "message": "Session not found",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000"
}
```

| Field | Description |
|-------|-------------|
| `failureType` | Machine-readable error category |
| `failureCode` | Numeric error code |
| `message` | Human-readable description |
| `correlationId` | Present only when the error originates from a `request` |

**Defined error types:**

| `failureType` | `failureCode` | Trigger |
|---------------|---------------|---------|
| `NoSession` | 404 | `send` or `request` arrived but no session (ripple) is registered for this connection |
| `Forbidden` | 403 | Client sent a `publish` message but `allowClientPublish` is `false` on the server |
| `HandlerError` | 500 | The application handler (`handleRequest:` or `handleSend:`) raised an unhandled exception |
| `general` | 0 | Generic server-side error with no specific category |
| `application` | ≥ 10000 | Application-level error explicitly raised by the handler; code is freely chosen by the application (10000 or above) |

> **Note:** Messages with an unknown or missing `type` are silently ignored on the server side (no `err` is sent; a warning is logged internally).

## Session Lifecycle

```
Client                          Server
  |                               |
  |-- WebSocket upgrade --------> |  token validated; RpRipple created
  |                               |  token auto-registered in subscriptionDict
  |                               |
  |-- { type: "register", ... }-> |  subscription recorded
  |                               |
  |-- { type: "request", ... } -> |  RpRipple>>handleRequest: called
  |<-- { type: "reply", ... } --  |  reply delivered with matching correlationId
  |                               |
  |-- { type: "send", ... } ----> |  RpRipple>>handleSend: called (no reply)
  |                               |
  |-- { type: "publish", ... } -> |  broadcast to all subscribers of address
  |<-- { type: "publish", ... }-- |  (if also subscribed)
  |                               |
  |-- { type: "ping" } ---------> |
  |<-- { type: "pong" } --------  |
  |                               |
  |-- close ----------------------|  RpRipple removed; all subscriptions cleaned up
```

