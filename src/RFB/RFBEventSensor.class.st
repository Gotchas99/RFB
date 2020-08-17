"
I am a kind of EventSensor that forwards mouse events and cursor change requests to the active RFBServer.  I replace the regular Sensor whenever the RFBServer is running (and remove myself whenever the RFBServer is shut down).
"
Class {
	#name : #RFBEventSensor,
	#superclass : #InputEventSensor,
	#instVars : [
		'rfbServer',
		'eventMutex'
	],
	#category : #'RFB-Server'
}

{ #category : #copying }
RFBEventSensor >> copyFrom: other [
	"Initialise the state of the receiver based on some other EventSensor object."

	1 to: other class instSize do: [:i | self instVarAt: i put: (other instVarAt: i)]
]

{ #category : #copying }
RFBEventSensor >> copyTo: other [
	"Copy the state of the receiver into another EventSensor object."

	1 to: other class instSize do: [:i | other instVarAt: i put: (self instVarAt: i)].
	^other
]

{ #category : #cursor }
RFBEventSensor >> currentCursor: newCursor [
	"Update the current cursor position.  Propagate the new cursor position to all remote viewers."

	super currentCursor: newCursor.
	rfbServer isNil ifFalse: [rfbServer currentCursor: newCursor]
]

{ #category : #'initialise-release' }
RFBEventSensor >> initialize [
	"Initialize the receiver."

	super initialize.
	eventMutex := Semaphore forMutualExclusion
]

{ #category : #private }
RFBEventSensor >> processEvent: evt [
	"Process a mouse event caused by cursor motion.  Propagate the new mouse position to all remote viewers."

	| prev result |
	prev := mousePosition.
	result := super processEvent: evt.
	(rfbServer notNil and: [ prev ~= mousePosition ])
		ifTrue: [ rfbServer mousePosition: mousePosition ].
	^ result
]

{ #category : #accessing }
RFBEventSensor >> rfbServer: server [
	"Set the receiver's RFBServer."

	rfbServer := server
]
