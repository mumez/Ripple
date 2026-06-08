Class {
	#name : #RpGenericErrorRipple,
	#superclass : #RpRipple,
	#category : #'Ripple-Core-Tests'
}

{ #category : #accessing }
RpGenericErrorRipple class >> roomName [
	^ 'generic-error-test'
]

{ #category : #'message handling' }
RpGenericErrorRipple >> handleRequest: aMessage [
	Error signal: 'generic error'
]
