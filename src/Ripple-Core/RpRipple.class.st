Class {
	#name : #RpRipple,
	#superclass : #Object,
	#instVars : [
		'webSocket'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpRipple class >> room [
	^ RpRippleRoom name: self roomName rippleClass: self
]

{ #category : #accessing }
RpRipple class >> roomName [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
RpRipple class >> on: aWebSocket [
	^ self new
		webSocket: aWebSocket;
		yourself
]

{ #category : #'message handling' }
RpRipple >> handleRequest: aMessage [
	self webSocket sendReply: (Dictionary new
		at: 'timestamp' put: DateAndTime now asString;
		yourself) for: aMessage
]

{ #category : #'message handling' }
RpRipple >> handleSend: aMessage [
]

{ #category : #accessing }
RpRipple >> token [
	^ webSocket token
]

{ #category : #accessing }
RpRipple >> webSocket [
	^ webSocket
]

{ #category : #accessing }
RpRipple >> webSocket: anObject [
	webSocket := anObject
]
