Class {
	#name : 'RpServerSettings',
	#superclass : 'RpBaseSettings',
	#classInstVars : [],
	#category : 'Ripple-Core',
	#package : 'Ripple-Core'
}

{ #category : 'accessing' }
RpServerSettings >> assetsDir [
	^ self at: #assetsDir fallback: {
		'PHARO_RIPPLE_ASSETS_DIR'.
		(FileLocator workingDirectory / 'assets') fullName }
]

{ #category : 'accessing' }
RpServerSettings >> assetsDir: aString [
	self at: #assetsDir put: aString
]

{ #category : 'accessing' }
RpServerSettings >> assetsDirectory [
	^ self assetsDir asFileReference
]

{ #category : 'accessing' }
RpServerSettings >> bindAddress [
	^ self at: #bindAddress ifAbsentPut: [
		| env |
		env := self envAt: 'PHARO_RIPPLE_BIND_ADDRESS' ifAbsent: [ '127.0.0.1' ].
		(env substrings: '.') collect: [ :each | each asInteger ] as: ByteArray ]
]

{ #category : 'accessing' }
RpServerSettings >> bindAddress: aByteArray [
	self at: #bindAddress put: aByteArray
]

{ #category : 'accessing' }
RpServerSettings >> debugMode [
	^ self at: #debugMode ifAbsentPut: [
		| env |
		env := self envAt: 'PHARO_RIPPLE_DEBUG_MODE' ifAbsent: [ 'false' ].
		env = 'true' ]
]

{ #category : 'accessing' }
RpServerSettings >> debugMode: aBoolean [
	self at: #debugMode put: aBoolean
]

{ #category : 'accessing' }
RpServerSettings >> defaultOutput [
	^ self at: #defaultOutput ifAbsentPut: [ #json ]
]

{ #category : 'accessing' }
RpServerSettings >> defaultOutput: aSymbol [
	self at: #defaultOutput put: aSymbol
]

{ #category : 'accessing-keys' }
RpServerSettings >> definedSettingsKeys [
	^ #(#defaultOutput #port #debugMode #bindAddress #assetsDir)
]

{ #category : 'accessing' }
RpServerSettings >> port [
	^ self at: #port fallback: { 'PHARO_RIPPLE_PORT'. 8080 } type: Integer
]

{ #category : 'accessing' }
RpServerSettings >> port: aNumber [
	self at: #port put: aNumber
]

{ #category : 'converting' }
RpServerSettings >> teapotConfig [
	^ self teapotConfigKeys inject: Dictionary new into: [ :dict :key |
		dict at: key put: (self perform: key);
		yourself ]
]

{ #category : 'accessing-keys' }
RpServerSettings >> teapotConfigKeys [
	^ #(#defaultOutput #port #debugMode #bindAddress)
]
