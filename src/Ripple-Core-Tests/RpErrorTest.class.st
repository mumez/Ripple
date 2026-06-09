Class {
	#name : #RpErrorTest,
	#superclass : #TestCase,
	#category : #'Ripple-Core-Tests'
}

{ #category : #tests }
RpErrorTest >> testForbiddenAttributes [
	| error |
	error := RpError forbidden.
	self assert: error code equals: 403.
	self assert: error type equals: 'Forbidden'
]

{ #category : #tests }
RpErrorTest >> testNoSessionAttributes [
	| error |
	error := RpError noSession.
	self assert: error code equals: 404.
	self assert: error type equals: 'NoSession'
]

{ #category : #tests }
RpErrorTest >> testHandlerErrorAttributes [
	| error |
	error := RpError handlerError: 'boom'.
	self assert: error code equals: 500.
	self assert: error type equals: 'HandlerError'.
	self assert: error messageText equals: 'boom'
]

{ #category : #tests }
RpErrorTest >> testApplicationDefaultMessageText [
	| error |
	error := RpError application.
	self assert: error code equals: 10000.
	self assert: error type equals: 'application'.
	self assert: error messageText equals: ''
]

{ #category : #tests }
RpErrorTest >> testApplicationWithMessage [
	| error |
	error := RpError application: 'some error'.
	self assert: error code equals: 10000.
	self assert: error type equals: 'application'.
	self assert: error messageText equals: 'some error'
]

{ #category : #tests }
RpErrorTest >> testHandlerErrorFromException [
	| error |
	error := RpError handlerErrorFrom: (Error new messageText: 'original').
	self assert: error messageText equals: 'original'
]

{ #category : #tests }
RpErrorTest >> testAsJsonRequiredFields [
	| json |
	json := (RpError general: 'test') asJson.
	self assert: (json at: 'type') equals: 'err'.
	self assert: (json includesKey: 'failureCode').
	self assert: (json includesKey: 'failureType').
	self assert: (json includesKey: 'message')
]

{ #category : #tests }
RpErrorTest >> testAsJsonOtherDataIncluded [
	| error json |
	error := RpError application: 'test'.
	error otherData: (Dictionary new at: 'key' put: 'value'; yourself).
	json := error asJson.
	self assert: (json includesKey: 'data').
	self assert: ((json at: 'data') at: 'key') equals: 'value'
]

{ #category : #tests }
RpErrorTest >> testAsJsonNoDataKeyWhenOtherDataNil [
	| json |
	json := (RpError application: 'test') asJson.
	self deny: (json includesKey: 'data')
]

{ #category : #tests }
RpErrorTest >> testIsSubclassOfError [
	self assert: RpError superclass equals: Error
]
