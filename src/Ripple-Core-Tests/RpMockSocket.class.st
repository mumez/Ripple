Class {
	#name : #RpMockSocket,
	#superclass : #Object,
	#instVars : [
		'sentMessages',
		'myToken',
		'connected',
		'baseHandler'
	],
	#category : #'Ripple-Core-Tests'
}

{ #category : #accessing }
RpMockSocket >> baseHandler [
	^ baseHandler
]

{ #category : #accessing }
RpMockSocket >> baseHandler: anObject [
	baseHandler := anObject
]

{ #category : #accessing }
RpMockSocket >> connected: aBoolean [
	connected := aBoolean
]

{ #category : #initialization }
RpMockSocket >> initialize [
	sentMessages := OrderedCollection new.
	connected := true
]

{ #category : #testing }
RpMockSocket >> isConnected [
	^ connected
]

{ #category : #accessing }
RpMockSocket >> lastMessage [
	^ sentMessages last
]

{ #category : #sending }
RpMockSocket >> sendJson: anObject [
	sentMessages add: anObject
]

{ #category : #sending }
RpMockSocket >> sendErrorFor: aMessage type: failureType message: errorMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'err'.
	jsonDict at: 'failureType' put: failureType.
	jsonDict at: 'failureCode' put: 0.
	jsonDict at: 'message' put: errorMessage.
	aMessage isRequest ifTrue: [ jsonDict at: 'correlationId' put: aMessage correlationId ].
	sentMessages add: jsonDict
]

{ #category : #sending }
RpMockSocket >> sendPong [
	sentMessages add: (Dictionary new at: 'type' put: 'pong'; yourself)
]

{ #category : #sending }
RpMockSocket >> sendReply: bodyDict for: aMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'reply'.
	jsonDict at: 'address' put: aMessage address.
	jsonDict at: 'correlationId' put: aMessage correlationId.
	jsonDict at: 'body' put: bodyDict.
	sentMessages add: jsonDict
]

{ #category : #sending }
RpMockSocket >> sendPublish: messageData to: address [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'publish'.
	jsonDict at: 'address' put: address.
	jsonDict at: 'body' put: messageData asDictionary.
	sentMessages add: jsonDict
]

{ #category : #accessing }
RpMockSocket >> sentMessages [
	^ sentMessages
]

{ #category : #accessing }
RpMockSocket >> token [
	^ myToken
]

{ #category : #accessing }
RpMockSocket >> token: aString [
	myToken := aString
]
