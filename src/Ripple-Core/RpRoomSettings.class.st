Class {
	#name : 'RpRoomSettings',
	#superclass : 'RpBaseSettings',
	#category : 'Ripple-Core',
	#package : 'Ripple-Core'
}

{ #category : 'accessing' }
RpRoomSettings >> allowClientPublish [
	^ self at: #allowClientPublish ifAbsentPut: [ false ]
]

{ #category : 'accessing' }
RpRoomSettings >> allowClientPublish: aBoolean [
	self at: #allowClientPublish put: aBoolean
]

{ #category : 'accessing-keys' }
RpRoomSettings >> definedSettingsKeys [
	^ #(#allowClientPublish)
]
