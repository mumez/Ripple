"
I am a ZnWebSocket subclass that adds Ripple-specific messaging and metadata access.

Responsibility:
- I send typed JSON messages: reply, publish, error, pong, send
- I expose the original HTTP request/response for token and header extraction
- I hold a back-reference to my RpWebSocketBaseHandler for room-level publish

Collaborators:
- ZnWebSocket: my superclass providing raw WebSocket framing
- RpWebSocketResponse: the original upgrade response I hold to access request headers
- RpWebSocketBaseHandler: accessed via baseHandler for #publish:to:
- RpError: serialised to JSON and sent as error frames
- NeoJSONWriter: serialises all outgoing messages to JSON text

Public API and Key Messages:
- #sendReply: bodyDict for: aMessage - correlated reply to a request
- #sendPublish: replyDict to: address - broadcast envelope to a subscriber
- #sendError: anRpError for: aMessage - error with optional correlationId
- #sendPong - respond to a ping
- #token - extracts the session token from the query string (or accept header fallback)
- #publish: jsonDict to: address - delegates to handler for room-level broadcast

Internal Representation:
- originalResponse - RpWebSocketResponse holding the upgrade request/headers
- baseHandler - the RpWebSocketEventBusHandler managing this connection
- sendLock - Mutex serialising outgoing frame writes on this connection, preventing interleaved frames when multiple processes send concurrently (e.g. broadcast publish and direct send racing on the same socket)
"
Class {
	#name : #RpWebSocket,
	#superclass : #ZnWebSocket,
	#instVars : [
		'originalResponse',
		'baseHandler',
		'sendLock'
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
RpWebSocket >> sendError: anRpError [
	self sendJson: anRpError asJson
]

{ #category : #'sending events' }
RpWebSocket >> sendError: anRpError for: aMessage [
	| jsonDict |
	jsonDict := anRpError asJson.
	aMessage isRequest ifTrue: [ jsonDict at: 'correlationId' put: aMessage correlationId ].
	self sendJson: jsonDict
]

{ #category : #sending }
RpWebSocket >> sendJson: anObject [
	self sendLock critical: [
		self sendText: (NeoJSONWriter toString: anObject) ]
]

{ #category : #accessing }
RpWebSocket >> sendLock [
	^ sendLock ifNil: [ sendLock := Mutex new ]
]

{ #category : #'sending events' }
RpWebSocket >> sendErrorMessage: message [
	self sendErrorMessage: message type: 'general'
]

{ #category : #'sending events' }
RpWebSocket >> sendErrorMessage: message type: failureType [
	self sendErrorMessage: message type: failureType code: 0
]

{ #category : #'sending events' }
RpWebSocket >> sendErrorMessage: message type: failureType code: failureCode [
	self sendErrorMessage: message type: failureType code: failureCode otherData: nil
]

{ #category : #'sending events' }
RpWebSocket >> sendErrorMessage: message type: failureType code: failureCode otherData: otherData [
	| error |
	error := RpError code: failureCode type: failureType message: message.
	error otherData: otherData.
	self sendError: error
]

{ #category : #'sending events' }
RpWebSocket >> sendPublish: replyDict to: address [
	| jsonDict |
	jsonDict := {'type'->'publish'. 'address'->address} asDictionary.
	jsonDict at: 'body' put: replyDict asDictionary.
	self sendJson: jsonDict.
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
