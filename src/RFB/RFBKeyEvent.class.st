"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBKeyEvent,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBKeyEvent class >> key: keyCode down: downFlag [

	"RFBKeyEvent key: 42 down: true"

	^self new key: keyCode down: downFlag
]

{ #category : #'instance creation' }
RFBKeyEvent class >> new [

	"RFBKeyEvent new"

	^super
		new: 8					"type + down + pad[2] + key"
		type: RfbKeyEvent
]

{ #category : #accessing }
RFBKeyEvent >> down [
	"Answer whether the receiver represents a key down event.  (If not, then it is a key up event.)"

	^(self byteAt: 2) ~~ 0
]

{ #category : #accessing }
RFBKeyEvent >> key [
	"Answer the keysym for the event represented by the receiver."

	^self unsignedLongAt: 5
]

{ #category : #accessing }
RFBKeyEvent >> key: keyCode down: downFlag [
	"Set the keysym and down flag for the event represented by the receiver."

	self
		byteAt: 2 put: (downFlag ifTrue: [1] ifFalse: [0]);
		unsignedLongAt: 5 put: keyCode
]
