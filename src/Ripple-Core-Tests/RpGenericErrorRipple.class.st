Class {
	#name : #RpGenericErrorRipple,
	#superclass : #RpRipple,
	#category : #'Ripple-Core-Tests'
}

{ #category : #testing }
RpGenericErrorRipple class >> shouldAutoPutRoute [
	^ false
]

{ #category : #accessing }
RpGenericErrorRipple class >> roomName [
	^ 'generic-error-test'
]

{ #category : #'message handling' }
RpGenericErrorRipple >> handleRequest: aMessage [
	Error signal: 'generic error'
]

{ #category : #'message handling' }
RpGenericErrorRipple >> handleSend: aMessage [
	Error signal: 'generic error on send'
]

{ #category : #'message handling' }
RpGenericErrorRipple >> handleSend: aMessage [
	Error signal: 'generic error on send'
]
