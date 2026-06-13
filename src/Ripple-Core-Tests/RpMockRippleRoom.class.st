Class {
	#name : #RpMockRippleRoom,
	#superclass : #RpRippleRoom,
	#category : #'Ripple-Core-Tests'
}

{ #category : #'token-validation' }
RpMockRippleRoom >> validateToken: aToken [
	^ aToken = 'mock-token'
]
