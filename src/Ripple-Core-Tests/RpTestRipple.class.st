Class {
	#name : #RpTestRipple,
	#superclass : #RpRipple,
	#classInstVars : [
		'publishProcess'
	],
	#category : #'Ripple-Core-Tests'
}

{ #category : #accessing }
RpTestRipple class >> roomName [
	^ 'ripple-integration-test'
]

{ #category : #accessing }
RpTestRipple class >> roomSettings [
	^ super roomSettings allowClientPublish: true; yourself
]

{ #category : #private }
RpTestRipple class >> publishProcess [
	^ publishProcess
]

{ #category : #private }
RpTestRipple class >> publishProcess: aProcess [
	publishProcess := aProcess
]

{ #category : #private }
RpTestRipple class >> stopPublishing [
	self publishProcess ifNotNil: [ :process | process terminate ].
	self publishProcess: nil
]

{ #category : #'message handling' }
RpTestRipple >> handleRequest: aMessage [
	| sessionKey |
	sessionKey := aMessage body at: 'sessionKey' ifAbsent: [ 'unknown' ].
	Transcript crShow: '[RpTestRipple] request from ' , sessionKey.
	self webSocket sendReply: { 'result' -> 'reply from server'. 'sessionKey' -> sessionKey } asDictionary for: aMessage
]

{ #category : #'message handling' }
RpTestRipple >> handleSend: aMessage [
	| command sessionKey |
	command := aMessage body at: 'message' ifAbsent: [ aMessage body printString ].
	sessionKey := aMessage body at: 'sessionKey' ifAbsent: [ 'unknown' ].
	Transcript crShow: '[RpTestRipple] send from ' , sessionKey , ': ' , command.
	command = 'send from client' ifTrue: [
		self webSocket
			send: { 'message' -> 'send back from server'. 'sessionKey' -> sessionKey } asDictionary
			to: 'test-response'.
		^ self ].
	command = 'start publish' ifTrue: [
		self startPublishing.
		^ self ].
	command = 'stop publish' ifTrue: [
		self stopPublishing.
		^ self ]
]

{ #category : #private }
RpTestRipple >> startPublishing [
	| socket |
	"Keep only one publish process regardless of the number of clients for testing purposes.
	The process is held in a class instance variable; stop any existing one before starting a new one."
	self class stopPublishing.
	socket := self webSocket.
	self class publishProcess: [
		[ true ] whileTrue: [
			[ socket publish: { 'message' -> 'publish from server' } asDictionary to: 'test-events' ]
				on: Error
				do: [ :ex | Transcript crShow: '[RpTestRipple] publish error: ' , ex messageText ].
			(Delay forSeconds: 2) wait ] ] fork
]

{ #category : #private }
RpTestRipple >> stopPublishing [
	self class stopPublishing
]
