"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBPointerEvent,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBPointerEvent class >> buttonMask: mask position: aPoint [

	"RFBPointerEvent buttonMask: 42 position: 1@2"

	^self new buttonMask: mask position: aPoint
]

{ #category : #'instance creation' }
RFBPointerEvent class >> new [

	"RFBPointerEvent new"

	^super
		new: 6					"type + buttonMask + x + y"
		type: RfbPointerEvent
]

{ #category : #accessing }
RFBPointerEvent >> buttonMask [
	"Answer the bit mask corresponding to the buttons pressed when the event represented by the receiver was generated."

	^self byteAt: 2
]

{ #category : #accessing }
RFBPointerEvent >> buttonMask: mask position: aPoint [
	"Set the bit mask corresponding to the buttons pressed and position of the reveiver."

	self
		byteAt: 2 put: mask;
		unsignedShortAt: 3 put: aPoint x;
		unsignedShortAt: 5 put: aPoint y
]

{ #category : #accessing }
RFBPointerEvent >> x [
	"Answer the x coordinate at which the pointer event represented by the receiver occurred."

	^self unsignedShortAt: 3
]

{ #category : #accessing }
RFBPointerEvent >> y [
	"Answer the y coordinate at which the pointer event represented by the receiver occurred."

	^self unsignedShortAt: 5
]
