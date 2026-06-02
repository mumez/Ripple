Class {
	#name : #RpLocalLogger,
	#superclass : #Object,
	#instVars : [
		'logLevel'
	],
	#classInstVars : [
		'defaultLogLevel'
	],
	#category : #'Ripple-Core'
}

{ #category : #accessing }
RpLocalLogger class >> defaultLogLevel [
	^defaultLogLevel ifNil: [ defaultLogLevel := 2]
]

{ #category : #accessing }
RpLocalLogger class >> defaultLogLevel: anInteger [
	^defaultLogLevel := anInteger
]

{ #category : #'class initialization' }
RpLocalLogger class >> initialize [
	defaultLogLevel := nil
]

{ #category : #actions }
RpLocalLogger >> debug: record [
	"Use Nagare-logger for production"
	self shouldLogDebug ifFalse: [ ^self ].
	self log: record tag: 'DEBUG'
]

{ #category : #actions }
RpLocalLogger >> error: record [
	"Use Nagare-logger for production"
	self shouldLogError ifFalse: [ ^self ].
	self log: record tag: 'ERROR'
]

{ #category : #actions }
RpLocalLogger >> info: record [
	"Use Nagare-logger for production"
	self shouldLogInfo ifFalse: [ ^self ].
	self log: record tag: 'INFO'
]

{ #category : #'initialize-release' }
RpLocalLogger >> initialize [
	logLevel := nil
]

{ #category : #acccessing }
RpLocalLogger >> isDebugging [
	^self logLevel > 0
]

{ #category : #acccessing }
RpLocalLogger >> isDebugging: aBoolean [
	| level |
	level := aBoolean ifTrue: [self defaultLogLevel] ifFalse: [0].
	self logLevel: level
]

{ #category : #private }
RpLocalLogger >> log: record tag: tagString [
	Transcript cr; show: tagString, ':', record asString
]

{ #category : #acccessing }
RpLocalLogger >> logLevel [
	^logLevel ifNil: [logLevel := self class defaultLogLevel ]
]

{ #category : #acccessing }
RpLocalLogger >> logLevel: anInteger [
	logLevel := anInteger
]

{ #category : #testing }
RpLocalLogger >> shouldLogDebug [
	^self logLevel >= 3
]

{ #category : #testing }
RpLocalLogger >> shouldLogError [
	^self logLevel >= 1
]

{ #category : #testing }
RpLocalLogger >> shouldLogInfo [
	^self logLevel >= 4
]

{ #category : #testing }
RpLocalLogger >> shouldLogWarn [
	^self logLevel >= 2
]

{ #category : #actions }
RpLocalLogger >> warn: record [
	"Use Nagare-logger for production"
	self shouldLogWarn ifFalse: [ ^self ].
	self log: record tag: 'WARN'
]
