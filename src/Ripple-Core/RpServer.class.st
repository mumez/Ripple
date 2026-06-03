Class {
	#name : #RpServer,
	#superclass : #Object,
	#instVars : [
		'teapot',
		'settings'
	],
	#category : #'Ripple-Core'
}

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
RpServer >> initRoutes [

	self stop.
	teapot := Teapot configure: self settings teapotConfig.
	teapot
		serveStatic: '/assets' from: self settings assetsDirectory.
	teapot
		GET: '/hello' -> [ :req | 'hello' ];
		GET: '/ws/echo' -> [ :req |
				(ZnWebSocketDelegate
					 map: '/ws/echo'
					 to: ZnWebSocketEchoHandler new) handleRequest: req ].

	self addRoute: '/ws/event-bus' handler: RpWebSocketEventBusHandler shared
]

{ #category : #initialization }
RpServer >> initialize [
	super initialize.
	self initRoutes
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
	self teapot ifNotNil: [:tp | tp start]
]

{ #category : #actions }
RpServer >> stop [
	self teapot ifNotNil: [:tp | tp stop]
]

{ #category : #accessing }
RpServer >> teapot [
	^ teapot
]

{ #category : #accessing }
RpServer >> teapot: anObject [
	teapot := anObject
]
