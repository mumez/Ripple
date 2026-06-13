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

{ #category : #tests }
RpRippleRoomTest >> testAddRoomRegistersRoomRoute [
	| server room |
	server := RpMockServer new.
	room := RpRippleRoom name: 'chat' rippleClass: RpRipple.
	server addRoom: room.
	self assert: server lastRoutePath equals: '/ws/chat'
]

{ #category : #tests }
RpRippleRoomTest >> testAddRoomOfDelegatesToRippleClassRoom [
	| server |
	server := RpMockServer new.
	server addRoomOf: RpMockRipple.
	self assert: server lastRoutePath equals: '/ws/mock'.
	self assert: server lastRouteHandler rippleClass equals: RpMockRipple
]

{ #category : #tests }
RpRippleRoomTest >> testRpRippleRoomRaisesErrorWhenRoomNameNotOverridden [
	self should: [ RpRipple room ] raise: Error
]

{ #category : #tests }
RpRippleRoomTest >> testRoomSettingsReturnsDefaultCopied [
	| settings |
	settings := RpRipple roomSettings.
	self assert: settings class equals: RpRoomSettings.
	self deny: settings allowClientPublish
]

{ #category : #tests }
RpRippleRoomTest >> testRoomUsesRippleClassRoomSettings [
	| room |
	room := RpRippleRoom name: 'test' rippleClass: RpTestRipple.
	self assert: room settings allowClientPublish
]

{ #category : #tests }
RpRippleRoomTest >> testRippleRoomIsSameObjectForAllRipplesInRoom [
	| room handler socket1 socket2 ripple1 ripple2 |
	room := RpRippleRoom name: 'chat' rippleClass: RpRipple.
	handler := room handler.
	socket1 := RpMockSocket new token: 'tok-1'.
	socket2 := RpMockSocket new token: 'tok-2'.
	socket1 baseHandler: handler.
	socket2 baseHandler: handler.
	handler register: socket1.
	handler register: socket2.
	ripple1 := handler rippleFor: socket1.
	ripple2 := handler rippleFor: socket2.
	self assert: ripple1 room == room.
	self assert: ripple2 room == room
]

{ #category : #tests }
RpRippleRoomTest >> testValidateTokenDefaultBehavior [
	| room |
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	
	self assert: (room validateToken: 'valid-token').
	self deny: (room validateToken: '').
	self deny: (room validateToken: nil)
]

{ #category : #tests }
RpRippleRoomTest >> testValidateTokenDefaultBehavior [
	| room |
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	
	self assert: (room validateToken: 'valid-token').
	self deny: (room validateToken: '').
	self deny: (room validateToken: nil)
]

{ #category : #tests }
RpRippleRoomTest >> testValidateTokenDefaultBehavior [
	| room |
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	
	self assert: (room validateToken: 'valid-token').
	self deny: (room validateToken: '').
	self deny: (room validateToken: nil)
]

{ #category : #tests }
RpRippleRoomTest >> testValidateTokenDefaultBehavior [
	| room |
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	
	self assert: (room validateToken: 'valid-token').
	self deny: (room validateToken: '').
	self deny: (room validateToken: nil)
]
