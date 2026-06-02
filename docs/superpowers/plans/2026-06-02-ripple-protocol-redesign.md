# Ripple Protocol Redesign — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the new Ripple WebSocket protocol (request/reply with correlationId, one-way send, ping/pong, token auto-registration) with `RpMessage` as a pure value object and `RpMessageDispatcher` as the dispatch strategy.

**Architecture:** `RpMessage` = pure value object (no socket ref). `RpMessageDispatcher` encapsulates routing logic. `RpWebSocket` gains `sendReply:for:` / `sendErrorFor:type:message:` / `sendPong`. `RpWebSocketEventBusHandler` becomes a thin lifecycle manager.

**Spec:** `docs/superpowers/specs/2026-06-02-ripple-protocol-redesign-design.md`

**Tech Stack:** Pharo Smalltalk, Tonel format, SUnit, NeoJSON

> **Tonel note:** Indentation in `.st` files uses **tabs**, not spaces.

---

## File Map

**Already done (Task 1):**
- `src/Ripple-Core-Tests/package.st` ✅
- `src/Ripple-Core-Tests/RpMockSocket.class.st` ✅

**Create:**
- `src/Ripple-Core/RpMessage.class.st`
- `src/Ripple-Core/RpMessageDispatcher.class.st`
- `src/Ripple-Core-Tests/RpMessageTest.class.st`
- `src/Ripple-Core-Tests/RpMessageDispatcherTest.class.st`

**Modify:**
- `src/Ripple-Core/RpWebSocket.class.st` — add `sendReply:for:`, `sendErrorFor:type:message:`, `sendPong`; remove `sendReply:to:` and `send:to:`
- `src/Ripple-Core/RpWebSocketEventBusHandler.class.st` — thin `dispatchMessage:with:`, add `register:`/`unregister:` overrides, remove `handlePublish:to:with:`
- `src/Ripple-Core/RpRipple.class.st` — update handler signatures to accept `RpMessage`

---

### Task 2: RpMessage — pure value object

**Files:**
- Create: `src/Ripple-Core/RpMessage.class.st`
- Create: `src/Ripple-Core-Tests/RpMessageTest.class.st`

- [ ] **Step 1: Write failing tests**

`src/Ripple-Core-Tests/RpMessageTest.class.st`:
```
Class {
	#name : #RpMessageTest,
	#superclass : #TestCase,
	#category : #'Ripple-Core-Tests'
}

{ #category : #tests }
RpMessageTest >> testParsesAllFields [
	| msg |
	msg := RpMessage
		fromJsonString: '{"type":"request","address":"user.login","headers":{"locale":"ja"},"body":{"user":"alice"},"correlationId":"abc-123"}'.
	self assert: msg type equals: 'request'.
	self assert: msg address equals: 'user.login'.
	self assert: msg correlationId equals: 'abc-123'.
	self assert: (msg body at: 'user') equals: 'alice'.
	self assert: (msg headers at: 'locale') equals: 'ja'
]

{ #category : #tests }
RpMessageTest >> testParsesMinimalMessage [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"ping"}'.
	self assert: msg type equals: 'ping'.
	self assert: msg address equals: ''.
	self assert: msg correlationId isNil.
	self assert: msg body isNil
]

{ #category : #tests }
RpMessageTest >> testMissingTypeReturnsNilType [
	| msg |
	msg := RpMessage fromJsonString: '{"address":"a"}'.
	self assert: msg type isNil
]

{ #category : #tests }
RpMessageTest >> testIsRequest [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"request","address":"a","correlationId":"c1"}'.
	self assert: msg isRequest.
	self deny: msg isSend
]

{ #category : #tests }
RpMessageTest >> testIsSend [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"send","address":"a"}'.
	self assert: msg isSend.
	self deny: msg isRequest
]

{ #category : #tests }
RpMessageTest >> testIsPing [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"ping"}'.
	self assert: msg isPing.
	self deny: msg isRequest
]

{ #category : #tests }
RpMessageTest >> testIsRegister [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"register","address":"topic.x"}'.
	self assert: msg isRegister.
	self deny: msg isUnregister
]

{ #category : #tests }
RpMessageTest >> testIsUnregister [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"unregister","address":"topic.x"}'.
	self assert: msg isUnregister.
	self deny: msg isRegister
]
```

