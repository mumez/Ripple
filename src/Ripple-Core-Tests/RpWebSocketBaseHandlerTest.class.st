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

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenDelegatesToRippleRoom [
	| handler room |
	handler := RpWebSocketBaseHandler new.
	room := RpMockRippleRoom name: 'mock' rippleClass: RpMockRipple.
	handler rippleRoom: room.
	
	self assert: (handler validateToken: 'mock-token').
	self deny: (handler validateToken: 'invalid-token')
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenFallsBackWhenRippleRoomIsNil [
	| handler |
	handler := RpWebSocketBaseHandler new.
	handler rippleRoom: nil.
	
	self assert: (handler validateToken: 'any-token').
	self deny: (handler validateToken: '').
	self deny: (handler validateToken: nil)
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenDelegatesToRippleRoom [
	| handler room |
	handler := RpWebSocketBaseHandler new.
	room := RpMockRippleRoom name: 'mock' rippleClass: RpMockRipple.
	handler rippleRoom: room.
	
	self assert: (handler validateToken: 'mock-token').
	self deny: (handler validateToken: 'invalid-token')
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenFallsBackWhenRippleRoomIsNil [
	| handler |
	handler := RpWebSocketBaseHandler new.
	handler rippleRoom: nil.
	
	self assert: (handler validateToken: 'any-token').
	self deny: (handler validateToken: '').
	self deny: (handler validateToken: nil)
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenDelegatesToRippleRoom [
	| handler room |
	handler := RpWebSocketBaseHandler new.
	room := RpMockRippleRoom name: 'mock' rippleClass: RpMockRipple.
	handler rippleRoom: room.
	
	self assert: (handler validateToken: 'mock-token').
	self deny: (handler validateToken: 'invalid-token')
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenFallsBackWhenRippleRoomIsNil [
	| handler |
	handler := RpWebSocketBaseHandler new.
	handler rippleRoom: nil.
	
	self assert: (handler validateToken: 'any-token').
	self deny: (handler validateToken: '').
	self deny: (handler validateToken: nil)
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenDelegatesToRippleRoom [
	| handler room |
	handler := RpWebSocketBaseHandler new.
	room := RpMockRippleRoom name: 'mock' rippleClass: RpMockRipple.
	handler rippleRoom: room.
	
	self assert: (handler validateToken: 'mock-token').
	self deny: (handler validateToken: 'invalid-token')
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenFallsBackWhenRippleRoomIsNil [
	| handler |
	handler := RpWebSocketBaseHandler new.
	handler rippleRoom: nil.
	
	self assert: (handler validateToken: 'any-token').
	self deny: (handler validateToken: '').
	self deny: (handler validateToken: nil)
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenDelegatesToRippleRoom [
	| handler room |
	handler := RpWebSocketBaseHandler new.
	room := RpMockRippleRoom name: 'mock' rippleClass: RpMockRipple.
	handler rippleRoom: room.
	
	self assert: (handler validateToken: 'mock-token').
	self deny: (handler validateToken: 'invalid-token')
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenFallsBackWhenRippleRoomIsNil [
	| handler |
	handler := RpWebSocketBaseHandler new.
	handler rippleRoom: nil.
	
	self assert: (handler validateToken: 'any-token').
	self deny: (handler validateToken: '').
	self deny: (handler validateToken: nil)
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenDelegatesToRippleRoom [
	| handler room |
	handler := RpWebSocketBaseHandler new.
	room := RpMockRippleRoom name: 'mock' rippleClass: RpMockRipple.
	handler rippleRoom: room.
	
	self assert: (handler validateToken: 'mock-token').
	self deny: (handler validateToken: 'invalid-token')
]

{ #category : #tests }
RpWebSocketBaseHandlerTest >> testValidateTokenFallsBackWhenRippleRoomIsNil [
	| handler |
	handler := RpWebSocketBaseHandler new.
	handler rippleRoom: nil.
	
	self assert: (handler validateToken: 'any-token').
	self deny: (handler validateToken: '').
	self deny: (handler validateToken: nil)
]
