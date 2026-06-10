Class {
	#name : #RpUnregisterTrackingRipple,
	#superclass : #RpRipple,
	#instVars : [
		'wasUnregistered'
	],
	#category : #'Ripple-Core-Tests'
}

{ #category : #testing }
RpUnregisterTrackingRipple class >> shouldAutoPutRoute [
	^ false
]

{ #category : #accessing }
RpUnregisterTrackingRipple class >> roomName [
	^ 'tracking-test'
]

{ #category : #testing }
RpUnregisterTrackingRipple >> wasUnregistered [
	^ wasUnregistered ifNil: [ false ]
]

{ #category : #lifecycle }
RpUnregisterTrackingRipple >> unregistered [
	wasUnregistered := true
]
