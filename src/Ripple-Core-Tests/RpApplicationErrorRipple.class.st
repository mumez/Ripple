Class {
	#name : #RpApplicationErrorRipple,
	#superclass : #RpRipple,
	#category : #'Ripple-Core-Tests'
}

{ #category : #testing }
RpApplicationErrorRipple class >> shouldAutoPutRoute [
	^ false
]

{ #category : #accessing }
RpApplicationErrorRipple class >> roomName [
	^ 'application-error-test'
]

{ #category : #'message handling' }
RpApplicationErrorRipple >> handleRequest: aMessage [
	(RpError application: 'app error') signal
]

{ #category : #'message handling' }
RpApplicationErrorRipple >> handleSend: aMessage [
	(RpError application: 'app error on send') signal
]
