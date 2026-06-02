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
		spec
			baseline: 'NeoJSON'
			with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
		spec
			baseline: 'ZincHTTPComponents'
			with: [
				spec
					repository: 'github://svenvc/zinc:v5/repository';
					loads: #('WebSocket') ].

		"Packages"
		spec
			package: 'Ripple-Core'
			with: [ spec requires: #('NeoJSON' 'ZincHTTPComponents') ].
		spec
			package: 'Ripple-Core-Tests'
			with: [ spec requires: #('Ripple-Core') ].

		"Groups"
		spec
			group: 'Core' with: #('Ripple-Core');
			group: 'Tests' with: #('Ripple-Core' 'Ripple-Core-Tests');
			group: 'default' with: #('Core' 'Tests') ]
]