- [ ] **Step 2: Import tests and verify they fail**

```
import_package: Ripple-Core-Tests, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageTest
```
Expected: errors because `RpMessage` does not exist yet.

- [ ] **Step 3: Implement RpMessage**

`src/Ripple-Core/RpMessage.class.st`:
```
Class {
	#name : #RpMessage,
	#superclass : #Object,
	#instVars : [
		'type',
		'address',
		'headers',
		'body',
		'correlationId'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpMessage class >> fromJsonString: jsonString [
	| json msg |
	json := NeoJSONReader fromString: jsonString asString.
	msg := self new.
	msg type: (json at: 'type' ifAbsent: [ nil ]).
	msg address: (json at: 'address' ifAbsent: [ '' ]).
	msg headers: (json at: 'headers' ifAbsent: [ Dictionary new ]).
	msg body: (json at: 'body' ifAbsent: [ nil ]).
	msg correlationId: (json at: 'correlationId' ifAbsent: [ nil ]).
	^ msg
]

{ #category : #accessing }
RpMessage >> address [
	^ address
]

{ #category : #accessing }
RpMessage >> address: anObject [
	address := anObject
]

{ #category : #accessing }
RpMessage >> body [
	^ body
]

{ #category : #accessing }
RpMessage >> body: anObject [
	body := anObject
]

{ #category : #accessing }
RpMessage >> correlationId [
	^ correlationId
]

{ #category : #accessing }
RpMessage >> correlationId: anObject [
	correlationId := anObject
]

{ #category : #accessing }
RpMessage >> headers [
	^ headers
]

{ #category : #accessing }
RpMessage >> headers: anObject [
	headers := anObject
]

{ #category : #testing }
RpMessage >> isPing [
	^ type = 'ping'
]

{ #category : #testing }
RpMessage >> isRegister [
	^ type = 'register'
]

{ #category : #testing }
RpMessage >> isRequest [
	^ type = 'request'
]

{ #category : #testing }
RpMessage >> isSend [
	^ type = 'send'
]

{ #category : #testing }
RpMessage >> isUnregister [
	^ type = 'unregister'
]

{ #category : #accessing }
RpMessage >> type [
	^ type
]

{ #category : #accessing }
RpMessage >> type: anObject [
	type := anObject
]
```

- [ ] **Step 4: Import both and run tests**

