Class {
	#name : #RpError,
	#superclass : #Error,
	#instVars : [
		'code',
		'type',
		'otherData'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpError class >> code: aCode type: aType message: aMessage [
	^ self new
		code: aCode;
		type: aType;
		messageText: aMessage;
		yourself
]

{ #category : #'instance creation' }
RpError class >> application [
	^ self application: ''
]

{ #category : #'instance creation' }
RpError class >> application: aMessage [
	^ self application: aMessage code: 10000
]

{ #category : #'instance creation' }
RpError class >> application: aMessage code: aCode [
	^ self code: aCode type: 'application' message: aMessage
]

{ #category : #'instance creation' }
RpError class >> forbidden [
	^ self code: 403 type: 'Forbidden' message: 'Client publish is not allowed'
]

{ #category : #'instance creation' }
RpError class >> general: aMessage [
	^ self code: 0 type: 'general' message: aMessage
]

{ #category : #'instance creation' }
RpError class >> handlerError: aMessage [
	^ self code: 500 type: 'HandlerError' message: aMessage
]

{ #category : #'instance creation' }
RpError class >> handlerErrorFrom: anException [
	^ self handlerError: anException messageText
]

{ #category : #'instance creation' }
RpError class >> noSession [
	^ self code: 404 type: 'NoSession' message: 'Session not found'
]

{ #category : #converting }
RpError >> asJson [
	| dict |
	dict := {
		'type' -> 'err'.
		'failureCode' -> self code.
		'failureType' -> self type.
		'message' -> self messageText } asDictionary.
	self otherData ifNotNil: [ :data | dict at: 'data' put: data ].
	^ dict
]

{ #category : #accessing }
RpError >> code [
	^ code
]

{ #category : #accessing }
RpError >> code: anInteger [
	code := anInteger
]

{ #category : #accessing }
RpError >> otherData [
	^ otherData
]

{ #category : #accessing }
RpError >> otherData: anObject [
	otherData := anObject
]

{ #category : #accessing }
RpError >> type [
	^ type
]

{ #category : #accessing }
RpError >> type: aString [
	type := aString
]
