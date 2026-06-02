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
