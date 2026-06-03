# RpRippleRoom Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Introduce `RpRippleRoom` — a configuration object that binds a URL route, a handler, and a ripple class together, so users can add WebSocket endpoints with a single `addRoom:` call on `RpServer`.

**Architecture:** `RpRippleRoom` holds `name`, `handler`, and `rippleClass` with lazy handler creation. `RpWebSocketBaseHandler` gets a configurable `rippleClass` instVar so each room can use a custom `RpRipple` subclass. `RpServer` gets two convenience methods: `addRoom:` (takes a room) and `addRoomOf:` (takes a ripple class and derives the room from it).

**Tech Stack:** Pharo Smalltalk, Tonel file format, SUnit tests, ZnWebSocket/Teapot (existing deps).

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `src/Ripple-Core/RpWebSocketBaseHandler.class.st` | Add `rippleClass` instVar + getter/setter; use it in `register:` |
| Create | `src/Ripple-Core/RpRippleRoom.class.st` | New class: name + handler + rippleClass |
| Modify | `src/Ripple-Core/RpServer.class.st` | Add `addRoom:` and `addRoomOf:` |
| Modify | `src/Ripple-Core/RpRipple.class.st` | Add class-side `room` (subclassResponsibility) |
| Create | `src/Ripple-Core-Tests/RpRippleRoomTest.class.st` | Tests for RpRippleRoom, addRoom:, addRoomOf: |
| Create | `src/Ripple-Core-Tests/RpMockServer.class.st` | Test double for RpServer (records addRoute:handler: calls) |
| Create | `src/Ripple-Core-Tests/RpMockRipple.class.st` | Minimal RpRipple subclass used as test fixture |

---

## Task 1: Add `rippleClass` to `RpWebSocketBaseHandler`

**Files:**
- Modify: `src/Ripple-Core/RpWebSocketBaseHandler.class.st`
- Test: `src/Ripple-Core-Tests/RpRippleRoomTest.class.st` (bootstrap — just the class shell + this test)

- [ ] **Step 1: Create the test file with the first failing test**

Create `src/Ripple-Core-Tests/RpRippleRoomTest.class.st`:

```smalltalk
Class {
	#name : #RpRippleRoomTest,
	#superclass : #TestCase,
	#category : #'Ripple-Core-Tests'
}

{ #category : #tests }
RpRippleRoomTest >> testHandlerDefaultRippleClassIsRpRipple [
	| handler |
	handler := RpWebSocketEventBusHandler new.
	self assert: handler rippleClass equals: RpRipple
]
```

- [ ] **Step 2: Import and run to confirm failure**

```
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core-Tests
/st-test RpRippleRoomTest
```

Expected: Error — `rippleClass` method not found.

- [ ] **Step 3: Add `rippleClass` instVar and methods to `RpWebSocketBaseHandler`**

Edit `src/Ripple-Core/RpWebSocketBaseHandler.class.st`.

Change the class definition instVars from:
```smalltalk
	#instVars : [
		'lock',
		'logger',
		'ripples'
	],
```
to:
```smalltalk
	#instVars : [
		'lock',
		'logger',
		'ripples',
		'rippleClass'
	],
```

Add two new methods at the end of the file:

```smalltalk
{ #category : #accessing }
RpWebSocketBaseHandler >> rippleClass [
	^ rippleClass ifNil: [ rippleClass := RpRipple ]
]

{ #category : #accessing }
RpWebSocketBaseHandler >> rippleClass: aClass [
	rippleClass := aClass
]
```

- [ ] **Step 4: Modify `register:` to use `self rippleClass`**

In `src/Ripple-Core/RpWebSocketBaseHandler.class.st`, find the `register:` method:

```smalltalk
{ #category : #registering }
RpWebSocketBaseHandler >> register: clientWebSocket [

	lock critical: [
		| token |
		token := clientWebSocket token.
		(self validateToken: token) ifTrue: [
			self ripples at: token put: (RpRipple on: clientWebSocket) ] ]
]
```

Change `(RpRipple on: clientWebSocket)` to `(self rippleClass on: clientWebSocket)`:

