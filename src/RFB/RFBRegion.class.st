"
I represent a (possibly non-contiguous) damaged region in some display medium (such as a Form).  You send me ""add: aRectangle"" to add new areas to the region I represent.  Later you can send me ""removeFirst"" to retrieve individual areas in the region, or ""removeAll"" to retrieve a Collection of all the rectangles in the region.
"
Class {
	#name : #RFBRegion,
	#superclass : #SharedQueue,
	#category : #'RFB-Server'
}

{ #category : #accessing }
RFBRegion >> add: aRectangle [
	"Add aRectangle to the region represented by the receiver."

	aRectangle hasPositiveExtent ifTrue: [self nextPut: aRectangle]
]

{ #category : #accessing }
RFBRegion >> removeAll [
	"Answer an Array containing all the damage rectangles in the receiver, emptying the receiver in the process."

	| boxes |
	boxes := OrderedCollection new.
	[self isEmpty] whileFalse: [boxes add: self next].
	^boxes asArray
]

{ #category : #accessing }
RFBRegion >> removeFirst [
	"Answer the first rectangle in the region represented by the receiver, removing it in the process."

	^self isEmpty ifTrue: [0@0 corner: 0@0] ifFalse: [self next]
]
