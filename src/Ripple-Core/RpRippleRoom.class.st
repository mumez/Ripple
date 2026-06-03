Class {
	#name : #RpRippleRoom,
	#superclass : #Object,
	#instVars : [
		'name',
		'handler',
		'rippleClass'
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

{ #category : #routing }
RpRippleRoom >> addedTo: aRippleServer [
	aRippleServer addRoute: self route handler: self handler
]

{ #category : #private }
RpRippleRoom >> createHandler [
	| newHandler |
	newHandler := RpWebSocketEventBusHandler handlerNamed: self name.
	newHandler rippleClass: self rippleClass.
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

{ #category : #routing }
RpRippleRoom >> route [
	^ '/ws/', name
]