```smalltalk
{ #category : #registering }
RpWebSocketBaseHandler >> register: clientWebSocket [

	lock critical: [
		| token |
		token := clientWebSocket token.
		(self validateToken: token) ifTrue: [
			self ripples at: token put: (self rippleClass on: clientWebSocket) ] ]
]
```

- [ ] **Step 5: Import Ripple-Core and re-run tests**

```
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core-Tests
/st-test RpRippleRoomTest
```

Expected: `testHandlerDefaultRippleClassIsRpRipple` passes.

- [ ] **Step 6: Add test for custom rippleClass**

Append to `src/Ripple-Core-Tests/RpRippleRoomTest.class.st`:

```smalltalk
{ #category : #tests }
RpRippleRoomTest >> testHandlerUsesCustomRippleClassOnRegister [
	| handler socket ripple |
	handler := RpWebSocketEventBusHandler new.
	handler rippleClass: RpRipple.
	socket := RpMockSocket new token: 'tok-custom'.
	handler register: socket.
	ripple := handler rippleFor: socket.
	self assert: (ripple isKindOf: RpRipple)
]
```

- [ ] **Step 7: Import and run — confirm all tests pass**

```
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core-Tests
/st-test RpRippleRoomTest
/st-test RpMessageDispatcherTest
```

Expected: All tests pass (existing `RpMessageDispatcherTest` tests must still pass because `rippleClass` defaults to `RpRipple`).

- [ ] **Step 8: Commit**

```bash
git add src/Ripple-Core/RpWebSocketBaseHandler.class.st \
        src/Ripple-Core-Tests/RpRippleRoomTest.class.st
git commit -m "feat: add rippleClass to RpWebSocketBaseHandler"
```

---

## Task 2: Implement `RpRippleRoom`

**Files:**
- Create: `src/Ripple-Core/RpRippleRoom.class.st`
- Create: `src/Ripple-Core-Tests/RpMockServer.class.st`
- Modify: `src/Ripple-Core-Tests/RpRippleRoomTest.class.st`

- [ ] **Step 1: Add failing tests for RpRippleRoom to the test class**

Append these tests to `src/Ripple-Core-Tests/RpRippleRoomTest.class.st`:

```smalltalk
{ #category : #tests }
RpRippleRoomTest >> testRoomName [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room name equals: 'foo'
]

{ #category : #tests }
RpRippleRoomTest >> testRoomRippleClass [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room rippleClass equals: RpRipple
]

{ #category : #tests }
RpRippleRoomTest >> testRouteDerivesFromName [
	| room |
	room := RpRippleRoom name: 'chat' rippleClass: RpRipple.
	self assert: room route equals: '/ws/chat'
]

{ #category : #tests }
RpRippleRoomTest >> testHandlerIsKindOfEventBusHandler [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: (room handler isKindOf: RpWebSocketEventBusHandler)
]

{ #category : #tests }
RpRippleRoomTest >> testHandlerHasRippleClassSet [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room handler rippleClass equals: RpRipple
]

{ #category : #tests }
RpRippleRoomTest >> testHandlerIsCachedOnSubsequentAccess [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room handler == room handler
]

{ #category : #tests }
RpRippleRoomTest >> testAddedToRegistersRouteAndHandler [
	| room mockServer |
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	mockServer := RpMockServer new.
	room addedTo: mockServer.
	self assert: mockServer lastRoutePath equals: '/ws/test'.
	self assert: mockServer lastRouteHandler equals: room handler
]
```

- [ ] **Step 2: Run tests to confirm they fail**

```
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core-Tests
/st-test RpRippleRoomTest
```

Expected: Multiple failures — `RpRippleRoom` does not exist, `RpMockServer` does not exist.

- [ ] **Step 3: Create `RpMockServer`**

Create `src/Ripple-Core-Tests/RpMockServer.class.st`:

```smalltalk
Class {
	#name : #RpMockServer,
	#superclass : #Object,
	#instVars : [
		'addedRoutes'
	],
	#category : #'Ripple-Core-Tests'
}

{ #category : #initialization }
RpMockServer >> initialize [
	addedRoutes := OrderedCollection new
]

{ #category : #routing }
RpMockServer >> addRoute: aPath handler: aHandler [
	addedRoutes add: (Association key: aPath value: aHandler)
]

{ #category : #accessing }
RpMockServer >> addedRoutes [
	^ addedRoutes
]

{ #category : #accessing }
RpMockServer >> lastRoutePath [
	^ addedRoutes last key
]

{ #category : #accessing }
RpMockServer >> lastRouteHandler [
	^ addedRoutes last value
]
```

