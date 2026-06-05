Class {
	#name : #RpWebSocket,
	#superclass : #ZnWebSocket,
	#instVars : [
		'originalResponse',
		'baseHandler'
	],
	#category : #'Ripple-Core'
}

{ #category : #accessing }
RpWebSocket >> acceptHeaderValue [
	^ self responseHeaders at: 'Sec-WebSocket-Accept' ifAbsent: [ '' ]
]

{ #category : #accessing }
RpWebSocket >> baseHandler [
	^ baseHandler
]

{ #category : #accessing }
RpWebSocket >> baseHandler: anObject [
	baseHandler := anObject
]

{ #category : #accessing }
RpWebSocket >> originalRequest [
	^self originalResponse originalRequest
]

{ #category : #accessing }
RpWebSocket >> originalResponse [
	^ originalResponse
]

{ #category : #accessing }
RpWebSocket >> originalResponse: anObject [
	originalResponse := anObject
]

{ #category : #actions }
RpWebSocket >> publish: jsonDict to: address [
	^self baseHandler publishMessage: jsonDict to: address
]

{ #category : #actions }
RpWebSocket >> send: jsonDict to: address [
	| envelope |
	envelope := { 'type' -> 'send'. 'address' -> address. 'body' -> jsonDict } asDictionary.
	self sendJson: envelope
]

{ #category : #accessing }
RpWebSocket >> requestHeaders [
	^self originalRequest headers
]

{ #category : #accessing }
RpWebSocket >> requestQuery [
	^self requestUri query
]

{ #category : #accessing }
RpWebSocket >> requestUri [
	^self originalRequest uri
]

{ #category : #accessing }
RpWebSocket >> responseHeaders [
	^self originalResponse headers
]

{ #category : #'sending events' }
RpWebSocket >> sendError: message [
	self sendError: message type: 'general'
]

{ #category : #'sending events' }
RpWebSocket >> sendError: message type: failureType [
	self sendError: message type: failureType code: 0
]

{ #category : #'sending events' }
RpWebSocket >> sendError: message type: failureType code: failureCode [
	self sendError: message type: failureType code: failureCode otherData: nil
]

{ #category : #'sending events' }
RpWebSocket >> sendError: message type: failureType code: failureCode otherData: otherData [
	| jsonDict |
	jsonDict := { 'type'->'err'. 'failureCode'->failureCode. 'failureType'->failureType. 'message'->message} asDictionary.
	otherData ifNotNil: [jsonDict at: 'data' put: otherData].
	self sendJson: jsonDict.
]

{ #category : #sending }
RpWebSocket >> sendJson: anObject [
	self sendText: (NeoJSONWriter toString: anObject) 
]

{ #category : #'sending events' }
RpWebSocket >> sendPublish: replyDict to: address [
	| jsonDict |
	jsonDict := {'type'->'publish'. 'address'->address} asDictionary.
	jsonDict at: 'body' put: replyDict asDictionary.
	self sendJson: jsonDict.
]

{ #category : #'sending events' }
RpWebSocket >> sendErrorFor: aMessage type: failureType message: errorMessage [
	self sendErrorFor: aMessage type: failureType code: 0 message: errorMessage
]

{ #category : #'sending events' }
RpWebSocket >> sendErrorFor: aMessage type: failureType code: failureCode message: errorMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'err'.
	jsonDict at: 'failureType' put: failureType.
	jsonDict at: 'failureCode' put: failureCode.
	jsonDict at: 'message' put: errorMessage.
	aMessage isRequest ifTrue: [ jsonDict at: 'correlationId' put: aMessage correlationId ].
	self sendJson: jsonDict
]

{ #category : #'sending events' }
RpWebSocket >> sendPong [
	self sendJson: (Dictionary new at: 'type' put: 'pong'; yourself)
]

{ #category : #'sending events' }
RpWebSocket >> sendReply: bodyDict for: aMessage [
	| jsonDict |
	jsonDict := Dictionary new.
	jsonDict at: 'type' put: 'reply'.
	jsonDict at: 'address' put: aMessage address.
	jsonDict at: 'correlationId' put: aMessage correlationId.
	jsonDict at: 'body' put: bodyDict.
	self sendJson: jsonDict
]

{ #category : #accessing }
RpWebSocket >> token [
	self requestQuery ifNil: [ ^ self acceptHeaderValue ].
	^ self requestQuery at: 'token' ifAbsent: ['']
]
