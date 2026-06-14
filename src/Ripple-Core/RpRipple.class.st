"
I represent a per-session WebSocket endpoint, wrapping an active connection
and providing the message-handling API for Ripple applications.

Responsibility:
- I hold the WebSocket connection for a single authenticated session (keyed by token)
- I delegate message handling to subclass hooks (#handleSend:, #handleRequest:)
- I provide access to the handler and room I belong to via #baseHandler and #room
- Subclasses define the room name and customize message handling behaviour

Collaborators:
- RpWebSocket: the underlying connection I wrap
- RpWebSocketBaseHandler: the handler managing all connections in my room (via #baseHandler)
- RpRippleRoom: the room configuration I belong to (via #room)

Public API and Key Messages:
- #handleSend: aMessage - override to handle incoming one-way messages
- #handleRequest: aMessage - override to handle request/reply messages
- #publish: jsonDict to: address - broadcast to all subscribers of address in this room
- #room - returns the RpRippleRoom this ripple belongs to
- #token - returns the session authentication token
- #unregistered - lifecycle hook called on disconnect; override for cleanup

Class-side:
- #roomName - subclass responsibility; defines the WebSocket path (e.g. '/ws/chat')
- #roomSettings - override to provide custom RpRoomSettings for this room
- #shouldAutoPutRoute - return false to exclude from automatic route registration (default: true)
- #autoPutAllRoutesToDefaultServer - registers all auto-route subclasses on image startup

Implementation Points:
- Network errors during send/publish increment errorCount; on reaching maxErrorCount the session is unregistered
- maxErrorCount is read from the room's RpRoomSettings (default: 5)
"
Class {
	#name : #RpRipple,
	#superclass : #Object,
	#instVars : [
		'errorCount',
		'webSocket'
	],
	#category : #'Ripple-Core'
}

{ #category : #actions }
RpRipple class >> autoPutAllRoutesToDefaultServer [
	<script>
	self allSubclasses
		select: [ :subclass | subclass shouldAutoPutRoute ]
		thenDo: [ :subclass | subclass putRouteToDefaultServer ]
]

{ #category : #actions }
RpRipple class >> putRouteTo: aRippleServer [
	aRippleServer addRoomOf: self
]

{ #category : #actions }
RpRipple class >> putRouteToDefaultServer [
	<script>
	self putRouteTo: RpServer default
]

{ #category : #testing }
RpRipple class >> shouldAutoPutRoute [
	^ true
]

{ #category : #accessing }
RpRipple class >> roomClass [
	^ RpRippleRoom
]

{ #category : #'instance creation' }
RpRipple class >> room [
	^ self roomClass name: self roomName rippleClass: self
]

{ #category : #accessing }
RpRipple class >> roomName [
	^ self subclassResponsibility
]

{ #category : #accessing }
RpRipple class >> roomSettings [
	"Override to provide custom room settings"
	^ RpRoomSettings defaultCopied
]

{ #category : #'instance creation' }
RpRipple class >> on: aWebSocket [
	^ self new
		webSocket: aWebSocket;
		resetErrorCount;
		yourself
]

{ #category : #'message handling' }
RpRipple >> handleNetworkError: anException during: anOperation [
	errorCount := self errorCount + 1.
	self logger
		warn: {
			self class name.
			anOperation.
			'errorCount: ', self errorCount printString.
			anException description }.
	self errorCount >= self maxErrorCount
		ifTrue: [
			self logger warn: { self class name. #maxErrorCountReached. 'unregistering'. self token }.
			self unregister ]
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

{ #category : #actions }
RpRipple >> publish: jsonDict to: address [
	[ ^ self webSocket publish: jsonDict to: address ]
		on: NetworkError
		do: [ :ex | self handleNetworkError: ex during: #publish ]
]

{ #category : #actions }
RpRipple >> send: jsonDict to: address [
	[ ^ self webSocket send: jsonDict to: address ]
		on: NetworkError
		do: [ :ex | self handleNetworkError: ex during: #send ]
]

{ #category : #accessing }
RpRipple >> errorCount [
	^ errorCount
]

{ #category : #accessing }
RpRipple >> logger [
	^ self baseHandler logger
]

{ #category : #accessing }
RpRipple >> maxErrorCount [
	^ self baseHandler settings maxErrorCount
]

{ #category : #private }
RpRipple >> resetErrorCount [
	errorCount := 0
]

{ #category : #accessing }
RpRipple >> baseHandler [
	^ self webSocket baseHandler
]

{ #category : #accessing }
RpRipple >> room [
	^ self baseHandler rippleRoom
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

{ #category : #'lifecycle' }
RpRipple >> unregistered [
	"Hook called when this ripple is unregistered from the handler. Subclasses can override."
]

{ #category : #'lifecycle' }
RpRipple >> unregister [
	self baseHandler unregister: self webSocket
]
