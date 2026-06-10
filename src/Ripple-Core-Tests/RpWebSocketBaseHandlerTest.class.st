Class {
	#name : #RpWebSocketBaseHandlerTest,
	#superclass : #TestCase,
	#category : #'Ripple-Core-Tests'
}

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testUnregisterCallsRippleUnregistered [
	| handler socket ripple |
	handler := RpWebSocketBaseHandler new.
	handler rippleClass: RpUnregisterTrackingRipple.
	socket := RpMockSocket new token: 'tok-test'.
	handler register: socket.
	ripple := handler rippleFor: socket.
	self assert: ripple isNotNil.
	self deny: ripple wasUnregistered.

	handler unregister: socket.

	self assert: ripple wasUnregistered
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testUnregisterRemovesRippleFromRegistry [
	| handler socket |
	handler := RpWebSocketBaseHandler new.
	socket := RpMockSocket new token: 'tok-test'.
	handler register: socket.
	self assert: (handler rippleFor: socket) isNotNil.

	handler unregister: socket.

	self assert: (handler rippleFor: socket) isNil
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testUnregisterWithUnknownSocketDoesNotRaise [
	| handler socket |
	handler := RpWebSocketBaseHandler new.
	socket := RpMockSocket new token: 'tok-unknown'.

	self shouldnt: [ handler unregister: socket ] raise: Error
]
