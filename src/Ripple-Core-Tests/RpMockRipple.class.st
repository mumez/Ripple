Class {
	#name : #RpMockRipple,
	#superclass : #RpRipple,
	#category : #'Ripple-Core-Tests'
}

{ #category : #testing }
RpMockRipple class >> shouldAutoPutRoute [
	^ false
]

{ #category : #accessing }
RpMockRipple class >> roomName [
	^ 'mock'
]
