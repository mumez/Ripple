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
RpWebSocketEventBusHandler >> subscriptionDict [
	^ subscriptionDict ifNil: [ subscriptionDict := Dictionary new ]
]

{ #category : #accessing }
RpWebSocketEventBusHandler >> subscriptionDict: anObject [
	subscriptionDict := anObject
]
