Class {
	#name : #RpRippleTest,
	#superclass : #TestCase,
	#category : #'Ripple-Core-Tests'
}

{ #category : #tests }
RpRippleTest >> testErrorCountAccessor [
	| ripple socket |
	socket := RpMockSocket new token: 'tok-err'.
	ripple := RpRipple on: socket.
	self assert: ripple errorCount equals: 0
]

{ #category : #tests }
RpRippleTest >> testErrorCountIncrementsOnNetworkError [
	| handler socket ripple |
	handler := RpWebSocketEventBusHandler new.
	handler rippleClass: RpRipple.
	socket := RpMockSocket new token: 'tok-err'.
	socket baseHandler: handler.
	handler register: socket.
	ripple := handler rippleFor: socket.
	self assert: ripple errorCount equals: 0.
	[ ripple send: Dictionary new to: 'test/address' ]
		on: NetworkError
		do: [ :ex | "expected" ].
	self assert: ripple errorCount equals: 1
]

{ #category : #tests }
RpRippleTest >> testUnregisterAfterMaxErrorCount [
	| handler socket ripple settings |
	handler := RpWebSocketEventBusHandler new.
	settings := RpRoomSettings defaultCopied.
	settings maxErrorCount: 3.
	handler settings: settings.
	handler rippleClass: RpRipple.
	socket := RpMockSocket new token: 'tok-unreg'.
	socket baseHandler: handler.
	handler register: socket.
	ripple := handler rippleFor: socket.
	self assert: ripple errorCount equals: 0.
	self assert: (handler rippleFor: socket) notNil.
	3 timesRepeat: [
		[ ripple send: Dictionary new to: 'test/address' ]
			on: NetworkError
			do: [ :ex | "expected" ] ].
	self assert: ripple errorCount equals: 3.
	self assert: (handler rippleFor: socket) isNil
]
