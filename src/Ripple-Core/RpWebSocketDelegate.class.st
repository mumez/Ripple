Class {
	#name : #RpWebSocketDelegate,
	#superclass : #ZnWebSocketDelegate,
	#category : #'Ripple-Core'
}

{ #category : #accessing }
RpWebSocketDelegate >> continuation [
	^ [ :webSocket | self handler runWith: webSocket ]
]

{ #category : #private }
RpWebSocketDelegate >> responseHeadersForKey: key [
	| headers |
	headers := super responseHeadersForKey: key.
	^ headers at: 'Sec-WebSocket-Protocol' put: 'ripple-st.0';
			yourself
]

{ #category : #responding }
RpWebSocketDelegate >> webSocketResponseForRequest: request [
	"Given a valid WebSocket setup request, return the matching server response"
	
	| acceptKey  |
	acceptKey := ZnWebSocketUtils handshake: (request headers at: 'Sec-WebSocket-Key').
	^ RpWebSocketResponse new
		statusLine: (ZnStatusLine code: 101);
		originalRequest: request;
		headers: (self responseHeadersForKey: acceptKey);
		continuation: self continuation;
		yourself
		
]
