"
I am the HTTP/WebSocket server for a Ripple application, wrapping Teapot and managing
a collection of RpRippleRoom instances.

Responsibility:
- I create and hold the Teapot HTTP server, configured from RpServerSettings
- I register WebSocket routes by accepting RpRippleRoom objects via #addRoom:
- I serve static assets from the configured assets directory
- I register with Pharo's SessionManager to restart cleanly on image startup

Collaborators:
- Teapot: the underlying HTTP server I configure and delegate to
- RpRippleRoom: room objects I accept and whose routes I register
- RpServerSettings: configuration for port, bind address, debug mode, assets dir
- RpRipple: subclasses auto-register their rooms on image startup via #autoPutAllRoutesToDefaultServer

Public API and Key Messages:
- #start / #stop / #reset - lifecycle management
- #addRoom: aRippleRoom - register a room and its WebSocket route
- #addRoomOf: aRippleClass - convenience; creates and registers aRippleClass room
- #roomNamed: aString - look up a registered room by name
- #settings - returns (lazily) the RpServerSettings for this server

Class-side:
- #default - returns (lazily creating and starting) the singleton server instance
- #resetDefault - stops, clears, and restarts the default server

Implementation Points:
- The class-side default is a class instance variable, not a true Singleton; use #default: to inject a test server
- On image startup, Teapot availability is checked before starting to allow headless images without HTTP
"
Class {
	#name : #RpServer,
	#superclass : #Object,
	#instVars : [
		'teapot',
		'settings',
		'roomsDict'
	],
	#classInstVars : [
		'default'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpServer class >> createStarted [
	| inst |
	inst := self new.
	inst start.
	^ inst
]

{ #category : #accessing }
RpServer class >> default [
	^ default ifNil: [ default := self createStarted ]
]

{ #category : #accessing }
RpServer class >> default: anRpServer [
	default := anRpServer
]

{ #category : #'class initialization' }
RpServer class >> initialize [
	SessionManager default registerUserClassNamed: self name
]

{ #category : #actions }
RpServer class >> resetDefault [
	<script>
	self default stop.
	self default: nil.
	^ self default start
]

{ #category : #'system startup' }
RpServer class >> startUp: isImageStarting [
	isImageStarting ifFalse: [ ^ self ].
	default ifNotNil: [ default stop ].
	default := nil.
	Smalltalk session addDeferredStartupAction: [
		(Smalltalk globals hasClassNamed: #Teapot) ifTrue: [
			self default.
			RpRipple autoPutAllRoutesToDefaultServer ] ]
]

{ #category : #routing }
RpServer >> addDefaultRoutes [
	self teapot serveStatic: '/assets' from: self settings assetsDirectory
]

{ #category : #routing }
RpServer >> addRoom: aRippleRoom [
	self roomsDict at: aRippleRoom name put: aRippleRoom.
	aRippleRoom addedTo: self
]

{ #category : #routing }
RpServer >> addRoomOf: aRippleClass [
	self addRoom: aRippleClass room
]

{ #category : #routing }
RpServer >> addRoute: path handler: aWebSocketEventHandler [
	self teapot
		GET: path -> [ :req |
				(RpWebSocketDelegate
					 map: path
					 to: aWebSocketEventHandler) handleRequest: req ]
]

{ #category : #initialization }
RpServer >> initTeapot [
	self teapot: (Teapot configure: self settings teapotConfig).
	self addDefaultRoutes
]

{ #category : #accessing }
RpServer >> settings [
	^ settings ifNil: [ settings := RpServerSettings defaultCopied ]
]

{ #category : #accessing }
RpServer >> settings: anRpSettings [
	settings := anRpSettings
]

{ #category : #actions }
RpServer >> start [
	self stop.
	self teapot start
]

{ #category : #actions }
RpServer >> stop [
	self teapot ifNotNil: [ :tp | tp stop ]
]

{ #category : #actions }
RpServer >> reset [
	self stop.
	self teapot: nil
]

{ #category : #accessing }
RpServer >> teapot [
	teapot ifNil: [ self initTeapot ].
	^ teapot
]

{ #category : #accessing }
RpServer >> teapot: anObject [
	teapot := anObject
]

{ #category : #'accessing-rooms' }
RpServer >> roomsDict [
	^ roomsDict ifNil: [ roomsDict := Dictionary new ]
]

{ #category : #'accessing-rooms' }
RpServer >> rooms [
	^ self roomsDict values
]

{ #category : #'accessing-rooms' }
RpServer >> roomNames [
	^ self roomsDict keys
]

{ #category : #'accessing-rooms' }
RpServer >> roomNamed: aString [
	^ self roomsDict at: aString ifAbsent: [ nil ]
]
