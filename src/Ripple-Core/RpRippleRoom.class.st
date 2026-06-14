"
I represent a WebSocket room configuration that binds a URL path, a ripple class,
and an event bus handler into a single deployable unit.

Responsibility:
- I create and own the RpWebSocketEventBusHandler for my room
- I register my WebSocket route (e.g. '/ws/chat') with an RpServer
- I provide room-level publish via #publish:to:, broadcasting to all subscribers in the room
- I carry the settings that govern room behaviour (e.g. allowClientPublish)

Collaborators:
- RpWebSocketEventBusHandler: the handler I create and configure; holds all active connections
- RpRipple (subclasses): the session class instantiated for each connection in this room
- RpServer: the server I register my route with via #addedTo:
- RpRoomSettings: room-level configuration I supply to the handler

Public API and Key Messages:
- #publish: jsonDict to: address - broadcast a message to all subscribers of address in this room
- #handler - returns (lazily creating) the event bus handler for this room
- #route - the WebSocket path string (e.g. '/ws/chat')
- #addedTo: aServer - register this room's route and handler with the given server

Class-side:
- #name: aName rippleClass: aRippleClass - primary factory

Internal Representation:
- name - the path segment used to build the WebSocket route
- handler - the lazily created RpWebSocketEventBusHandler (back-references this room via rippleRoom)
- rippleClass - the RpRipple subclass used to create per-session objects
- settings - RpRoomSettings controlling room behaviour
"
Class {
	#name : #RpRippleRoom,
	#superclass : #Object,
	#instVars : [
		'name',
		'handler',
		'rippleClass',
		'settings'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpRippleRoom class >> name: aName rippleClass: aRippleClass [
	^ self new
		name: aName;
		rippleClass: aRippleClass;
		yourself
]

{ #category : #actions }
RpRippleRoom >> publish: jsonDict to: address [
	^ self handler publishMessage: jsonDict to: address
]

{ #category : #routing }
RpRippleRoom >> addedTo: aRippleServer [
	aRippleServer addRoute: self route handler: self handler
]

{ #category : #private }
RpRippleRoom >> createHandler [
	| newHandler |
	newHandler := RpWebSocketEventBusHandler handlerNamed: self name.
	newHandler rippleClass: self rippleClass.
	newHandler settings: self settings.
	newHandler rippleRoom: self.
	^ newHandler
]

{ #category : #accessing }
RpRippleRoom >> handler [
	^ handler ifNil: [ handler := self createHandler ]
]

{ #category : #accessing }
RpRippleRoom >> handler: anObject [
	handler := anObject
]

{ #category : #accessing }
RpRippleRoom >> name [
	^ name
]

{ #category : #accessing }
RpRippleRoom >> name: anObject [
	name := anObject
]

{ #category : #accessing }
RpRippleRoom >> rippleClass [
	^ rippleClass ifNil: [ rippleClass := RpRipple ]
]

{ #category : #accessing }
RpRippleRoom >> rippleClass: aClass [
	rippleClass := aClass
]

{ #category : #'token-validation' }
RpRippleRoom >> validateToken: aToken [
	aToken isEmptyOrNil ifTrue: [ ^ false ].
	^ true
]

{ #category : #accessing }
RpRippleRoom >> settings [
	^ settings ifNil: [ settings := self rippleClass roomSettings ]
]

{ #category : #accessing }
RpRippleRoom >> settings: anRpRoomSettings [
	settings := anRpRoomSettings
]

{ #category : #accessing }
RpRippleRoom >> ripples [
	^ self handler ripples
]

{ #category : #routing }
RpRippleRoom >> route [
	^ '/ws/', self name
]
