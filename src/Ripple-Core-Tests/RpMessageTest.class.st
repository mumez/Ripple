Class {
	#name : #RpMessageTest,
	#superclass : #TestCase,
	#category : #'Ripple-Core-Tests'
}

{ #category : #tests }
RpMessageTest >> testParsesAllFields [
	| msg |
	msg := RpMessage
		fromJsonString: '{"type":"request","address":"user.login","headers":{"locale":"ja"},"body":{"user":"alice"},"correlationId":"abc-123"}'.
	self assert: msg type equals: 'request'.
	self assert: msg address equals: 'user.login'.
	self assert: msg correlationId equals: 'abc-123'.
	self assert: (msg body at: 'user') equals: 'alice'.
	self assert: (msg headers at: 'locale') equals: 'ja'
]

{ #category : #tests }
RpMessageTest >> testParsesMinimalMessage [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"ping"}'.
	self assert: msg type equals: 'ping'.
	self assert: msg address equals: ''.
	self assert: msg correlationId isNil.
	self assert: msg body isNil
]

{ #category : #tests }
RpMessageTest >> testMissingTypeReturnsNilType [
	| msg |
	msg := RpMessage fromJsonString: '{"address":"a"}'.
	self assert: msg type isNil
]

{ #category : #tests }
RpMessageTest >> testIsRequest [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"request","address":"a","correlationId":"c1"}'.
	self assert: msg isRequest.
	self deny: msg isSend
]

{ #category : #tests }
RpMessageTest >> testIsSend [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"send","address":"a"}'.
	self assert: msg isSend.
	self deny: msg isRequest
]

{ #category : #tests }
RpMessageTest >> testIsPing [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"ping"}'.
	self assert: msg isPing.
	self deny: msg isRequest
]

{ #category : #tests }
RpMessageTest >> testIsRegister [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"register","address":"topic.x"}'.
	self assert: msg isRegister.
	self deny: msg isUnregister
]

{ #category : #tests }
RpMessageTest >> testIsPublish [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"publish","address":"topic.x"}'.
	self assert: msg isPublish.
	self deny: msg isRequest
]

{ #category : #tests }
RpMessageTest >> testIsUnregister [
	| msg |
	msg := RpMessage fromJsonString: '{"type":"unregister","address":"topic.x"}'.
	self assert: msg isUnregister.
	self deny: msg isRegister
]
