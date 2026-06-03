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

{ #category : #tests }
RpRippleRoomTest >> testRoomName [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room name equals: 'foo'
]

{ #category : #tests }
RpRippleRoomTest >> testRoomRippleClass [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room rippleClass equals: RpRipple
]

{ #category : #tests }
RpRippleRoomTest >> testRouteDerivesFromName [
	| room |
	room := RpRippleRoom name: 'chat' rippleClass: RpRipple.
	self assert: room route equals: '/ws/chat'
]

{ #category : #tests }
RpRippleRoomTest >> testHandlerIsKindOfEventBusHandler [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: (room handler isKindOf: RpWebSocketEventBusHandler)
]

{ #category : #tests }
RpRippleRoomTest >> testHandlerHasRippleClassSet [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room handler rippleClass equals: RpRipple
]

{ #category : #tests }
RpRippleRoomTest >> testHandlerIsCachedOnSubsequentAccess [
	| room |
	room := RpRippleRoom name: 'foo' rippleClass: RpRipple.
	self assert: room handler == room handler
]

{ #category : #tests }
RpRippleRoomTest >> testAddedToRegistersRouteAndHandler [
	| room mockServer |
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	mockServer := RpMockServer new.
	room addedTo: mockServer.
	self assert: mockServer lastRoutePath equals: '/ws/test'.
	self assert: mockServer lastRouteHandler equals: room handler
]
