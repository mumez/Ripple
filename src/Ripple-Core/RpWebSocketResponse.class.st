Class {
	#name : #RpWebSocketResponse,
	#superclass : #ZnWebSocketResponse,
	#instVars : [
		'originalRequest'
	],
	#category : #'Ripple-Core'
}

{ #category : #accessing }
RpWebSocketResponse >> originalRequest [
	^ originalRequest
]

{ #category : #accessing }
RpWebSocketResponse >> originalRequest: anObject [
	originalRequest := anObject
]

{ #category : #accessing }
RpWebSocketResponse >> requestHeaders [
	^ self originalRequest headers
]

{ #category : #accessing }
RpWebSocketResponse >> requestUri [
	^ self originalRequest uri
]

{ #category : #handling }
RpWebSocketResponse >> useConnection: connection [	
	| webSocket  |
	webSocket := RpWebSocket onStream: connection.
	webSocket originalResponse: self.
	self continuation value: webSocket
]
