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
