"
I am a RFBSocket that understands how to read pixels.
"
Class {
	#name : #RFBClientSocket,
	#superclass : #RFBSocket,
	#instVars : [
		'getPixel',
		'getCPixel',
		'pixelBuffer'
	],
	#category : #'RFB-Viewer'
}

{ #category : #'instance creation' }
RFBClientSocket class >> new [
	"Answer a new socket."

	^super new initialise
]

{ #category : #'instance creation' }
RFBClientSocket class >> newTCP [
	"Answer a new TCP socket."

	^super newTCP initialise
]

{ #category : #accessing }
RFBClientSocket >> getCPixel [
	"Answer the next compressed pixel read from the connection."

	^getCPixel
]

{ #category : #accessing }
RFBClientSocket >> getPixel [
	"Answer the next pixel read from the connection."

	^getPixel
]

{ #category : #'initialize-release' }
RFBClientSocket >> initialise [
	"Set the default conditions in the receiver."

	getPixel := #next.
	pixelBuffer := ByteArray new: 4
]

{ #category : #'initialize-release' }
RFBClientSocket >> initialiseForDepth: depth mask: pixelMask byteSwapped: swapped [
	"Initialise the receiver to read pixels at the given depth with natural or swapped byte order."

	depth == 8 ifTrue: [^getPixel := getCPixel := #next].
	depth == 16 ifTrue: [^getPixel := getCPixel := swapped ifTrue: [#nextSwap16] ifFalse: [#next16]].
	depth == 32 ifFalse: [self error: 'this cannot happen'].
	getPixel := swapped ifTrue: [#nextSwap32] ifFalse: [#next32].
	getCPixel := pixelMask < 16r01000000
		ifTrue: [swapped ifTrue: [#nextSwap24] ifFalse: [#next24]]
		ifFalse: [swapped ifTrue: [#nextSwap32] ifFalse: [#next32]]
]

{ #category : #accessing }
RFBClientSocket >> next [
	"Answer the next byte from the connection."

	self receiveData: pixelBuffer startingAt: 1 count: 1.
	^pixelBuffer at: 1
]

{ #category : #private }
RFBClientSocket >> next16 [
	"Answer a 16-bit pixel in natural byte order read from the connection."

	self receiveData: pixelBuffer startingAt: 1 count: 2.
	^(			(pixelBuffer at: 1) bitShift: 8)
		bitOr: 	(pixelBuffer at: 2)
]

{ #category : #private }
RFBClientSocket >> next24 [
	"Answer a 24-bit pixel in natural byte order read from the connection."

	self receiveData: pixelBuffer startingAt: 1 count: 3.
	^((			(pixelBuffer at: 1) bitShift: 16)
		bitOr: (	(pixelBuffer at: 2) bitShift: 8))
		bitOr: 	(pixelBuffer at: 3)
]

{ #category : #private }
RFBClientSocket >> next32 [
	"Answer a 32-bit pixel in natural byte order read from the connection."

	self receiveData: pixelBuffer startingAt: 1 count: 4.
	^(((			(pixelBuffer at: 1) bitShift: 24)
		bitOr: (	(pixelBuffer at: 2) bitShift: 16))
		bitOr: (	(pixelBuffer at: 3) bitShift: 8))
		bitOr: 	(pixelBuffer at: 4)
]

{ #category : #accessing }
RFBClientSocket >> nextCPixel [
	"Answer the next compressed pixel from the connection."

	^self perform: getCPixel
]

{ #category : #decoding }
RFBClientSocket >> nextHextileBounds: origin [
	"Answer the next byte decoded as a hextile subrect bounds at the given origin."

	^self nextHextileOrigin + origin extent: self nextHextileExtent
]

{ #category : #private }
RFBClientSocket >> nextHextileExtent [
	"Answer the next byte decoded as a hextile subrect extent."

	| byte |
	byte := self next.
	^((byte bitShift: -4) + 1) @ ((byte bitAnd: 16r0F) + 1)
]

{ #category : #private }
RFBClientSocket >> nextHextileOrigin [
	"Answer the next byte decoded as a hextile subrect origin."

	| byte |
	byte := self next.
	^(byte bitShift: -4) @ (byte bitAnd: 16r0F)
]

{ #category : #accessing }
RFBClientSocket >> nextPixel [
	"Answer the next pixel from the connection."

	^self perform: getPixel
]

{ #category : #private }
RFBClientSocket >> nextSwap16 [
	"Answer a 16-bit pixel in unnatural byte order read from the connection."

	self receiveData: pixelBuffer startingAt: 1 count: 2.
	^(			(pixelBuffer at: 2) bitShift: 8)
		bitOr: 	(pixelBuffer at: 1)
]

{ #category : #private }
RFBClientSocket >> nextSwap24 [
	"Answer a 24-bit pixel in unnatural byte order read from the connection."

	self receiveData: pixelBuffer startingAt: 1 count: 3.
	^((			(pixelBuffer at: 3) bitShift: 16)
		bitOr: (	(pixelBuffer at: 2) bitShift: 8))
		bitOr: 	(pixelBuffer at: 1)
]

{ #category : #private }
RFBClientSocket >> nextSwap32 [
	"Answer a 32-bit pixel in unnatural byte order read from the connection."

	self receiveData: pixelBuffer startingAt: 1 count: 4.
	^(((			(pixelBuffer at: 4) bitShift: 24)
		bitOr: (	(pixelBuffer at: 3) bitShift: 16))
		bitOr: (	(pixelBuffer at: 2) bitShift: 8))
		bitOr: 	(pixelBuffer at: 1)
]

{ #category : #receiving }
RFBClientSocket >> receiveForm: aForm in: bounds [
	"Read the contents of aForm from the receiver.  Note: this is VERY inefficient.  Decoders generally read a ByteArray and then display it on their Form."

	| poke |
	poke := RFBBitBlt bitPokerToForm: aForm.
	bounds top to: bounds bottom - 1 do:
		[:y | bounds left to: bounds right - 1 do:
			[:x | poke pixelAt: x@y put: self nextPixel]]
]
