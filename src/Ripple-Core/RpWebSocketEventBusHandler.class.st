"
I extend RpWebSocketBaseHandler with publish/subscribe routing, maintaining a
subscription dictionary that maps address strings to sets of WebSocket connections.

Responsibility:
- I parse raw JSON into RpMessage and delegate dispatch to RpMessageDispatcher
- I maintain subscriptionDict: a map of address -> Set of subscriber WebSockets
- I add each connecting socket to its token's subscriber set on register
- I broadcast publish messages to all sockets subscribed to a given address

Collaborators:
- RpWebSocketBaseHandler: my superclass; I inherit connection and ripple management
- RpMessage: parsed from raw JSON before dispatch
- RpMessageDispatcher: performs type-based dispatch of each message
- RpRoomSettings: my settings; controls allowClientPublish and maxErrorCount

Public API and Key Messages:
- #publishMessage: jsonDict to: address - broadcast to all subscribers of address
- #subscriptionDict - address-to-socket-set mapping (lazily created)

Implementation Points:
- subscriptionDict entries are keyed by address string, not token
- On register, the token string is added as a default subscriber (for direct send)
- Stale disconnected sockets are pruned from subscriptions during register/unregister/dispatch
"
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
	msg type ifNil: [
		^ self logger warn: { self className. #NoMessageType. rawMessage } ].
	webSocket baseHandler: self.
	(RpMessageDispatcher message: msg socket: webSocket handler: self) dispatch
]

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
RpWebSocketEventBusHandler >> settings [
	settings ifNil: [ settings := RpRoomSettings defaultCopied ].
	^ settings
]

{ #category : #accessing }
RpWebSocketEventBusHandler >> subscriptionDict [
	^ subscriptionDict ifNil: [ subscriptionDict := Dictionary new ]
]

{ #category : #accessing }
RpWebSocketEventBusHandler >> subscriptionDict: anObject [
	subscriptionDict := anObject
]
