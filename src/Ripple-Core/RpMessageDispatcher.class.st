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
		self originatorSocket sendErrorFor: self message type: 'NoSession' message: 'Session not found'.
		^ self ].
	[ ripple handleRequest: self message ]
		on: Error
		do: [ :ex |
			self originatorSocket
				sendErrorFor: self message
				type: 'HandlerError'
				message: ex messageText ]
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchSend [
	| ripple |
	ripple := self handler rippleFor: self originatorSocket.
	ripple ifNil: [
		self originatorSocket sendErrorFor: self message type: 'NoSession' message: 'Session not found'.
		^ self ].
	ripple handleSend: self message
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
