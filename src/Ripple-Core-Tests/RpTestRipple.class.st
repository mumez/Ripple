Class {
	#name : #RpTestRipple,
	#superclass : #RpRipple,
	#instVars : [
		'publishProcess'
	],
	#category : #'Ripple-Core-Tests'
}

{ #category : #accessing }
RpTestRipple class >> roomName [
	^ 'test'
]

{ #category : #'message handling' }
RpTestRipple >> handleRequest: aMessage [
	self webSocket sendReply: { 'result' -> 'reply from server' } asDictionary for: aMessage
]

{ #category : #'message handling' }
RpTestRipple >> handleSend: aMessage [
	Transcript show: '[RpTestRipple] send received: ' , aMessage body printString; nl.
	aMessage body = 'send from client' ifTrue: [
		self webSocket sendJson: {
			'type' -> 'send'.
			'address' -> 'test-response'.
			'body' -> 'send back from server' } asDictionary.
		^ self ].
	aMessage body = 'start publish' ifTrue: [
		self startPublishing.
		^ self ].
	aMessage body = 'stop publish' ifTrue: [
		self stopPublishing.
		^ self ]
]

{ #category : #private }
RpTestRipple >> publishProcess [
	^ publishProcess
]

{ #category : #private }
RpTestRipple >> publishProcess: aProcess [
	publishProcess := aProcess
]

{ #category : #private }
RpTestRipple >> startPublishing [
	self stopPublishing.
	self publishProcess: [
		[ true ] whileTrue: [
			[ self webSocket publish: { 'message' -> 'publish from server' } asDictionary to: 'test-events' ]
				on: Error
				do: [ :ex | Transcript show: '[RpTestRipple] publish error: ' , ex messageText; nl ].
			(Delay forSeconds: 2) wait ] ] fork
]

{ #category : #private }
RpTestRipple >> stopPublishing [
	self publishProcess ifNotNil: [ :process | process terminate ].
	self publishProcess: nil
]
