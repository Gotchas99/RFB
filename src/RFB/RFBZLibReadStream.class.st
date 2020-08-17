"
I am a ZLibReadStream that understands how to decompress pixel values.
"
Class {
	#name : #RFBZLibReadStream,
	#superclass : #ZLibReadStream,
	#instVars : [
		'getPixel',
		'getCPixel',
		'pixelBuffer'
	],
	#category : #'RFB-Viewer'
}

{ #category : #'initialise-release' }
RFBZLibReadStream >> continueOn: aCollection [
	"Restart the stream with new compressed data but do not clear the previous encoding dictionary."

	source := aCollection.
	sourcePos := bitPos := 0.
	sourceLimit := aCollection size
]

{ #category : #'initialise-release' }
RFBZLibReadStream >> getPixel: pixelSelector getCPixel: cpixelSelector [
	"Set the accessors for pixels and compressed pixels."

	getPixel := pixelSelector.
	getCPixel := cpixelSelector.
	pixelBuffer := ByteArray new: 4
]

{ #category : #private }
RFBZLibReadStream >> next16 [
	"Answer a 16-bit pixel in natural byte order."

	self next: 2 into: pixelBuffer.
	^(			(pixelBuffer at: 1) bitShift: 8)
		bitOr: 	(pixelBuffer at: 2)
]

{ #category : #private }
RFBZLibReadStream >> next24 [
	"Answer a 24-bit pixel in natural byte order."

	self next: 3 into: pixelBuffer.
	^((			(pixelBuffer at: 1) bitShift: 16)
		bitOr: (	(pixelBuffer at: 2) bitShift: 8))
		bitOr: 	(pixelBuffer at: 3)
]

{ #category : #private }
RFBZLibReadStream >> next32 [
	"Answer a 32-bit pixel in natural byte order."

	self next: 4 into: pixelBuffer.
	^(((			(pixelBuffer at: 1) bitShift: 24)
		bitOr: (	(pixelBuffer at: 2) bitShift: 16))
		bitOr: (	(pixelBuffer at: 3) bitShift: 8))
		bitOr: 	(pixelBuffer at: 4)
]

{ #category : #accessing }
RFBZLibReadStream >> nextCPixel [
	"Answer the next compressed pixel."

	^self perform: getCPixel
]

{ #category : #accessing }
RFBZLibReadStream >> nextPixel [
	"Answer the next pixel."

	^self perform: getPixel
]

{ #category : #private }
RFBZLibReadStream >> nextSwap16 [
	"Answer a 16-bit pixel in unnatural byte order."

	self next: 2 into: pixelBuffer.
	^(			(pixelBuffer at: 2) bitShift: 8)
		bitOr: 	(pixelBuffer at: 1)
]

{ #category : #private }
RFBZLibReadStream >> nextSwap24 [
	"Answer a 24-bit pixel in unnatural byte order."

	self next: 3 into: pixelBuffer.
	^((			(pixelBuffer at: 3) bitShift: 16)
		bitOr: (	(pixelBuffer at: 2) bitShift: 8))
		bitOr: 	(pixelBuffer at: 1)
]

{ #category : #private }
RFBZLibReadStream >> nextSwap32 [
	"Answer a 32-bit pixel in unnatural byte order."

	self next: 4 into: pixelBuffer.
	^(((			(pixelBuffer at: 4) bitShift: 24)
		bitOr: (	(pixelBuffer at: 3) bitShift: 16))
		bitOr: (	(pixelBuffer at: 2) bitShift: 8))
		bitOr: 	(pixelBuffer at: 1)
]
