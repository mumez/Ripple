Class {
	#name : #RpMockServer,
	#superclass : #Object,
	#instVars : [
		'addedRoutes',
		'settings'
	],
	#category : #'Ripple-Core-Tests'
}

{ #category : #initialization }
RpMockServer >> initialize [
	addedRoutes := OrderedCollection new
]

{ #category : #routing }
RpMockServer >> addRoute: aPath handler: aHandler [
	aHandler settings: self settings.
	addedRoutes add: (Association key: aPath value: aHandler)
]

{ #category : #accessing }
RpMockServer >> settings [
	^ settings ifNil: [ settings := RpSettings defaultCopied ]
]

{ #category : #accessing }
RpMockServer >> addedRoutes [
	^ addedRoutes
]

{ #category : #accessing }
RpMockServer >> lastRoutePath [
	^ addedRoutes last key
]

{ #category : #accessing }
RpMockServer >> lastRouteHandler [
	^ addedRoutes last value
]

{ #category : #routing }
RpMockServer >> addRoom: aRippleRoom [
	aRippleRoom addedTo: self
]

{ #category : #routing }
RpMockServer >> addRoomOf: aRippleClass [
	self addRoom: aRippleClass room
]
