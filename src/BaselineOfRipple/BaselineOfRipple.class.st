Class {
	#name : #BaselineOfRipple,
	#superclass : #BaselineOf,
	#category : #'BaselineOfRipple'
}

{ #category : #baselines }
BaselineOfRipple >> baseline: spec [
	<baseline>
	spec for: #common do: [
		"External Dependencies"
		self neoJson: spec.
		self zincHttp: spec.
		self teapot: spec.

		"Packages"
		spec
			package: 'Ripple-Core'
			with: [ spec requires: #('NeoJSON' 'ZincHTTPComponents' 'Teapot') ].
		spec
			package: 'Ripple-Core-Tests'
			with: [ spec requires: #('Ripple-Core') ].

		"Groups"
		spec
			group: 'Core' with: #('Ripple-Core');
			group: 'Tests' with: #('Ripple-Core' 'Ripple-Core-Tests');
			group: 'default' with: #('Core' 'Tests') ]
]

{ #category : #'external projects' }
BaselineOfRipple >> neoJson: spec [
	spec
		baseline: 'NeoJSON'
		with: [ spec repository: 'github://svenvc/NeoJSON/repository' ];
		import: 'NeoJSON'
]

{ #category : #'external projects' }
BaselineOfRipple >> teapot: spec [
	spec
		baseline: 'Teapot'
		with: [
			spec
				repository: 'github://zeroflag/Teapot:master/source';
				loads: #('Deployment') ];
		import: 'Teapot'
]

{ #category : #'external projects' }
BaselineOfRipple >> zincHttp: spec [
	spec
		baseline: 'ZincHTTPComponents'
		with: [
			spec
				repository: 'github://svenvc/zinc:83bb2cf95016cdc75cde3797b446f97b68b4780d/repository'; "The commit when Pharo 1.4 CI added & passed"
				loads: #('WebSocket') ];
		import: 'ZincHTTPComponents'
]
