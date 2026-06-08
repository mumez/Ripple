Class {
	#name : 'RpBaseSettings',
	#superclass : 'Object',
	#instVars : [
		'settingsDict'
	],
	#classInstVars : [
		'default'
	],
	#category : 'Ripple-Core',
	#package : 'Ripple-Core'
}

{ #category : 'instance creation' }
RpBaseSettings class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
RpBaseSettings class >> defaultCopied [
	^ self new initFrom: self default
]

{ #category : 'class initialization' }
RpBaseSettings class >> initialize [
	default := nil
]

{ #category : 'converting' }
RpBaseSettings >> asDictionary [
	self ensureDefinedKeys.
	^ (self keys collect: [ :each | each -> (self at: each) ]) asDictionary
]

{ #category : 'actions-dictionary' }
RpBaseSettings >> at: key [
	^ self settingsDict at: key
]

{ #category : 'actions-dictionary' }
RpBaseSettings >> at: key fallback: anArray [
	^ self at: key ifAbsentPut: [
		| envKey envDefault |
		envKey := anArray first.
		envDefault := anArray last.
		self envAt: envKey ifAbsent: [ envDefault ] ]
]

{ #category : 'actions-dictionary' }
RpBaseSettings >> at: key fallback: anArray type: aClass [
	| rawValue |
	rawValue := self at: key fallback: anArray.
	^ rawValue ifNotNil: [ aClass readFrom: rawValue asString ]
]

{ #category : 'actions-dictionary' }
RpBaseSettings >> at: key ifAbsent: aBlock [
	^ self settingsDict at: key ifAbsent: aBlock
]

{ #category : 'actions-dictionary' }
RpBaseSettings >> at: key ifAbsentPut: aBlock [
	^ self settingsDict at: key ifAbsentPut: aBlock
]

{ #category : 'actions-dictionary' }
RpBaseSettings >> at: key put: value [
	^ self settingsDict at: key put: value
]

{ #category : 'accessing-keys' }
RpBaseSettings >> definedSettingsKeys [
	^ #()
]

{ #category : 'private' }
RpBaseSettings >> ensureDefinedKeys [
	self definedSettingsKeys do: [ :each | self perform: each asSymbol ]
]

{ #category : 'private' }
RpBaseSettings >> envAt: key ifAbsent: aBlock [
	^ OSEnvironment current at: key ifAbsent: aBlock
]

{ #category : 'initialization' }
RpBaseSettings >> initFrom: otherSettings [
	self initialize.
	otherSettings settingsDict keysAndValuesDo: [ :k :v |
		self settingsDict at: k put: v ]
]

{ #category : 'initialization' }
RpBaseSettings >> initialize [
	settingsDict := nil
]

{ #category : 'actions-dictionary' }
RpBaseSettings >> keys [
	^ self settingsDict keys
]

{ #category : 'accessing-private' }
RpBaseSettings >> settingsDict [
	^ settingsDict ifNil: [ settingsDict := IdentityDictionary new ]
]

{ #category : 'accessing-private' }
RpBaseSettings >> settingsDict: anObject [
	settingsDict := anObject
]
