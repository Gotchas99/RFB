"
I am a colour palette.  I manage some number of pixel values (see #insert:) which I convert into an indexed palette (see #lookup:).  I am used by the ZRLE encoding which tries to send indexed pixel values instead of raw pixel values whenever possible.
"
Class {
	#name : #RFBPalette,
	#superclass : #Object,
	#instVars : [
		'index',
		'key',
		'pixels',
		'size'
	],
	#classVars : [
		'RfbPaletteMaxSize'
	],
	#category : #'RFB-Server'
}

{ #category : #'class initialisation' }
RFBPalette class >> initialize [
	"RFBPalette initialize"

	RfbPaletteMaxSize := 127.
]

{ #category : #'instance creation' }
RFBPalette class >> new [
	"Answer a new, empty palette."

	^super new initialise
]

{ #category : #'initialise-release' }
RFBPalette >> initialise [
	"RFBPalette new"

	pixels := WordArray new: RfbPaletteMaxSize.
	index := ByteArray new: (RfbPaletteMaxSize + 4096).
	key := WordArray new: RfbPaletteMaxSize + 4096.
	index atAllPut: 255.
	size := 0
]

{ #category : #accessing }
RFBPalette >> insert: pixelValue [
	"Add pixelValue to the palette if not already present, retaining its reverse index."

	| i |
	size < RfbPaletteMaxSize
		ifTrue:
			[i := (self zrleHash: pixelValue) + 1.
			 [(index at: i) ~~ 255 and: [(key at: i) ~= pixelValue]] whileTrue: [i := i + 1].
			 (index at: i) ~~ 255 ifTrue: [^self].
			 index at: i put: size.
			 key at: i put: pixelValue.
			 pixels at: 1 + size put: pixelValue].
	size := size + 1
]

{ #category : #accessing }
RFBPalette >> lookup: pixelValue [
	"Answer the palette index associated with pixelValue."

	| i |
	i := (self zrleHash: pixelValue) + 1.
	[(index at: i) ~~ 255 and: [(key at: i) ~= pixelValue]] whileTrue: [i := i + 1].
	^(index at: i) == 255
		ifTrue: [-1]
		ifFalse: [index at: i]
]

{ #category : #accessing }
RFBPalette >> pixels [
	"Answer the pixel values stored in the receiver."

	^pixels
]

{ #category : #accessing }
RFBPalette >> size [
	"Answer the number of pixel values stored in the receiver."

	^size
]

{ #category : #accessing }
RFBPalette >> size: anInteger [
	"Set the number of pixels stored in the receiver."

	size := anInteger
]

{ #category : #private }
RFBPalette >> zrleHash: pixelValue [
	"Return a SmallInteger hash for pixelValue, in the range 0..4095."

	^(pixelValue bitXor: (pixelValue bitShift: -17)) bitAnd: 4095
]
