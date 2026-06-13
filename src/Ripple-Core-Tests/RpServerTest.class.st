Class {
	#name : #RpServerTest,
	#superclass : #TestCase,
	#category : #'Ripple-Core-Tests'
}

{ #category : #tests }
RpServerTest >> testRoomsDict [
	| server room |
	server := RpServer new.
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	server addRoom: room.
	self assert: (server roomsDict includesKey: 'test').
	self assert: (server roomsDict at: 'test') equals: room
]

{ #category : #tests }
RpServerTest >> testRooms [
	| server room1 room2 |
	server := RpServer new.
	room1 := RpRippleRoom name: 'test1' rippleClass: RpRipple.
	room2 := RpRippleRoom name: 'test2' rippleClass: RpRipple.
	server addRoom: room1.
	server addRoom: room2.
	self assert: server rooms size equals: 2.
	self assert: (server rooms includes: room1).
	self assert: (server rooms includes: room2)
]

{ #category : #tests }
RpServerTest >> testRoomNames [
	| server room1 room2 |
	server := RpServer new.
	room1 := RpRippleRoom name: 'test1' rippleClass: RpRipple.
	room2 := RpRippleRoom name: 'test2' rippleClass: RpRipple.
	server addRoom: room1.
	server addRoom: room2.
	self assert: server roomNames size equals: 2.
	self assert: (server roomNames includes: 'test1').
	self assert: (server roomNames includes: 'test2')
]

{ #category : #tests }
RpServerTest >> testRoomNamed [
	| server room |
	server := RpServer new.
	room := RpRippleRoom name: 'test' rippleClass: RpRipple.
	server addRoom: room.
	self assert: (server roomNamed: 'test') equals: room.
	self assert: (server roomNamed: 'unknown') isNil
]

{ #category : #tests }
RpServerTest >> testAddRoomOverwrites [
	| server room1 room2 |
	server := RpServer new.
	room1 := RpRippleRoom name: 'test' rippleClass: RpRipple.
	room2 := RpRippleRoom name: 'test' rippleClass: RpRipple.
	server addRoom: room1.
	server addRoom: room2.
	self assert: server rooms size equals: 1.
	self assert: (server roomNamed: 'test') equals: room2
]
