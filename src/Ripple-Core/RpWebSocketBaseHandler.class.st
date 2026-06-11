"
I am a thread-safe connection registry that maps authentication tokens to RpRipple
session objects, managing the full lifecycle of WebSocket connections within a room.

Responsibility:
- I register and unregister WebSocket connections, maintaining a token-to-RpRipple dictionary
- I dispatch incoming raw messages to the appropriate ripple's handler
- I hold a back-reference to the RpRippleRoom that created me (rippleRoom)
- Subclasses extend dispatching behaviour (e.g. RpWebSocketEventBusHandler adds pub/sub)

Collaborators:
- RpRipple: per-session objects I create and manage
- RpRippleRoom: the room configuration that created this handler (via rippleRoom)
- Mutex: serialises all access to the ripples dictionary
- RpLocalLogger: reports warnings on connection errors

Public API and Key Messages:
- #register: / #unregister: - connection lifecycle management
- #rippleFor: aWebSocket - look up the RpRipple for a socket
- #runWith: aWebSocket - main loop; register, dispatch messages, unregister on error
- #rippleRoom / #rippleRoom: - the RpRippleRoom that owns this handler
- #rippleClass / #rippleClass: - the RpRipple subclass used for new sessions

Internal Representation:
- ripples - Dictionary mapping token strings to RpRipple instances
- lock - Mutex serialising all mutations to ripples
- rippleRoom - back-reference to the RpRippleRoom that created this handler
- rippleClass - class used to instantiate new RpRipple session objects

Implementation Points:
- Instances are cached by name in the class-side handlers Dictionary; use #handlerNamed: or #shared
- All mutations to ripples must be wrapped in lock critical: [...]
- #validateToken: currently accepts any non-empty string; override for real authentication
"
Class {
	#name : 'RpWebSocketBaseHandler',
	#superclass : 'Object',
	#instVars : [
		'lock',
		'logger',
		'ripples',
		'rippleClass',
		'rippleRoom',
		'settings'
	],
	#classInstVars : [
		'handlers'
	],
	#category : 'Ripple-Core',
	#package : 'Ripple-Core'
}

{ #category : 'accessing' }
RpWebSocketBaseHandler class >> handlerNamed: key [
	^ self handlers at: key ifAbsentPut: [ self new ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler class >> handlers [

	^ handlers ifNil: [ handlers := Dictionary new ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler class >> handlers: anObject [

	handlers := anObject
]

{ #category : 'class initialization' }
RpWebSocketBaseHandler class >> initialize [
	handlers := Dictionary new
]

{ #category : 'instance creation' }
RpWebSocketBaseHandler class >> shared [
	^ self handlerNamed: #shared
]

{ #category : 'defaults' }
RpWebSocketBaseHandler >> defaultLogger [
	^RpLocalLogger new
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> dispatchMessage: rawMessage with: webSocket [
	self distributeMessage: rawMessage
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> distributeMessage: message [
	lock
		critical: [
			self webSockets valuesDo: [ :each |
				[ each sendMessage: message ]
					on: NetworkError
					do: [ :exception |
						self logger
							warn:
								{(self className).
								#WebSocketDistributeMessage.
								(exception printString)} ] ] ]
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> handleMessage: rawMessage with: webSocket [
	(self rippleFor: webSocket) ifNil: [
		self logger warn: { self className. #NoSuchRipple. rawMessage}.
		^self
	 ].
	self dispatchMessage: rawMessage with: webSocket
]

{ #category : 'initialize-release' }
RpWebSocketBaseHandler >> initialize [
	ripples := Dictionary new.
	lock := Mutex new
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> lock [
	^ lock
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> logger [

	^ logger ifNil: [ logger := self defaultLogger ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> logger: anObject [

	logger := anObject
]

{ #category : 'registering' }
RpWebSocketBaseHandler >> register: clientWebSocket [

	lock critical: [
		| token |
		token := clientWebSocket token.
		(self validateToken: token) ifTrue: [
			self ripples at: token put: (self rippleClass on: clientWebSocket) ] ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleClass [
	^ rippleClass ifNil: [ rippleClass := RpRipple ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleClass: aClass [
	rippleClass := aClass
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleRoom [
	^ rippleRoom
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleRoom: anRpRippleRoom [
	rippleRoom := anRpRippleRoom
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleFor: webSocket [
	^ self ripples at: webSocket token ifAbsent: [  ]

]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> ripples [

	^ ripples
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> ripples: anObject [

	ripples := anObject
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> runWith: webSocket [
	[ self register: webSocket.
		webSocket runWith: [ :rawMessage | self handleMessage: rawMessage with: webSocket ] ]
		on: NetworkError, PrimitiveFailed
		do: [:ex |
			self logger warn: {'WebSocket registration failed'. webSocket identityHash. ex printString}.
			self unregister: webSocket ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> settings [
	settings ifNil: [ settings := RpBaseSettings defaultCopied ].
	^ settings
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> settings: anRpSettings [
	settings := anRpSettings
]

{ #category : 'registering' }
RpWebSocketBaseHandler >> unregister: clientWebSocket [
	lock
		critical: [
			| ripple |
			ripple := self ripples removeKey: clientWebSocket token ifAbsent: [ nil ].
			ripple ifNotNil: [ ripple unregistered ] ]
]

{ #category : 'private' }
RpWebSocketBaseHandler >> validateToken: aToken [
	aToken isEmptyOrNil ifTrue: [ ^ false ].

	^ true
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> webSockets [
	^ self ripples collect: [ :each | each webSocket ]
]
