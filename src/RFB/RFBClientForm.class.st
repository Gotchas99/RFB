"
I am a RFBForm that understands how to decode framebuffer update messages.
"
Class {
	#name : #RFBClientForm,
	#superclass : #RFBForm,
	#category : #'RFB-Viewer'
}

{ #category : #copying }
RFBClientForm >> applyColourMap: aColorMap in: bounds [
	"Apply aColorMap destructively to all the pixels in the receiver within bounds."

	(RFBBitBlt toForm: self)
		sourceForm: self;
		sourceAndDestRect: bounds;
		combinationRule: Form over;
		colorMap: aColorMap;
		copyBits
]

{ #category : #'decoding-zrle' }
RFBClientForm >> bitsPerPackedPixel: paletteSize [
	"Answer the number of bits required for each pixel index in a palette of the given size."

	^paletteSize > 16
		ifTrue: [8]
		ifFalse: [paletteSize > 4
			ifTrue: [4]
			ifFalse: [paletteSize > 2 ifTrue: [2] ifFalse: [1]]]
]

{ #category : #'decoding-corre' }
RFBClientForm >> correDecode: bounds from: aSocket for: client [
	"Decode a CoRRE update from aSocket.  The receiver is of the correct depth and extent."

	| nSubrects pix subrect origin subBounds |
	nSubrects := (aSocket receiveData: RFBRREHeader new) nSubrects.
	pix := aSocket nextPixel.
	subrect := RFBCoRRERectangle new.
	self fill pixelsIn: bounds put: pix.
	origin := bounds origin.
	nSubrects
		timesRepeat:
			[pix := aSocket nextPixel.
			 subBounds := (aSocket receiveData: subrect) bounds translateBy: origin.
			 self fill pixelsIn: subBounds put: pix]
]

{ #category : #'decoding-hextile' }
RFBClientForm >> hextileDecode: bounds from: aSocket for: client [
	"Decode a hextile update from aSocket.  The receiver is of the correct depth and extent.  If client is nil then simply fill the receiver with the update.  If client is not nil then receive individual subrects and paint them on the receiver via the client."

	| w h subOrigin subExtent subBounds l r b bgFg |
	l := bounds left.
	r := bounds right.
	b := bounds bottom.
	bgFg := Array new: 2.
	bounds top to: b - 1 by: 16 do:
		[:y |
		 l to: r - 1 by: 16 do:
			[:x |
			 w := r - x min: 16.
			 h := b - y min: 16.
			 subOrigin := x@y.
			 subExtent := w@h.
			 subBounds := subOrigin extent: subExtent.
			 client isNil
				ifTrue:	"Fast update: fill self."
					[self hextileSubrectDecode: subBounds from: aSocket with: bgFg]
				ifFalse:	"Slow update: display on self."
					[client
						display: ((RFBClientForm extent: subExtent depth: depth)
									hextileSubrectDecode: (0@0 corner: subExtent)
									from: aSocket
									with: bgFg)
					 	on: self
						in: subBounds]]]
]

{ #category : #'decoding-hextile' }
RFBClientForm >> hextileSubrectDecode: bounds from: aSocket with: bgFg [
	"Decode a hextile subrectangle from aSocket using the given foreground/background pixel values."

	| subEncoding nSubrects bg fg origin |
	subEncoding := aSocket next.
	(subEncoding anyMask: RfbHextileRaw)
		ifTrue: [aSocket receiveForm: self in: bounds]
		ifFalse:
			[bg := bgFg at: 1.
			 fg := bgFg at: 2.
			 (subEncoding anyMask: RfbHextileBackgroundSpecified)
				ifTrue: [bg := aSocket nextPixel].
			 self fill pixelsIn: bounds put: bg.
			 (subEncoding anyMask: RfbHextileForegroundSpecified)
				ifTrue: [fg := aSocket nextPixel].
			 (subEncoding anyMask: RfbHextileAnySubrects)
				ifTrue:
					[origin := bounds origin.
					 nSubrects := aSocket next.
					 (subEncoding anyMask: RfbHextileSubrectsColoured)
						ifTrue:
							[nSubrects timesRepeat:
								[fg := aSocket nextPixel.
								 self fill pixelsIn: (aSocket nextHextileBounds: origin) put: fg]]
						ifFalse:
							[nSubrects timesRepeat:
								[self fill pixelsIn: (aSocket nextHextileBounds: origin) put: fg]]].
			 bgFg
				at: 1 put: bg;
				at: 2 put: fg]
]

{ #category : #'decoding-rre' }
RFBClientForm >> rreDecode: bounds from: aSocket for: client [
	"Decode a CoRRE update from aSocket.  The receiver is of the correct depth and extent."

	| nSubrects pix subrect |
	nSubrects := (aSocket receiveData: RFBRREHeader new) nSubrects.
	pix := aSocket nextPixel.
	subrect := RFBRectangle new.
	self fill pixelsIn: bounds put: pix.
	nSubrects
		timesRepeat:
			[pix := aSocket nextPixel.
			 self fill pixelsIn: (aSocket receiveData: subrect) bounds put: pix]
]

{ #category : #'decoding-zrle' }
RFBClientForm >> zrleDecode: bounds from: aStream for: client [
	"Decode a ZRLE update from the decompressed data on aStream.  The receiver is of the correct depth and extent."

	| l r t b th tw tile |
	l := bounds left.
	r := bounds right.
	t := bounds top.
	b := bounds bottom.
	t to: b - 1 by: RfbZrleTileHeight do:
		[:ty |
		 th := b - ty min: RfbZrleTileHeight.
		 l to: r - 1 by: RfbZrleTileWidth do:
			[:tx |
			 tw := r - tx min: RfbZrleTileWidth.
			 tile := RFBClientForm extent: tw@th depth: 32.
			 tile zrleDecodeTileFrom: aStream for: client.
			 tile displayOn: self at: tx@ty]]
]

{ #category : #'decoding-zrle' }
RFBClientForm >> zrleDecodeTileFrom: aStream for: client [
	"Decode a ZRLE update tile from the decompressed data on aStream.  The receiver is depth 32 regardless of the bits per pixel in use."

	| mode rle palSize palette bppp mask nBits byte index ptr end pix len |
	mode := aStream next.
	rle := mode anyMask: 128.
	palSize := mode bitAnd: 127.
	palette := WordArray new: 128.
	1 to: palSize do: [:i | palette at: i put: aStream nextCPixel].
	palSize == 1
		ifTrue: [bits atAllPut: (palette at: 1)]
		ifFalse:
			[rle
				ifFalse:	"not rle"
					[palSize == 0
						ifTrue:	"raw pixels"
							[1 to: bits size do: [:i | bits at: i put: aStream nextCPixel]]
						ifFalse:	"packed pixels"
							[bppp := self bitsPerPackedPixel: palSize.
							 mask := (1 bitShift: bppp) - 1.
							 ptr := 1.
							 1 to: height do:
								[:j |
								 nBits := 0.
							 	 1 to: width do:
									[:i |
									 nBits == 0
									 ifTrue:
										[byte := aStream next.
										 nBits := -8].
									 nBits := nBits + bppp.
									 index := (byte bitShift: nBits) bitAnd: mask.
									 bits at: ptr put: (palette at: 1 + (index bitAnd: 127)).
									 ptr := ptr + 1]]]]
				ifTrue:	"rle"
					[palSize == 0
						ifTrue:	"plain rle"
							[ptr := 1.
							 end := bits size.
							 [ptr <= end]
								whileTrue:
									[pix := aStream nextCPixel.
									 len := 1.
									 [byte := aStream next.
									  len := len + byte.
									  byte == 255] whileTrue.
									 len timesRepeat:
										[bits at: ptr put: pix.
										 ptr := ptr + 1]]]
						ifFalse:	"palette rle"
							[ptr := 1.
							 end := bits size.
							 [ptr <= end]
								whileTrue:
									[index := aStream next.
									 len := 1.
									 (index anyMask: 128)
										ifTrue:
											[[byte := aStream next.
											 len := len + byte.
											 byte == 255] whileTrue].
									 pix := palette at: 1 + (index bitAnd: 127).
									 len timesRepeat:
										[bits at: ptr put: pix.
										 ptr := ptr + 1]]]]]
]
