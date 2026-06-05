Class {
	#name : #RpSettings,
	#superclass : #Object,
	#instVars : [
		'settingsDict'
	],
	#classInstVars : [
		'default'
	],
	#category : #'Ripple-Core'
}

{ #category : #'instance creation' }
RpSettings class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : #'instance creation' }
RpSettings class >> defaultCopied [
	^ self new initFrom: self default
]

{ #category : #'class initialization' }
RpSettings class >> initialize [
	super initialize.
	default := nil
]

{ #category : #converting }
RpSettings >> asDictionary [
	self ensureDefinedKeys.
	^ (self keys collect: [ :each | each -> (self at: each) ]) asDictionary
]

{ #category : #accessing }
RpSettings >> allowClientPublish [
	^ self at: #allowClientPublish ifAbsentPut: [ false ]
]

{ #category : #accessing }
RpSettings >> allowClientPublish: aBoolean [
	self at: #allowClientPublish put: aBoolean
]

{ #category : #accessing }
RpSettings >> assetsDir [
	^ self at: #assetsDir fallback: {
		'PHARO_RIPPLE_ASSETS_DIR'.
		(FileLocator workingDirectory / 'assets') fullName }
]

{ #category : #accessing }
RpSettings >> assetsDir: aString [
	self at: #assetsDir put: aString
]

{ #category : #accessing }
RpSettings >> assetsDirectory [
	^ self assetsDir asFileReference
]

{ #category : #'actions-dictionary' }
RpSettings >> at: key [
	^ self settingsDict at: key
]

{ #category : #'actions-dictionary' }
RpSettings >> at: key fallback: anArray [
	^ self at: key ifAbsentPut: [
		| envKey envDefault |
		envKey := anArray first.
		envDefault := anArray last.
		self envAt: envKey ifAbsent: [ envDefault ] ]
]

{ #category : #'actions-dictionary' }
RpSettings >> at: key fallback: anArray type: aClass [
	| rawValue |
	rawValue := self at: key fallback: anArray.
	^ rawValue ifNotNil: [ aClass readFrom: rawValue asString ]
]

{ #category : #'actions-dictionary' }
RpSettings >> at: key ifAbsent: aBlock [
	^ self settingsDict at: key ifAbsent: aBlock
]

{ #category : #'actions-dictionary' }
RpSettings >> at: key ifAbsentPut: aBlock [
	^ self settingsDict at: key ifAbsentPut: aBlock
]

{ #category : #'actions-dictionary' }
RpSettings >> at: key put: value [
	^ self settingsDict at: key put: value
]

{ #category : #accessing }
RpSettings >> bindAddress [
	^ self at: #bindAddress ifAbsentPut: [
		| env |
		env := self envAt: 'PHARO_RIPPLE_BIND_ADDRESS' ifAbsent: [ '127.0.0.1' ].
		(env substrings: '.') collect: [ :each | each asInteger ] as: ByteArray ]
]

{ #category : #accessing }
RpSettings >> bindAddress: aByteArray [
	self at: #bindAddress put: aByteArray
]

{ #category : #accessing }
RpSettings >> debugMode [
	^ self at: #debugMode ifAbsentPut: [
		| env |
		env := self envAt: 'PHARO_RIPPLE_DEBUG_MODE' ifAbsent: [ 'false' ].
		env = 'true' ]
]

{ #category : #accessing }
RpSettings >> debugMode: aBoolean [
	self at: #debugMode put: aBoolean
]

{ #category : #accessing }
RpSettings >> defaultOutput [
	^ self at: #defaultOutput ifAbsentPut: [ #json ]
]

{ #category : #accessing }
RpSettings >> defaultOutput: aSymbol [
	self at: #defaultOutput put: aSymbol
]

{ #category : #'accessing-keys' }
RpSettings >> definedSettingsKeys [
	^ #(#defaultOutput #port #debugMode #bindAddress #assetsDir #allowClientPublish)
]

{ #category : #private }
RpSettings >> ensureDefinedKeys [
	self definedSettingsKeys do: [ :each | self perform: each asSymbol ]
]

{ #category : #private }
RpSettings >> envAt: key ifAbsent: aBlock [
	^ OSEnvironment current at: key ifAbsent: aBlock
]

{ #category : #initialization }
RpSettings >> initFrom: otherSettings [
	self initialize.
	otherSettings settingsDict keysAndValuesDo: [ :k :v |
		self settingsDict at: k put: v ]
]

{ #category : #initialization }
RpSettings >> initialize [
	settingsDict := nil
]

{ #category : #'actions-dictionary' }
RpSettings >> keys [
	^ self settingsDict keys
]

{ #category : #accessing }
RpSettings >> port [
	^ self at: #port fallback: { 'PHARO_RIPPLE_PORT'. 8080 } type: Integer
]

{ #category : #accessing }
RpSettings >> port: aNumber [
	self at: #port put: aNumber
]

{ #category : #'accessing-private' }
RpSettings >> settingsDict [
	^ settingsDict ifNil: [ settingsDict := IdentityDictionary new ]
]

{ #category : #'accessing-private' }
RpSettings >> settingsDict: anObject [
	settingsDict := anObject
]

{ #category : #converting }
RpSettings >> teapotConfig [
	^ self teapotConfigKeys inject: Dictionary new into: [ :dict :key |
		dict at: key put: (self perform: key);
		yourself ]
]

{ #category : #'accessing-keys' }
RpSettings >> teapotConfigKeys [
	^ #(#defaultOutput #port #debugMode #bindAddress)
]