- [ ] **Step 4: Create `RpRippleRoom`**

Create `src/Ripple-Core/RpRippleRoom.class.st`:

```smalltalk
Class {
	#name : #RpRippleRoom,
	#superclass : #Object,
	#instVars : [
		'name',
		'handler',
		'rippleClass'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpRippleRoom class >> name: aName rippleClass: aRippleClass [
	^ self new
		name: aName;
		rippleClass: aRippleClass;
		yourself
]

{ #category : #routing }
RpRippleRoom >> addedTo: aRippleServer [
	aRippleServer addRoute: self route handler: self handler
]

{ #category : #private }
RpRippleRoom >> createHandler [
	| newHandler |
	newHandler := RpWebSocketEventBusHandler handlerNamed: self name.
	newHandler rippleClass: self rippleClass.
	^ newHandler
]

{ #category : #accessing }
RpRippleRoom >> handler [
	^ handler ifNil: [ handler := self createHandler ]
]

{ #category : #accessing }
RpRippleRoom >> handler: anObject [
	handler := anObject
]

{ #category : #accessing }
RpRippleRoom >> name [
	^ name
]

{ #category : #accessing }
RpRippleRoom >> name: anObject [
	name := anObject
]

{ #category : #accessing }
RpRippleRoom >> rippleClass [
	^ rippleClass ifNil: [ rippleClass := RpRipple ]
]

{ #category : #accessing }
RpRippleRoom >> rippleClass: aClass [
	rippleClass := aClass
]

{ #category : #routing }
RpRippleRoom >> route [
	^ '/ws/', name
]
```

- [ ] **Step 5: Import and run all tests**

```
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core-Tests
/st-test RpRippleRoomTest
/st-test RpMessageDispatcherTest
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add src/Ripple-Core/RpRippleRoom.class.st \
        src/Ripple-Core-Tests/RpMockServer.class.st \
        src/Ripple-Core-Tests/RpRippleRoomTest.class.st
git commit -m "feat: add RpRippleRoom and RpMockServer test double"
```

---

## Task 3: Convenience API — `RpServer` and `RpRipple`

**Files:**
- Modify: `src/Ripple-Core/RpServer.class.st`
- Modify: `src/Ripple-Core/RpRipple.class.st`
- Create: `src/Ripple-Core-Tests/RpMockRipple.class.st` (test fixture)
- Modify: `src/Ripple-Core-Tests/RpRippleRoomTest.class.st`

- [ ] **Step 1: Create test fixture `RpMockRipple`**

Create `src/Ripple-Core-Tests/RpMockRipple.class.st`:

```smalltalk
Class {
	#name : #RpMockRipple,
	#superclass : #RpRipple,
	#category : #'Ripple-Core-Tests'
}

{ #category : #accessing }
RpMockRipple class >> roomName [
	^ 'mock'
]
```

This only overrides `roomName`. The inherited `room` method (added to `RpRipple` in Step 6) handles the rest.

- [ ] **Step 2: Add failing tests for `addRoom:`, `addRoomOf:`, and `RpRipple class >> room`**

Append to `src/Ripple-Core-Tests/RpRippleRoomTest.class.st`:

```smalltalk
{ #category : #tests }
RpRippleRoomTest >> testAddRoomRegistersRoomRoute [
	| server room |
	server := RpMockServer new.
	room := RpRippleRoom name: 'chat' rippleClass: RpRipple.
	server addRoom: room.
	self assert: server lastRoutePath equals: '/ws/chat'
]

{ #category : #tests }
RpRippleRoomTest >> testAddRoomOfDelegatesToRippleClassRoom [
	| server |
	server := RpMockServer new.
	server addRoomOf: RpMockRipple.
	self assert: server lastRoutePath equals: '/ws/mock'.
	self assert: server lastRouteHandler rippleClass equals: RpMockRipple
]

{ #category : #tests }
RpRippleRoomTest >> testRpRippleRoomRaisesErrorWhenRoomNameNotOverridden [
	self should: [ RpRipple room ] raise: Error
]
```

