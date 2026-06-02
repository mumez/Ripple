Class {
	#name : #RpMessage,
	#superclass : #Object,
	#instVars : [
		'type',
		'address',
		'headers',
		'body',
		'correlationId'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpMessage class >> fromJsonString: jsonString [
	| json msg |
	json := NeoJSONReader fromString: jsonString asString.
	msg := self new.
	msg type: (json at: 'type' ifAbsent: [ nil ]).
	msg address: (json at: 'address' ifAbsent: [ '' ]).
	msg headers: (json at: 'headers' ifAbsent: [ Dictionary new ]).
	msg body: (json at: 'body' ifAbsent: [ nil ]).
	msg correlationId: (json at: 'correlationId' ifAbsent: [ nil ]).
	^ msg
]

{ #category : #accessing }
RpMessage >> address [
	^ address
]

{ #category : #accessing }
RpMessage >> address: anObject [
	address := anObject
]

{ #category : #accessing }
RpMessage >> body [
	^ body
]

{ #category : #accessing }
RpMessage >> body: anObject [
	body := anObject
]

{ #category : #accessing }
RpMessage >> correlationId [
	^ correlationId
]

{ #category : #accessing }
RpMessage >> correlationId: anObject [
	correlationId := anObject
]

{ #category : #accessing }
RpMessage >> headers [
	^ headers
]

{ #category : #accessing }
RpMessage >> headers: anObject [
	headers := anObject
]

{ #category : #testing }
RpMessage >> isPing [
	^ type = 'ping'
]

{ #category : #testing }
RpMessage >> isRegister [
	^ type = 'register'
]

{ #category : #testing }
RpMessage >> isRequest [
	^ type = 'request'
]

{ #category : #testing }
RpMessage >> isSend [
	^ type = 'send'
]

{ #category : #testing }
RpMessage >> isUnregister [
	^ type = 'unregister'
]

{ #category : #accessing }
RpMessage >> type [
	^ type
]

{ #category : #accessing }
RpMessage >> type: anObject [
	type := anObject
]
