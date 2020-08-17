"
I am a fragment of a RFBMessage representing an update rectangle in the CoRRE encoding.
"
Class {
	#name : #RFBCoRRERectangle,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBCoRRERectangle class >> new [
	"Answer a RFBMessage that represents CoRRE rectangles."

	^super new: 4
]

{ #category : #accessing }
RFBCoRRERectangle >> bounds [
	"Answer the receiver's bounds."

	^(self byteAt: 1) @ (self byteAt: 2) extent: (self byteAt: 3) @ (self byteAt: 4)
]

{ #category : #accessing }
RFBCoRRERectangle >> bounds: bounds [
	"Set the receiver's bounds."

	self
		byteAt: 1 put: bounds left;
		byteAt: 2 put: bounds top;
		byteAt: 3 put: bounds width;
		byteAt: 4 put: bounds height
]

{ #category : #accessing }
RFBCoRRERectangle >> x: x y: y w: w h: h [
	"Set the receiver's bounds."

	self
		byteAt: 1 put: x;
		byteAt: 2 put: y;
		byteAt: 3 put: w;
		byteAt: 4 put: h
]
