Class {
	#name : #RpServer,
	#superclass : #Object,
	#instVars : [
		'teapot',
		'settings'
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
RpServer class >> restart [
	<script>
	self default stop.
	self default: nil.
	self default start
]

{ #category : #'system startup' }
RpServer class >> startUp: isImageStarting [
	isImageStarting ifFalse: [ ^ self ].
	default ifNotNil: [ default stop ].
	default := nil.
	Smalltalk session addDeferredStartupAction: [ self default ]
]

{ #category : #routing }
RpServer >> addDefaultRoutes [
	self teapot serveStatic: '/assets' from: self settings assetsDirectory
]

{ #category : #routing }
RpServer >> addRoom: aRippleRoom [
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
	^ settings ifNil: [ settings := RpSettings defaultCopied ]
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
