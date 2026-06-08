Class {
	#name : #RpRoomSettings,
	#superclass : #Object,
	#instVars : [
		'allowClientPublish'
	],
	#category : #'Ripple-Core'
}

{ #category : #accessing }
RpRoomSettings >> allowClientPublish [
	^ allowClientPublish ifNil: [ false ]
]

{ #category : #accessing }
RpRoomSettings >> allowClientPublish: aBoolean [
	allowClientPublish := aBoolean
]
