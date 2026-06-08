Class {
	#name : #RpApplicationErrorRipple,
	#superclass : #RpRipple,
	#category : #'Ripple-Core-Tests'
}

{ #category : #accessing }
RpApplicationErrorRipple class >> roomName [
	^ 'application-error-test'
]

{ #category : #'message handling' }
RpApplicationErrorRipple >> handleRequest: aMessage [
	(RpError application: 'app error') signal
]
