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
	message isPublish ifTrue: [ ^ self dispatchPublish ].
	message isRegister ifTrue: [ ^ self dispatchRegister ].
	message isUnregister ifTrue: [ ^ self dispatchUnregister ].
	message isPing ifTrue: [ ^ self dispatchPing ].
	handler logger warn: { handler className. #UnknownType. message type }
]

{ #category : #dispatching }
RpMessageDispatcher >> dispatchPublish [
	handler publishMessage: message body to: message address
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
