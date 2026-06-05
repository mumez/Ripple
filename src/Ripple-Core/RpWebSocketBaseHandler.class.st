Class {
	#name : 'RpWebSocketBaseHandler',
	#superclass : 'Object',
	#instVars : [
		'lock',
		'logger',
		'ripples',
		'rippleClass',
		'server',
		'settings'
	],
	#classInstVars : [
		'handlers'
	],
	#category : 'Ripple-Core',
	#package : 'Ripple-Core'
}

{ #category : 'constants' }
RpWebSocketBaseHandler class >> clientHtml [
	^ '<!DOCTYPE html>
<meta charset="utf-8" />
<title>WebSocket Chatroom</title>

<script language="javascript" type="text/javascript">

  var wsUri = "ws://" + location.host + "/ws-chatroom?appKey=123123123";
  var websocket;
  var output, handleInput, messageInput, sendButton, closeButton;

  function init() {
    output = document.getElementById("output");
    handleInput = document.getElementById("handleInput");
    messageInput = document.getElementById("messageInput");
    sendButton = document.getElementById("sendButton");
    closeButton = document.getElementById("closeButton");
    handleInput.value = "user-" + (new Date()).getMilliseconds();
    messageInput.onkeyup = function (evt) { if (evt.keyCode == 13) sendChatMessage(evt) }
    sendButton.onclick = function (evt) { sendChatMessage(evt) };
    closeButton.onclick = function (evt) { closeChat(evt) };
    testWebSocket();
  }

  function testWebSocket() {
    writeToScreen(wsUri);
    websocket = new WebSocket(wsUri);
    websocket.onopen = function(evt) { onOpen(evt) };
    websocket.onclose = function(evt) { onClose(evt) };
    websocket.onmessage = function(evt) { onMessage(evt) };
    websocket.onerror = function(evt) { onError(evt) };
  }

  function onOpen(evt) {
    writeToScreen("CONNECTED");
    doSend("Hi there !");
  }

  function onClose(evt) {
    writeToScreen("DISCONNECTED");
  }

  function onMessage(evt) {
    writeToScreen(evt.data);
   }

  function onError(evt) {
    writeToScreen("<span style=''color: red''>ERROR:</span> " + evt.data);
  }

  function doSend(message) {
     websocket.send(handleInput.value + ">>" + message);
  }

  function writeToScreen(message) {
    var pre = document.createElement("p");
    pre.style.wordWrap = "break-word";
    pre.innerHTML = message;
    output.appendChild(pre);
  }

  function sendChatMessage(evt) {
    doSend(messageInput.value);
    messageInput.value = "";
  }

  function closeChat(evt) {
    doSend("Bye!");
    websocket.close();
  }

  window.addEventListener("load", init, false);

</script>

<h2>WebSocket Chatroom</h2>
<div>
Handle: <input id="handleInput" type="text"/>
Message: <input id="messageInput" type="text" size="64"/> 
<input id="sendButton" type="submit" value="Send"/>
<input id="closeButton" type="submit" value="Close"/>
</div>
<div id="output"></div>

</html> '

]

{ #category : 'accessing' }
RpWebSocketBaseHandler class >> handlerNamed: key [
	^ self handlers at: key ifAbsentPut: [ self new ] 
]

{ #category : 'accessing' }
RpWebSocketBaseHandler class >> handlers [

	^ handlers ifNil: [ handlers := Dictionary new ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler class >> handlers: anObject [

	handlers := anObject
]

{ #category : 'class initialization' }
RpWebSocketBaseHandler class >> initialize [
	handlers := Dictionary new
]

{ #category : 'instance creation' }
RpWebSocketBaseHandler class >> shared [
	^ self handlerNamed: #shared
]

{ #category : 'defaults' }
RpWebSocketBaseHandler >> defaultLogger [
	^RpLocalLogger new
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> dispatchMessage: rawMessage with: webSocket [
	self distributeMessage: rawMessage
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> distributeMessage: message [
	lock
		critical: [ 
			self webSockets values
				do: [ :each | 
					[ each sendMessage: message ]
						on: NetworkError
						do: [ :exception | 
							self logger
								warn:
									{(self className).
									#WebSocketDistributeMessage.
									(exception printString)} ] ] ]
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> handleMessage: rawMessage with: webSocket [
	(self rippleFor: webSocket) ifNil: [ 
		self logger warn: { self className. #NoSuchRipple. rawMessage}.
		^self
	 ].
	self dispatchMessage: rawMessage with: webSocket
]

{ #category : 'initialize-release' }
RpWebSocketBaseHandler >> initialize [
	ripples := Dictionary new.
	lock := Mutex new
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> lock [
	^ lock
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> logger [

	^ logger ifNil: [ logger := self defaultLogger ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> logger: anObject [

	logger := anObject
]

{ #category : 'registering' }
RpWebSocketBaseHandler >> register: clientWebSocket [

	lock critical: [
		| token |
		token := clientWebSocket token.
		(self validateToken: token) ifTrue: [
			self ripples at: token put: (self rippleClass on: clientWebSocket) ] ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleClass [
	^ rippleClass ifNil: [ rippleClass := RpRipple ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleClass: aClass [
	rippleClass := aClass
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> rippleFor: webSocket [
	^ self ripples at: webSocket token ifAbsent: [  ]
	
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> ripples [

	^ ripples
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> ripples: anObject [

	ripples := anObject
]

{ #category : 'handling' }
RpWebSocketBaseHandler >> runWith: webSocket [
	[ self register: webSocket.
		webSocket runWith: [ :rawMessage | self handleMessage: rawMessage with: webSocket ] ] 
		on: NetworkError, PrimitiveFailed  
		do: [:ex | 
			self logger warn: {'WebSocket registration failed'. webSocket identityHash. ex printString}.
			self unregister: webSocket ]
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> server [
	^ server
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> server: anRpServer [
	server := anRpServer
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> settings [
	settings ifNil: [ settings := (self server ifNotNil: [ :srv | srv settings ]) ifNil: [ RpSettings defaultCopied ] ].
	^ settings
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> settings: anRpSettings [
	settings := anRpSettings
]

{ #category : 'registering' }
RpWebSocketBaseHandler >> unregister: clientWebSocket [
	lock
		critical: [ 
			self ripples removeKey: clientWebSocket token ifAbsent: [  ] ]
]

{ #category : 'private' }
RpWebSocketBaseHandler >> validateToken: aToken [
	aToken isEmptyOrNil ifTrue: [ ^ false ].

	^ true
]

{ #category : 'accessing' }
RpWebSocketBaseHandler >> webSockets [
	^ self ripples collect: [ :each | each webSocket ]
]
