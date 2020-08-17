"
I am a fragment of a RFBMessage representing a ""generic"" screen update rectangle.
"
Class {
	#name : #RFBFramebufferUpdateRectHeader,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBFramebufferUpdateRectHeader class >> new [
	"Answer an empty update rectangle header."

	^super new: 12
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> bounds [
	"Answer the bounds of the update rectangle."

	^self x @ self y extent: (self width @ self height)
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> bounds: aRect type: type [
    "Set the contents of the receiver to represent a rectangle of the specified type."
    | left top width height aBlock |

    aBlock := [ :v | (v isFloat) ifTrue: [ v truncated ] ifFalse: [ v ] ].  
    left := aBlock value: aRect left.
    top := aBlock value: aRect top.
    width := aBlock value: aRect width.
    height := aBlock value: aRect height.

    self
        unsignedShortAt: 1 put: left;
        unsignedShortAt: 3 put: top;
        unsignedShortAt: 5 put: width;
        unsignedShortAt: 7 put: height;
        unsignedLongAt: 9 put: type
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> cursorExtent [
	"Answer the cursor extent encoded in the receiver."

	^self width @ self height
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> cursorHotSpot [
	"Answer the cursor hot spot encoded in the receiver."

	^self x @ self y
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> cursorHotSpot: offset extent: extent type: type [
	"Set the contents of the receiver to represent the header of a pseudo-encoded cursor shape update."

	self
		unsignedShortAt: 1 put: offset x;
		unsignedShortAt: 3 put: offset y;
		unsignedShortAt: 5 put: extent x;
		unsignedShortAt: 7 put: extent y;
		unsignedLongAt: 9 put: type
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> cursorPos: aPoint type: type [
	"Set the contents of the receiver appropriately for a pseudo-encoded cursor position update."

	self
		unsignedShortAt: 1 put: aPoint x;
		unsignedShortAt: 3 put: aPoint y;
		unsignedShortAt: 5 put: 0;
		unsignedShortAt: 7 put: 0;
		unsignedLongAt: 9 put: type
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> height [
	"Answer the height of the update rectangle."

	^self unsignedShortAt: 7
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> type [
	"Answer the type of the rectangle represented by the receiver."

	^self  unsignedLongAt: 9
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> type: type [
	"Set the type of the rectangle represented by the receiver."

	self
		atAllPut: 0;
		unsignedLongAt: 9 put: type
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> width [
	"Answer the width of the update rectangle."

	^self unsignedShortAt: 5
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> x [
	"Answer the left edge of the update rectangle."

	^self unsignedShortAt: 1
]

{ #category : #accessing }
RFBFramebufferUpdateRectHeader >> y [
	"Answer the top edge of the update rectangle."

	^self unsignedShortAt: 3
]