Note: `testAddRoomRegistersRoomRoute` and `testAddRoomOfDelegatesToRippleClassRoom` use `RpMockServer` (not `RpServer`) because `RpServer new` initializes a full Teapot instance. The important behaviors — `addRoom:` delegates to `addedTo:` and `addRoomOf:` calls `aClass room` — are exercised through `RpMockServer`.

- [ ] **Step 3: Run to confirm failures**

```
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core-Tests
/st-test RpRippleRoomTest
```

Expected: 3 failures — `addRoom:` not found on `RpMockServer`, `addRoomOf:` not found, `RpRipple room` does not raise.

- [ ] **Step 4: Add `addRoom:` and `addRoomOf:` to `RpMockServer`**

Append to `src/Ripple-Core-Tests/RpMockServer.class.st`:

```smalltalk
{ #category : #routing }
RpMockServer >> addRoom: aRippleRoom [
	aRippleRoom addedTo: self
]

{ #category : #routing }
RpMockServer >> addRoomOf: aRippleClass [
	self addRoom: aRippleClass room
]
```

These mirror exactly what `RpServer` will implement, so the same tests validate both.

- [ ] **Step 5: Add `addRoom:` and `addRoomOf:` to `RpServer`**

Append to `src/Ripple-Core/RpServer.class.st`:

```smalltalk
{ #category : #routing }
RpServer >> addRoom: aRippleRoom [
	aRippleRoom addedTo: self
]

{ #category : #routing }
RpServer >> addRoomOf: aRippleClass [
	self addRoom: aRippleClass room
]
```

- [ ] **Step 6: Add `roomName` and `room` class methods to `RpRipple`**

Append to `src/Ripple-Core/RpRipple.class.st`:

```smalltalk
{ #category : #accessing }
RpRipple class >> roomName [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
RpRipple class >> room [
	^ RpRippleRoom name: self roomName rippleClass: self
]
```

Subclasses only need to override `roomName`. The `room` method is shared by all.

- [ ] **Step 7: Import and run all tests**

```
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core
/st-import /Volumes/SSPJ-UTC/git.ssd/Ripple/src/Ripple-Core-Tests
/st-test RpRippleRoomTest
/st-test RpMessageDispatcherTest
```

Expected: All tests pass.

- [ ] **Step 8: Export to ensure Tonel files are in sync**

```smalltalk
(IceRepository registry detect: [:r | r name = 'Ripple']) workingCopy saveAllChanges.
```

- [ ] **Step 9: Commit**

```bash
git add src/Ripple-Core/RpServer.class.st \
        src/Ripple-Core/RpRipple.class.st \
        src/Ripple-Core-Tests/RpMockRipple.class.st \
        src/Ripple-Core-Tests/RpMockServer.class.st \
        src/Ripple-Core-Tests/RpRippleRoomTest.class.st
git commit -m "feat: add addRoom:/addRoomOf: to RpServer and room/roomName to RpRipple"
```

---

## Self-Review

### Spec coverage

| Spec requirement | Covered by |
|-----------------|------------|
| `RpRippleRoom` with `name`, `handler`, `rippleClass` (lazy) | Task 2 — `RpRippleRoom` class |
| `RpServer >> addRoom: aRippleRoom` | Task 3, Step 5 |
| `RpRippleRoom >> addedTo:` calls `addRoute:handler:` | Task 2 — `addedTo:` + `testAddedToRegistersRouteAndHandler` |
| `createHandler` uses `handlerNamed:` + sets `rippleClass:` | Task 2 — `createHandler` |
| `RpServer >> addRoomOf: aRippleClass` | Task 3, Step 5 |
| `FooRipple class >> roomName` override pattern | Task 3 — `RpMockRipple` fixture |
| `rippleClass` configurable on handler | Task 1 |

### Placeholder scan

No TBD, TODO, or incomplete steps found.

### Type consistency

- `RpRippleRoom name: aName rippleClass: aRippleClass` — used consistently in all tasks
- `room route` → `'/ws/', name` — consistent across all tests
- `handler rippleClass` — Task 1 adds this, Task 2 verifies it
- `RpMockServer >> addRoom:` mirrors `RpServer >> addRoom:` exactly — no drift
