"
I am a fragment of a RFBMessage representing a ""generic"" rectangle.
"
Class {
	#name : #RFBRectangle,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBRectangle class >> new [
	"Answer a new, empty rectangle."

	^super new: 8
]

{ #category : #accessing }
RFBRectangle >> bounds [
	"Answer the bounds of the rectangle represented by the receiver."

	^(self unsignedShortAt: 1) @ (self unsignedShortAt: 3)
		extent: (self unsignedShortAt: 5) @ (self unsignedShortAt: 7)
]

{ #category : #accessing }
RFBRectangle >> bounds: bounds [
	"Set the bounds of the rectangle represented by the receiver."

	self
		unsignedShortAt: 1 put: bounds left;
		unsignedShortAt: 3 put: bounds top;
		unsignedShortAt: 5 put: bounds width;
		unsignedShortAt: 7 put: bounds height
]

{ #category : #accessing }
RFBRectangle >> x: x y: y w: w h: h [
	"Set the bounds of the rectangle represented by the receiver."

	self
		unsignedShortAt: 1 put: x;
		unsignedShortAt: 3 put: y;
		unsignedShortAt: 5 put: w;
		unsignedShortAt: 7 put: h
]
