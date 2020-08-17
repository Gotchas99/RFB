"
I am a RFBMessage representing a server initialisation message.
"
Class {
	#name : #RFBServerInitialisation,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBServerInitialisation class >> extent: extent format: pixelFormat name: title [
	"Answer a new server initialisation message describing a desktop with the given extent, pixelFormat and title."

	"RFBServerInitialisation extent: 666@42 format: RFBPixelFormat serverFormat name: 'The display with no name'"

	^(self new: title size)
		width: extent x;
		height: extent y;
		pixelFormat: pixelFormat;
		nameLength: title size;
		name: title
]

{ #category : #'instance creation' }
RFBServerInitialisation class >> new [
	"Answer a new, empty server initialisation message.  Neither the length nor contents of the desktop title are included in the answer."
	"RFBServerInitialisation new"

	^super new: 4 + 16		"card16(w) card16(h) pixelFormat"

]

{ #category : #'instance creation' }
RFBServerInitialisation class >> new: titleLength [
	"Answer a new, empty server initialisation message with enough room to store titleLength characters of desktop title."
	"RFBServerInitialisation new: 5"

	^super new: 4 + 16 + 4 + titleLength		"card16(w) card16(h) pixelFormat card32(len) card8[len]"

]

{ #category : #accessing }
RFBServerInitialisation >> height [
	"Answer the desktop height stored in the receiver."

	^self unsignedShortAt: 3
]

{ #category : #accessing }
RFBServerInitialisation >> height: anInteger [
	"Set the desktop height stored in the receiver."

	self unsignedShortAt: 3 put: anInteger
]

{ #category : #accessing }
RFBServerInitialisation >> name [
	"Answer the desktop name stored in the receiver."

	| length |
	length := self nameLength.
	^length > 0
		ifTrue: [(self copyFrom: 25 to: 24 + length) asString]
		ifFalse: ['']
]

{ #category : #accessing }
RFBServerInitialisation >> name: aString [
	"Set the desktop name stored in the receiver."

	self replaceFrom: 25 to: 24 + aString size with: aString
]

{ #category : #accessing }
RFBServerInitialisation >> nameLength [
	"Answer the length of the desktop name stored in the receiver."

	^self size > 20 ifTrue: [self unsignedLongAt: 21] ifFalse: [0]
]

{ #category : #accessing }
RFBServerInitialisation >> nameLength: anInteger [
	"Set the length of the desktop name stored in the receiver."

	self unsignedLongAt: 21 put: anInteger
]

{ #category : #accessing }
RFBServerInitialisation >> pixelFormat [
	"Answer the server pixel format stored in the receiver."

	^RFBPixelFormat fromByteArray: (self copyFrom: 5 to: 20)
]

{ #category : #accessing }
RFBServerInitialisation >> pixelFormat: pixelFormat [
	"Set the server pixel format stored in the receiver."

	self replaceFrom: 5 to: 20 with: pixelFormat asByteArray
]

{ #category : #accessing }
RFBServerInitialisation >> width [
	"Answer the desktop width stored in the receiver."

	^self unsignedShortAt: 1
]

{ #category : #accessing }
RFBServerInitialisation >> width: anInteger [
	"Set the desktop width stored in the receiver."

	self unsignedShortAt: 1 put: anInteger
]
