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
RpMessageDispatcherTest >> testDispatchPingSendsPong [
	| msg dispatcher |
	msg := RpMessage fromJsonString: '{"type":"ping"}'.
	dispatcher := RpMessageDispatcher message: msg socket: mockSocket handler: handler.
	dispatcher dispatch.
	self assert: mockSocket sentMessages isEmpty not.
	self assert: (mockSocket lastMessage at: 'type') equals: 'pong'
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
RpMessageDispatcherTest >> testDispatchRequestNoSessionSendsError [
	| unregisteredSocket msg dispatcher |
	unregisteredSocket := RpMockSocket new token: 'unknown-tok'.
	msg := RpMessage fromJsonString: '{"type":"request","address":"a","correlationId":"c1"}'.
	dispatcher := RpMessageDispatcher message: msg socket: unregisteredSocket handler: handler.
	dispatcher dispatch.
	self assert: (unregisteredSocket lastMessage at: 'type') equals: 'err'.
	self assert: (unregisteredSocket lastMessage at: 'failureType') equals: 'NoSession'
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
RpMessageDispatcherTest >> testDispatchPublishBroadcastsToRegisteredAddress [
	| reg dispatcher sent |
	handler settings allowClientPublish: true.
	reg := RpMessageDispatcher
		message: (RpMessage fromJsonString: '{"type":"register","address":"topic.x"}')
		socket: mockSocket
		handler: handler.
	reg dispatch.
	dispatcher := RpMessageDispatcher
		message: (RpMessage fromJsonString: '{"type":"publish","address":"topic.x","body":{"x":1}}')
		socket: mockSocket
		handler: handler.
	dispatcher dispatch.
	sent := mockSocket lastMessage.
	self assert: (sent at: 'type') equals: 'publish'.
	self assert: (sent at: 'address') equals: 'topic.x'.
	self assert: ((sent at: 'body') at: 'x') equals: 1
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchPublishForbiddenWhenClientPublishDisallowed [
	| dispatcher sent |
	dispatcher := RpMessageDispatcher
		message: (RpMessage fromJsonString: '{"type":"publish","address":"topic.x","body":{"x":1}}')
		socket: mockSocket
		handler: handler.
	dispatcher dispatch.
	sent := mockSocket lastMessage.
	self assert: (sent at: 'type') equals: 'err'.
	self assert: (sent at: 'failureType') equals: 'Forbidden'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchRequestRpErrorSentAsApplicationError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpApplicationErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"request","address":"a","correlationId":"c1"}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'application'.
	self assert: (localSocket lastMessage at: 'correlationId') equals: 'c1'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchRequestGenericErrorSentAsHandlerError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpGenericErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"request","address":"a","correlationId":"c1"}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'HandlerError'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchUnknownTypeDoesNotCrash [
	| msg dispatcher |
	msg := RpMessage fromJsonString: '{"type":"bogus"}'.
	dispatcher := RpMessageDispatcher message: msg socket: mockSocket handler: handler.
	self shouldnt: [ dispatcher dispatch ] raise: Error
]

{ #category : #tests }
RpMessageDispatcherTest >> testRegisterAutoRegistersTokenAddress [
	"setUp already called handler register: mockSocket with token 'tok-1'"
	self assert: ((handler subscriptionDict at: 'tok-1' ifAbsent: [ Set new ]) includes: mockSocket)
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

{ #category : #tests }
RpMessageDispatcherTest >> testUnregisterRemovesTokenAddress [
	handler unregister: mockSocket.
	self assert: ((handler subscriptionDict at: 'tok-1' ifAbsent: [ Set new ]) includes: mockSocket) not
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
RpMessageDispatcherTest >> testDispatchSendRpErrorSentAsApplicationError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpApplicationErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'application'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendGenericErrorSentAsHandlerError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpGenericErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'HandlerError'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendRpErrorSentAsApplicationError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpApplicationErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'application'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendGenericErrorSentAsHandlerError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpGenericErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'HandlerError'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendRpErrorSentAsApplicationError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpApplicationErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'application'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendGenericErrorSentAsHandlerError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpGenericErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'HandlerError'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendRpErrorSentAsApplicationError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpApplicationErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'application'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendGenericErrorSentAsHandlerError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpGenericErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'HandlerError'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendRpErrorSentAsApplicationError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpApplicationErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'application'
]

{ #category : #tests }
RpMessageDispatcherTest >> testDispatchSendGenericErrorSentAsHandlerError [
	| localHandler localSocket msg dispatcher |
	localHandler := RpWebSocketEventBusHandler new.
	localHandler rippleClass: RpGenericErrorRipple.
	localSocket := RpMockSocket new token: 'err-tok'.
	localHandler register: localSocket.
	msg := RpMessage fromJsonString: '{"type":"send","address":"a","body":{"x":1}}'.
	dispatcher := RpMessageDispatcher message: msg socket: localSocket handler: localHandler.
	dispatcher dispatch.
	self assert: (localSocket lastMessage at: 'type') equals: 'err'.
	self assert: (localSocket lastMessage at: 'failureType') equals: 'HandlerError'
]
