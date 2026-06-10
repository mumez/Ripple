Class {
	#name : #RpRipple,
	#superclass : #Object,
	#instVars : [
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

{ #category : #'instance creation' }
RpRipple class >> room [
	^ RpRippleRoom name: self roomName rippleClass: self
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
		yourself
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
