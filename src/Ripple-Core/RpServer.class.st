Class {
	#name : #RpServer,
	#superclass : #Object,
	#instVars : [
		'teapot'
	],
	#category : #'Ripple-Core'
}

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
	teapot := Teapot configure: {
			          (#port -> 8080).
			          (#debugMode -> true).
			          (#bindAddress -> #[ 127 0 0 1 ]) }.
	teapot
		serveStatic: '/assets' from: (FileLocator workingDirectory / 'assets').
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