```
import_package: Ripple-Core, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
import_package: Ripple-Core-Tests, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageTest
```
Expected: 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/Ripple-Core/RpMessage.class.st src/Ripple-Core-Tests/RpMessageTest.class.st
git commit -m "feat: add RpMessage pure value object with JSON parsing"
```

---

### Task 3: RpWebSocket — new sending API

**Files:**
- Modify: `src/Ripple-Core/RpWebSocket.class.st`

These methods require a live ZnWebSocket to unit test directly; tested indirectly via `RpMessageDispatcherTest` in Task 5.

- [ ] **Step 1: Add new sending methods**

Add to `src/Ripple-Core/RpWebSocket.class.st`:

```
{ #category : #'sending events' }
RpWebSocket >> sendPong [
	self sendJson: (Dictionary new at: 'type' put: 'pong'; yourself)
]

{ #category : #'sending events' }
RpWebSocket >> sendReply: bodyDict for: aMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'reply'.
	jsonDict at: 'address' put: aMessage address.
	jsonDict at: 'correlationId' put: aMessage correlationId.
	jsonDict at: 'body' put: bodyDict.
	self sendJson: jsonDict
]

{ #category : #'sending events' }
RpWebSocket >> sendErrorFor: aMessage type: failureType message: errorMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'err'.
	jsonDict at: 'failureType' put: failureType.
	jsonDict at: 'failureCode' put: 0.
	jsonDict at: 'message' put: errorMessage.
	aMessage isRequest ifTrue: [ jsonDict at: 'correlationId' put: aMessage correlationId ].
	self sendJson: jsonDict
]
```

- [ ] **Step 2: Remove deprecated methods**

Delete these 2 method blocks from `src/Ripple-Core/RpWebSocket.class.st`:
- `send:to:` (alias for sendReply:to:)
- `sendReply:to:` (replaced by sendReply:for:)

- [ ] **Step 3: Add corresponding methods to RpMockSocket**

Add to `src/Ripple-Core-Tests/RpMockSocket.class.st`:

```
{ #category : #sending }
RpMockSocket >> sendReply: bodyDict for: aMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'reply'.
	jsonDict at: 'address' put: aMessage address.
	jsonDict at: 'correlationId' put: aMessage correlationId.
	jsonDict at: 'body' put: bodyDict.
	sentMessages add: jsonDict
]

{ #category : #sending }
RpMockSocket >> sendErrorFor: aMessage type: failureType message: errorMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'err'.
	jsonDict at: 'failureType' put: failureType.
	jsonDict at: 'failureCode' put: 0.
	jsonDict at: 'message' put: errorMessage.
	aMessage isRequest ifTrue: [ jsonDict at: 'correlationId' put: aMessage correlationId ].
	sentMessages add: jsonDict
]
```

- [ ] **Step 4: Import and verify existing tests still pass**

```
import_package: Ripple-Core, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
import_package: Ripple-Core-Tests, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageTest
```
Expected: 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/Ripple-Core/RpWebSocket.class.st src/Ripple-Core-Tests/RpMockSocket.class.st
git commit -m "feat: add RpWebSocket reply API (sendReply:for:, sendErrorFor:type:message:, sendPong)"
```

---

### Task 4: RpRipple — update handler signatures

**Files:**
- Modify: `src/Ripple-Core/RpRipple.class.st`

Must come before Task 5 because `RpMessageDispatcherTest` calls `ripple handleRequest: aMessage`.

- [ ] **Step 1: Rewrite RpRipple.class.st**

Replace entire file:

```
Class {
	#name : #RpRipple,
	#superclass : #Object,
	#instVars : [
		'webSocket'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpRipple class >> on: aWebSocket [
	^ self new
		webSocket: aWebSocket;
		yourself
]

{ #category : #'message handling' }
RpRipple >> handleRequest: aMessage [
	self webSocket sendReply: (Dictionary new
		at: 'timestamp' put: DateAndTime now asString;
		yourself) for: aMessage
]

{ #category : #'message handling' }
RpRipple >> handleSend: aMessage [
]

{ #category : #accessing }
RpRipple >> token [
	^ webSocket token
]

{ #category : #accessing }
RpRipple >> webSocket [
	^ webSocket
]

{ #category : #accessing }
RpRipple >> webSocket: anObject [
	webSocket := anObject
]
```

- [ ] **Step 2: Import and verify existing tests pass**

```
import_package: Ripple-Core, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageTest
```
Expected: 8 tests pass.

- [ ] **Step 3: Commit**

```bash
git add src/Ripple-Core/RpRipple.class.st
git commit -m "feat: update RpRipple handlers to accept RpMessage, use sendReply:for:"
```

---

### Task 5: RpMessageDispatcher — dispatch strategy

**Files:**
- Create: `src/Ripple-Core/RpMessageDispatcher.class.st`
- Create: `src/Ripple-Core-Tests/RpMessageDispatcherTest.class.st`
- Modify: `src/Ripple-Core/RpWebSocketEventBusHandler.class.st`

- [ ] **Step 1: Write failing tests**

`src/Ripple-Core-Tests/RpMessageDispatcherTest.class.st`:
```
Class {
	#name : #RpMessageDispatcherTest,
	#superclass : #TestCase,
	#instVars : [
		'handler',
		'mockSocket'
	],
	#category : #'Ripple-Core-Tests'
}

{ #category : #running }
RpMessageDispatcherTest >> setUp [
	handler := RpWebSocketEventBusHandler new.
	mockSocket := RpMockSocket new token: 'tok-1'.
	handler register: mockSocket
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchRequestSendsReply [
	| msg dispatcher |
	msg := RpMessage fromJsonString: '{"type":"request","address":"echo","correlationId":"cid-1","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: mockSocket handler: handler.
	dispatcher dispatch.
	self assert: mockSocket sentMessages isEmpty not.
	self assert: (mockSocket lastMessage at: 'type') equals: 'reply'.
	self assert: (mockSocket lastMessage at: 'correlationId') equals: 'cid-1'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendDoesNotSendReply [
	| msg dispatcher |
	msg := RpMessage fromJsonString: '{"type":"send","address":"notify","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: mockSocket handler: handler.
	dispatcher dispatch.
	self assert: (mockSocket sentMessages allSatisfy: [ :m | (m at: 'type') ~= 'reply' ])
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchPingSendsPong [
	| msg dispatcher |
	msg := RpMessage fromJsonString: '{"type":"ping"}'.
	dispatcher := RpMessageDispatcher message: msg socket: mockSocket handler: handler.
	dispatcher dispatch.
	self assert: mockSocket sentMessages isEmpty not.
	self assert: (mockSocket lastMessage at: 'type') equals: 'pong'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchUnknownTypeDoesNotCrash [
	| msg dispatcher |
	msg := RpMessage fromJsonString: '{"type":"bogus"}'.
	dispatcher := RpMessageDispatcher message: msg socket: mockSocket handler: handler.
	self shouldnt: [ dispatcher dispatch ] raise: Error
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchRegisterAddsSubscription [
	| msg dispatcher |
	msg := RpMessage fromJsonString: '{"type":"register","address":"topic.x"}'.
	dispatcher := RpMessageDispatcher message: msg socket: mockSocket handler: handler.
	dispatcher dispatch.
	self assert: ((handler subscriptionDict at: 'topic.x' ifAbsent: [ Set new ]) includes: mockSocket)
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchUnregisterRemovesSubscription [
	| reg unreg |
	reg := RpMessageDispatcher
		message: (RpMessage fromJsonString: '{"type":"register","address":"topic.x"}')
		socket: mockSocket
		handler: handler.
	unreg := RpMessageDispatcher
		message: (RpMessage fromJsonString: '{"type":"unregister","address":"topic.x"}')
		socket: mockSocket
		handler: handler.
	reg dispatch.
	unreg dispatch.
	self assert: ((handler subscriptionDict at: 'topic.x' ifAbsent: [ Set new ]) includes: mockSocket) not
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchRequestNoSessionSendsError [
	| unregisteredSocket msg dispatcher |
	unregisteredSocket := RpMockSocket new token: 'unknown-tok'.
	msg := RpMessage fromJsonString: '{"type":"request","address":"a","correlationId":"c1"}'.
	dispatcher := RpMessageDispatcher message: msg socket: unregisteredSocket handler: handler.
	dispatcher dispatch.
	self assert: (unregisteredSocket lastMessage at: 'type') equals: 'err'.
	self assert: (unregisteredSocket lastMessage at: 'failureType') equals: 'NoSession'
]
```

- [ ] **Step 2: Import and confirm tests fail**

```
import_package: Ripple-Core-Tests, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageDispatcherTest
```
Expected: failures because `RpMessageDispatcher` does not exist yet.

- [ ] **Step 3: Implement RpMessageDispatcher**

`src/Ripple-Core/RpMessageDispatcher.class.st`:
```
Class {
	#name : #RpMessageDispatcher,
	#superclass : #Object,
	#instVars : [
		'message',
		'originatorSocket',
		'handler'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpMessageDispatcher class >> message: aMessage socket: aWebSocket handler: aHandler [
	^ self new
		message: aMessage;
		originatorSocket: aWebSocket;
		handler: aHandler;
		yourself
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatch [
	message isRequest ifTrue: [ ^ self dispatchRequest ].
	message isSend ifTrue: [ ^ self dispatchSend ].
	message isRegister ifTrue: [ ^ self dispatchRegister ].
	message isUnregister ifTrue: [ ^ self dispatchUnregister ].
	message isPing ifTrue: [ ^ self dispatchPing ].
	handler logger warn: { handler className. #UnknownType. message type }
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchPing [
	originatorSocket sendPong
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchRegister [
	handler lock critical: [
		| subscribers |
		subscribers := handler subscriptionDict at: message address ifAbsentPut: [ Set new ].
		subscribers add: originatorSocket.
		(subscribers select: [ :each | each isConnected not ])
			do: [ :soc | subscribers remove: soc ifAbsent: [] ] ]
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchRequest [
	| ripple |
	ripple := handler rippleFor: originatorSocket.
	ripple isNil ifTrue: [
		originatorSocket sendErrorFor: message type: 'NoSession' message: 'Session not found'.
		^ self ].
	[ ripple handleRequest: message ]
		on: Error
		do: [ :ex |
			originatorSocket
				sendErrorFor: message
				type: 'HandlerError'
				message: ex messageText ]
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchSend [
	| ripple |
	ripple := handler rippleFor: originatorSocket.
	ripple isNil ifTrue: [
		originatorSocket sendErrorFor: message type: 'NoSession' message: 'Session not found'.
		^ self ].
	ripple handleSend: message
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchUnregister [
	handler lock critical: [
		| subscribers |
		subscribers := handler subscriptionDict at: message address ifAbsent: [ ^ self ].
		subscribers remove: originatorSocket ifAbsent: [].
		(subscribers select: [ :each | each isConnected not ])
			do: [ :soc | subscribers remove: soc ifAbsent: [] ] ]
]

{ #category : #accessing }
RpMessageDispatcher >> handler [
	^ handler
]

{ #category : #accessing }
RpMessageDispatcher >> handler: anObject [
	handler := anObject
]

{ #category : #accessing }
RpMessageDispatcher >> message [
	^ message
]

{ #category : #accessing }
RpMessageDispatcher >> message: anObject [
	message := anObject
]

{ #category : #accessing }
RpMessageDispatcher >> originatorSocket [
	^ originatorSocket
]

{ #category : #accessing }
RpMessageDispatcher >> originatorSocket: anObject [
	originatorSocket := anObject
]
```

- [ ] **Step 4: Update dispatchMessage:with: in RpWebSocketEventBusHandler**

Replace entire `src/Ripple-Core/RpWebSocketEventBusHandler.class.st`:

```
Class {
	#name : #RpWebSocketEventBusHandler,
	#superclass : #RpWebSocketBaseHandler,
	#instVars : [
		'subscriptionDict'
	],
	#category : #'Ripple-Core'
}

{ #category : #handling }
RpWebSocketEventBusHandler >> dispatchMessage: rawMessage with: webSocket [
	| msg |
	msg := RpMessage fromJsonString: rawMessage.
	msg type isNil ifTrue: [
		^ self logger warn: { self className. #NoMessageType. rawMessage } ].
	webSocket baseHandler: self.
	(RpMessageDispatcher message: msg socket: webSocket handler: self) dispatch
]

{ #category : #sending }
RpWebSocketEventBusHandler >> publishMessage: messageData to: address [
	| sockets |
	sockets := self subscriptionDict at: address ifAbsent: [ #() ].
	self publishMessage: messageData to: address with: sockets
]

{ #category : #sending }
RpWebSocketEventBusHandler >> publishMessage: messageData to: address with: sockets [
	lock critical: [
		sockets do: [ :each |
			[ each sendPublish: messageData to: address ]
				on: Error
				do: [ :exception |
					self logger warn: { self className. #WebSocketDistributeMessage. exception printString }.
					self unregister: each ] ] ]
]

{ #category : #accessing }
RpWebSocketEventBusHandler >> subscriptionDict [
	^ subscriptionDict ifNil: [ subscriptionDict := Dictionary new ]
]

{ #category : #accessing }
RpWebSocketEventBusHandler >> subscriptionDict: anObject [
	subscriptionDict := anObject
]
```

- [ ] **Step 5: Expose lock accessor in RpWebSocketBaseHandler**

`RpMessageDispatcher` が `handler lock` を呼ぶため、`RpWebSocketBaseHandler` に `lock` accessor を追加する（現在は protected instVar）:

Add to `src/Ripple-Core/RpWebSocketBaseHandler.class.st`:
```
{ #category : #accessing }
RpWebSocketBaseHandler >> lock [
	^ lock
]
```

- [ ] **Step 6: Import and run tests**

```
import_package: Ripple-Core, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
import_package: Ripple-Core-Tests, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageDispatcherTest
run_class_test: RpMessageTest
```
Expected: 7 + 8 = 15 tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/Ripple-Core/RpMessageDispatcher.class.st src/Ripple-Core/RpWebSocketEventBusHandler.class.st src/Ripple-Core/RpWebSocketBaseHandler.class.st src/Ripple-Core-Tests/RpMessageDispatcherTest.class.st
git commit -m "feat: add RpMessageDispatcher strategy, thin RpWebSocketEventBusHandler"
```

---

### Task 6: Token auto-registration on connect/disconnect

**Files:**
- Modify: `src/Ripple-Core/RpWebSocketEventBusHandler.class.st`
- Modify: `src/Ripple-Core-Tests/RpMessageDispatcherTest.class.st`

- [ ] **Step 1: Write failing tests**

Add to `src/Ripple-Core-Tests/RpMessageDispatcherTest.class.st`:

```
{ #category : #tests }
RpMessageDispatcherTest >> testRegisterAutoRegistersTokenAddress [
	"setUp already called handler register: mockSocket with token 'tok-1'"
	self assert: ((handler subscriptionDict at: 'tok-1' ifAbsent: [ Set new ]) includes: mockSocket)
]

{ #category : #tests }
RpMessageDispatcherTest >> testUnregisterRemovesTokenAddress [
	handler unregister: mockSocket.
	self assert: ((handler subscriptionDict at: 'tok-1' ifAbsent: [ Set new ]) includes: mockSocket) not
]

{ #category : #tests }
RpMessageDispatcherTest >> testServerCanSendToClientViaTokenAddress [
	| sent |
	handler publishMessage: (Dictionary new at: 'greeting' put: 'hello'; yourself) to: 'tok-1'.
	sent := mockSocket lastMessage.
	self assert: (sent at: 'type') equals: 'publish'.
	self assert: (sent at: 'address') equals: 'tok-1'.
	self assert: ((sent at: 'body') at: 'greeting') equals: 'hello'
]
```

- [ ] **Step 2: Import and confirm new tests fail**

```
import_package: Ripple-Core-Tests, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageDispatcherTest
```
Expected: 3 new tests fail. Existing 7 still pass.

- [ ] **Step 3: Add register:/unregister: overrides**

Add to `src/Ripple-Core/RpWebSocketEventBusHandler.class.st`:

```
{ #category : #registering }
RpWebSocketEventBusHandler >> register: clientWebSocket [
	super register: clientWebSocket.
	lock critical: [
		| token subscribers |
		token := clientWebSocket token.
		subscribers := self subscriptionDict at: token ifAbsentPut: [ Set new ].
		subscribers add: clientWebSocket ]
]

{ #category : #registering }
RpWebSocketEventBusHandler >> unregister: clientWebSocket [
	lock critical: [
		self subscriptionDict removeKey: clientWebSocket token ifAbsent: [] ].
	super unregister: clientWebSocket
]
```

- [ ] **Step 4: Import and run all tests**

```
import_package: Ripple-Core, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
import_package: Ripple-Core-Tests, path: /Volumes/SSPJ-UTC/git.ssd/Ripple/src
run_class_test: RpMessageDispatcherTest
run_class_test: RpMessageTest
```
Expected: 10 + 8 = 18 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/Ripple-Core/RpWebSocketEventBusHandler.class.st src/Ripple-Core-Tests/RpMessageDispatcherTest.class.st
git commit -m "feat: auto-register client token as pub/sub address on WebSocket connect"
```

---

### Task 7: Integration check

**Files:** none

- [ ] **Step 1: Start the server in Pharo**

```smalltalk
RpServer new start.
```

- [ ] **Step 2: Open the test UI**

Open `tmp-assets/index.html` in a browser (`http://localhost:8080`).

- [ ] **Step 3: Verify each protocol message type**

| Scenario | Expected |
|----------|----------|
| Page loads, ping fires | `pong` received in console |
| Send a `request` with correlationId | `reply` received with same correlationId |
| Send a one-way `send` | No `reply` received |
| `register` topic, then server-side `publishMessage:to:` | `publish` received on client |
| Close tab and reconnect | No leftover subscriptions from previous session |

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "feat: Ripple Phase 1 protocol redesign complete"
```
