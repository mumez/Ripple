"
I perform type-based routing of a single RpMessage, invoking the appropriate
handler action on the originating socket, ripple, or event bus handler.

Responsibility:
- I inspect the message type and call the matching dispatch method
- I look up the RpRipple session for request/send messages and delegate to it
- I manage subscription registration and unregistration in the handler's subscriptionDict
- I guard handler calls and send typed RpError responses on failure

Collaborators:
- RpMessage: the message I dispatch
- RpWebSocket: the originating socket I send replies and errors to
- RpWebSocketEventBusHandler: the handler I query for ripples and subscriptions
- RpError: factory I use to build typed error responses

Public API and Key Messages:
- #dispatch - entry point; routes by message type
- #settings - delegates to handler settings (used for allowClientPublish check)

Internal Representation:
- message - the RpMessage being dispatched
- originatorSocket - the RpWebSocket that sent the message
- handler - the RpWebSocketEventBusHandler managing this room

Implementation Points:
- #safeHandle: catches RpError (sent as application error) and generic Error (sent as handler error)
- #dispatchRegister / #dispatchUnregister prune disconnected sockets as a side effect
"
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
	self message isRequest ifTrue: [ ^ self dispatchRequest ].
	self message isSend ifTrue: [ ^ self dispatchSend ].
	self message isPublish ifTrue: [ ^ self dispatchPublish ].
	self message isRegister ifTrue: [ ^ self dispatchRegister ].
	self message isUnregister ifTrue: [ ^ self dispatchUnregister ].
	self message isPing ifTrue: [ ^ self dispatchPing ].
	self handler logger warn: { self handler className. #UnknownType. self message type }
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchPing [
	self originatorSocket sendPong
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchPublish [
	self settings allowClientPublish ifFalse: [
		self sendForbiddenErrorFor: self message.
		^ self ].
	self handler publishMessage: self message body to: self message address
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchRegister [
	self handler lock critical: [
		| subscribers |
		subscribers := self handler subscriptionDict at: self message address ifAbsentPut: [ Set new ].
		subscribers add: self originatorSocket.
		(subscribers select: [ :each | each isConnected not ])
			do: [ :soc | subscribers remove: soc ifAbsent: [] ] ]
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchRequest [
	| ripple |
	ripple := self handler rippleFor: self originatorSocket.
	ripple ifNil: [
		self sendNoSessionErrorFor: self message.
		^ self ].
	self safeHandle: [ ripple handleRequest: self message ]
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchSend [
	| ripple |
	ripple := self handler rippleFor: self originatorSocket.
	ripple ifNil: [
		self sendNoSessionErrorFor: self message.
		^ self ].
	self safeHandle: [ ripple handleSend: self message ]
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchUnregister [
	self handler lock critical: [
		| subscribers |
		subscribers := self handler subscriptionDict at: self message address ifAbsent: [ ^ self ].
		subscribers remove: self originatorSocket ifAbsent: [].
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

{ #category : #'error sending' }
RpMessageDispatcher >> sendApplicationErrorFor: aMessage error: anRpError [
	self originatorSocket sendError: anRpError for: aMessage
]

{ #category : #'error sending' }
RpMessageDispatcher >> sendForbiddenErrorFor: aMessage [
	self originatorSocket sendError: RpError forbidden for: aMessage
]

{ #category : #'error sending' }
RpMessageDispatcher >> sendHandlerErrorFor: aMessage message: errorMessage [
	self originatorSocket sendError: (RpError handlerError: errorMessage) for: aMessage
]

{ #category : #'error sending' }
RpMessageDispatcher >> sendNoSessionErrorFor: aMessage [
	self originatorSocket sendError: RpError noSession for: aMessage
]

{ #category : #private }
RpMessageDispatcher >> safeHandle: aHandlerBlock [
	[ [ aHandlerBlock value ]
		on: RpError
		do: [ :ex | self sendApplicationErrorFor: self message error: ex ] ]
		on: Error
		do: [ :ex | self sendHandlerErrorFor: self message message: ex messageText ]
]

{ #category : #accessing }
RpMessageDispatcher >> settings [
	^ self handler settings
]
