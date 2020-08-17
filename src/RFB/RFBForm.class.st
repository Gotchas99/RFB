"
I am a kind of Form that provides several additional facilities:

	- I hold on to cached BitBlts for doing pixel-based access (peeking, poking and filling), and provide additional methods #pixelAt:, #pixelAt:put:, and #pixelsIn:put: that use them.
	- I can describe my pixel format (depth, byte order, etc.) in the way that an RFBServer finds most useful.
	- I provide several methods to support the encoding of my contents on a stream for sending to a remote RFB viewer.
"
Class {
	#name : #RFBForm,
	#superclass : #Form,
	#instVars : [
		'format',
		'fill'
	],
	#classVars : [
		'IdentityMap16',
		'NumLargeInts',
		'NumSmallInts',
		'RfbHextileAnySubrects',
		'RfbHextileBackgroundSpecified',
		'RfbHextileForegroundSpecified',
		'RfbHextileRaw',
		'RfbHextileSubrectsColoured',
		'RfbZrleBitsPerPackedPixel',
		'RfbZrleTileHeight',
		'RfbZrleTileWidth'
	],
	#category : #'RFB-Server'
}

{ #category : #'instance creation' }
RFBForm class >> fromDisplay: bounds format: pixelFormat [
	"Answer a RFBForm containing a copy of the Display in bounds, in viewer byte order and depth (according to the given pixelFormat)."

	^(self extent: bounds extent depth: pixelFormat bitsPerPixel)
		format: pixelFormat;
		fromDisplay: bounds
]

{ #category : #'class initialisation' }
RFBForm class >> initialize [
	"RFBForm initialize"

	RfbHextileRaw					:= 1 << 0.
	RfbHextileBackgroundSpecified	:= 1 << 1.
	RfbHextileForegroundSpecified	:= 1 << 2.
	RfbHextileAnySubrects			:= 1 << 3.
	RfbHextileSubrectsColoured		:= 1 << 4.

	RfbZrleTileWidth := 64.
	RfbZrleTileHeight := 64.

	RfbZrleBitsPerPackedPixel := #(0 1 2 2 4 4 4 4 4 4 4 4 4 4 4 4).

	IdentityMap16 := ColorMap masks: #(16rFFFFFFFF 0 0 0) shifts: #(0 0 0 0).

	NumSmallInts := 0.
	NumLargeInts := 0.
]

{ #category : #copying }
RFBForm >> applyColourMap: aColorMap [
	"Apply aColorMap destructively to all the pixels in the receiver."

	(BitBlt toForm: self)
		sourceForm: self;
		combinationRule: Form over;
		width: width;
		height: height;
		colorMap: aColorMap;
		copyBits
]

{ #category : #accessing }
RFBForm >> bounds [
	"Answer the bounds of the original screen area from which the receiver was copied."

	^self boundingBox translateBy: offset
]

{ #category : #accessing }
RFBForm >> bytesPerPixel [
	"Answer the number of bytes needed to represent one pixel in the receiver."

	^depth // 8
]

{ #category : #'encoding-corre' }
RFBForm >> correSubrectEncodeIn: bounds on: stream [
	"Encode the region in the receiver covered by the gicen bounds onto the stream using CoRRE encoding."

	| maxSize backgroundPixel subrectHeader subForm |
	maxSize := bounds area * self bytesPerPixel.
	subForm := self pixelFormIn: bounds.
	backgroundPixel := subForm dominantPixel.
"self tallyPixel: backgroundPixel."
	stream nextPutPixel: backgroundPixel.
	subrectHeader := RFBCoRRERectangle new.
	^subForm
		rreSubrectsForBackgroundPixel: backgroundPixel
		doWithForegroundPixel:
			[:subrect :fg |
"self tallyPixel: fg."
			 stream
				nextPutPixel: fg;
				nextPutAll: (subrectHeader bounds: subrect).
			 stream size < maxSize
				ifFalse: [^-1]]
]

{ #category : #accessing }
RFBForm >> dominantPixel [
	"Answer the dominant (background) pixel in the receiver.
	Assumes: the receiver is 32 bits deep.
	Rationale: RFB/VNC server implementations traditionally (and stupidly) return the pixel at the origin for depth 16 or 32, or tally all pixels in the rectangle to find the predominant pixel when the depth is 8.  Both of these lose big when sending the initial screen, since: (1) the desktop background colour, at the origin, tends not to be the same as the window background colour covering most of the screen; and: (2) tallying pixel values in an 8-bit Form of any size, using BitBlt, involves enumerating a large tally array to find the maximum count.  Instead, since most non-background colour in the Squeak display is in narrow horizontal or vertical rectangles, we tally only a 1 pixel wide diagonal line from the origin.  This gives much better results than the traditional 'origin pixel' approach (since it is almost guaranteed to find the true backgound pixel) and speeds up RRE and CoRRE by a factor of three when sending a large update."

	| pixels line |
	pixels := RFBPixelPopulation new.			"Should use Bag, but can't get at its raw contents."
	line := 1.
	0 to: (height min: width) - 1 do: [:xy |
		pixels add: (bits at: line + xy).
		line := line + width].
	^pixels dominantPixel					"*much* faster than 'aBag sortedCounts first key'"
]

{ #category : #accessing }
RFBForm >> fill [
	"Answer the BitBlt used to fill pixels in the receiver."

	^fill
]

{ #category : #drawing }
RFBForm >> fill: aRectangle fillPixel: aPixel [
	"Fill the region covered by aRectangle in the receiver with aPixel."

	fill pixelsIn: aRectangle put: aPixel
]

{ #category : #accessing }
RFBForm >> format [
	"Answer the RFBPixelFormat of the receiver's pixels."

	^format
]

{ #category : #accessing }
RFBForm >> format: pixelFormat [
	"Set the pixel format of the receiver."

	format := pixelFormat
]

{ #category : #'initialise-release' }
RFBForm >> fromDisplay: aRectangle [
	"Answer a RFBForm containing the contents of the Display within aRectangle."

	^(super fromDisplay: aRectangle) offset: aRectangle origin

"
(RFBForm fromDisplay: (100@100 corner: 200@200)) displayAt: 10@10
"
]

{ #category : #'encoding-hextile' }
RFBForm >> hextileColours [
	"The receiver is a 16x16 pixel Form of depth 32 in viewer byte order.  Answer an Array of size 4 containing: (1) true if the Form is monochrome (or solid), false otherwise; (2) true if the Form is solid (contains a single colour), false otherwise; (3) the background (dominant) pixel; (4) the foreground (first pixel different from the background)."

	| tally1 tally2 colour1 colour2 |
	tally1 := tally2 := 0.
	bits do: [:pixel |
		tally1 == 0 ifTrue: [colour1 := pixel].
		pixel = colour1
			ifTrue: [tally1 := tally1 + 1]
			ifFalse:
				[tally2 == 0 ifTrue: [colour2 := pixel].
				 pixel = colour2
					ifTrue: [tally2 := tally2 + 1]
					ifFalse: [^Array		"monochrome solid background foreground"
								with: false
								with: false
								with: (tally1 > tally2 ifTrue: [colour1] ifFalse: [colour2])
								with: (tally1 > tally2 ifTrue: [colour2] ifFalse: [colour1])]]].
	^Array
		with: true
		with: colour2 == nil
		with: (tally1 > tally2 ifTrue: [colour1] ifFalse: [colour2])
		with: (tally1 > tally2 ifTrue: [colour2] ifFalse: [colour1])


"
| f |
f := RFBForm fromUser.
f hextileColours
"
]

{ #category : #'encoding-hextile' }
RFBForm >> hextileEncodeOn: stream forClient: rfbClient [
	"Encode the contents of the receiver on rfbClient using Hextile encoding."

	| w h flags rect colours mono solid newBg newFg validBg validFg bg fg flagsPosition subForm bpp |
	bpp := self bytesPerPixel.
	bg := fg := nil.
	validBg := validFg := false.
	0 to: height - 1 by: 16 do: [:y |
		0 to: width - 1 by: 16 do: [:x |
			w := h := 16.
			width - x < 16 ifTrue: [w := width - x].
			height - y < 16 ifTrue: [h := height - y].
			flagsPosition := stream size.
			stream nextPut: (flags := 0).
			rect := x@y extent: w@h.
			subForm := self pixelFormIn: rect.
			colours := subForm hextileColours.
			mono := colours at: 1.
			solid := colours at: 2.
			newBg := colours at: 3.
			newFg := colours at: 4.
			(validBg not or: [newBg ~~ bg])
				ifTrue:
					[validBg := true.
					 bg := newBg.
					 flags := flags bitOr: RfbHextileBackgroundSpecified.
					 stream nextPutPixel: bg].
			solid
				ifFalse:
					[flags := flags bitOr: RfbHextileAnySubrects.
					 mono
						ifTrue:
							[(validFg not or: [newFg ~~ fg])
								ifTrue:
									[validFg := true.
									 fg := newFg.
									 flags := flags bitOr: RfbHextileForegroundSpecified.
									 stream nextPutPixel: fg]]
						ifFalse:
							[validFg := false.
							 flags := flags bitOr: RfbHextileSubrectsColoured].
					 (subForm hextileSubrectEncodeOn: stream
								bg: bg fg: fg mono: mono
								bytesPerPixel: bpp) < 0
						ifTrue:
							[validBg := validFg := false.
							 stream
								resetTo: flagsPosition;
								nextPut: (flags := RfbHextileRaw);
							 	nextPutForm: self in: rect]].
			 stream at: flagsPosition put: flags].
		stream size > rfbClient maximumTransmissionUnit
			ifTrue:
				[rfbClient sendStream: stream.
				 stream resetContents]].
	rfbClient sendStream: stream
]

{ #category : #'encoding-hextile' }
RFBForm >> hextileSubrectEncodeOn: stream bg: bg fg: fg mono: mono bytesPerPixel: bpp [
	"The receiver is a 16x16 Hextile subrectangle in viewer format, requiring bpp byytes per pixel, and containing 2 (iff mono is true) or more distinct pixel values.  Write its encoding onto the stream using the specified background and foreground pixels."

	| initialPosition subrectCount encodedLength maxLength |
	initialPosition := stream size.
	stream nextPut: (subrectCount := 0).
	encodedLength := 1.
	maxLength := width * height * bpp.
	subrectCount := self
		rreSubrectsForBackgroundPixel: bg
		doWithForegroundPixel:
			[:subrect :foregroundPixel |
			 encodedLength := encodedLength + (mono ifTrue: [2] ifFalse: [bpp + 2]).
			 encodedLength < maxLength ifFalse: [^-1].
			 mono ifFalse: [stream nextPutPixel: foregroundPixel].
			 stream
				nextPut: ((subrect left bitShift: 4) bitOr: subrect top);
				nextPut: ((subrect width - 1 bitShift: 4) bitOr: subrect height - 1)].
	stream at: initialPosition put: subrectCount.
	^subrectCount
]

{ #category : #'fileIn/Out' }
RFBForm >> hibernate [
	"Put the receiver to sleep before storing an image snapshot.  Avoid hibernating the numerous small cached Forms within the RFB server implementation."

	bits size > 32 ifTrue: [super hibernate]
]

{ #category : #'initialise-release' }
RFBForm >> initialiseBitBlts [
	"Initialise the cached BitBlts."

	fill := RFBBitBlt bitFillerToForm: self.
]

{ #category : #comparing }
RFBForm >> isChangedFrom: aForm in: bounds [
	"Answer whether the receiver differs from aForm within the given bounds."

	aForm == self ifTrue: [^false].
	(self extent ~= aForm extent or: [self depth ~= aForm depth])
		ifTrue: [self error: 'forms must be commensurate'].
	^self pvtChangedFrom: aForm in: bounds
]

{ #category : #private }
RFBForm >> pixelFormIn: bounds [
	"Answer a Form containing contiguous 32-bit pixel values in the area of the receiver covered by the given bounds."

	| form w h cmap |
	w := bounds width.
	h := bounds height.
	cmap := depth == 16 ifTrue: [IdentityMap16].
	(BitBlt toForm: (form := RFBForm extent: w@h depth: 32))
		sourceForm: self;
		sourceOrigin: bounds origin;
		combinationRule: Form over;
		destX: 0 destY: 0 width: w height: h;
		colorMap: cmap;
		copyBits.
	^form
]

{ #category : #private }
RFBForm >> pvtChangedFrom: aForm in: bounds [
	"Answer whether the receiver differs from aForm within the given bounds.  Assume that aForm is commesurate with the receiver."

	| scale source dest l w t extent |
	depth > 8
		ifTrue:
			[scale := self depth // 8.
			 extent := width * scale @ height.
			 source := Form extent: extent depth: 8 bits: bits.
			 dest := Form extent: extent depth: 8 bits: aForm bits]
		ifFalse:
			[scale := 1.
			 source := self.
			 dest := aForm].
	l := bounds left * scale.
	w := bounds width * scale.
	t := bounds top.
	^0 ~~ ((BitBlt toForm: dest)
			sourceForm: source;
			sourceX: l;
			sourceY: t;
			combinationRule: 32;
			destX: l destY: t width: w height: bounds height;
			copyBits)
]

{ #category : #'encoding-rre' }
RFBForm >> rreSubrectEncodeOn: encodedStream [
	"The receiver is a Form in viewer byte order and depth, of arbitrary size.  Encode the contents on encodedStream using rise and run-length (RRE) encoding."

	| rawSize subrectHeader backgroundPixel subForm |
	rawSize := bits byteSize.
	subrectHeader := RFBRectangle new.
	subForm := self pixelFormIn: self boundingBox.
	backgroundPixel := subForm dominantPixel.
	encodedStream nextPutPixel: backgroundPixel.
	^subForm
		rreSubrectsForBackgroundPixel: backgroundPixel
		doWithForegroundPixel:
			[:subrect :fg |
			 encodedStream nextPutPixel: fg; nextPutAll: (subrectHeader bounds: subrect).
			 encodedStream size >= rawSize ifTrue: [^-1]]
]

{ #category : #'encoding-rre' }
RFBForm >> rreSubrectsForBackgroundPixel: backgroundPixel doWithForegroundPixel: subrectBlock [
	"Enumerate the RRE (rise and run-length encoded) rectangles within the receiver.  For each rectangle, invoke subrectBlock with the rectangle and its foreground (solid) pixel as arguments.  Answer the number of RRE subrectangles found in the receiver."

	| line subrectCount foregroundPixel hy hyflag scan j i vx hx vy hw hh vw vh subrect |
	line := 1.
	subrectCount := 0.
	0 to: height - 1 do: [:y |
		0 to: width - 1 do: [:x |
			(foregroundPixel := bits at: line + x) ~= backgroundPixel
				ifTrue:
					[hy := y - 1.
					 hyflag := true.
					 scan := line.
					 j := y.
					 [j < height and: [(bits at: scan + x) = foregroundPixel]]
						whileTrue:
							[i := x.
							 [i < width and: [(bits at: scan + i) = foregroundPixel]]
								whileTrue: [i := i + 1].
							 i := i - 1.
							 j == y ifTrue: [vx := hx := i].
							 i < vx ifTrue: [vx := i].
							 (hyflag and: [ i >= hx ])
								ifTrue: [hy := hy + 1]
								ifFalse: [hyflag := false].
							 j := j + 1.
							 scan := scan + width].
					vy := j - 1.
					"Two possible subrects: (x,y,hx,hy) (x,y,vx,vy).  Choose the larger."
					hw := hx - x + 1.  hh := hy - y + 1.
					vw := vx - x + 1.  vh := vy - y + 1.
					subrect := x@y extent: (((hw*hh) > (vw*vh)) ifTrue: [hw@hh] ifFalse: [vw@vh]).
					subrectBlock value: subrect value: foregroundPixel.
					subrectCount := subrectCount + 1.
					"Mark subrect as done."
					self fill: subrect fillPixel: backgroundPixel]].
		line := line + width].
	^subrectCount
]

{ #category : #private }
RFBForm >> setExtent: extent depth: bitDepth [
	"Set the extent and depth of the receiver."

	super setExtent: extent depth: bitDepth.
	self initialiseBitBlts
]

{ #category : #copying }
RFBForm >> subForm: bounds [
	"Answer a copy of the portion of the receiver in bounds, at the same depth."

	| subForm |
	subForm := RFBForm extent: bounds extent depth: depth.
	(BitBlt toForm: subForm)
		sourceForm: self;
		sourceOrigin: bounds origin;
		combinationRule: Form over;
		width: bounds width;
		height: bounds height;
		copyBits.
	^subForm
]

{ #category : #accessing }
RFBForm >> width: w height: h [
	"Set the width and height of the receiver without changing its bits."

	width := w.
	height := h.
]

{ #category : #'encoding-zrle' }
RFBForm >> zrleEncodeOn: aStream [
	"Encode the contents of the receiver on aStream for rfbClient using ZRLE encoding."

	| th tw |
	0 to: height - 1 by: RfbZrleTileHeight do:
		[:ty |
		 th := RfbZrleTileHeight.
		 th > (height - ty) ifTrue: [th := height - ty].
		 0 to: width - 1 by: RfbZrleTileWidth do:
			[:tx |
			 tw := RfbZrleTileWidth.
			 tw > (width - tx) ifTrue: [tw := width - tx].
			 (self pixelFormIn: (tx@ty extent: tw@th))
				zrleEncodeTileOn: aStream]]
]

{ #category : #'encoding-zrle' }
RFBForm >> zrleEncodeTileOn: aStream [
	"Encode the contents of the receiver on aStream for rfbClient using ZRLE encoding.  Assumes: the receiver is depth 32, regardless of the 'depth' of each pixel value stored in its Bitmap."

	| palette runs singlePixels ptr end pix usePalette estimatedBytes plainRleBytes useRle paletteRleBytes packedBytes runStart len index bppp nbits byte eol bpcp |
	palette := RFBPalette new.
	bpcp := aStream bytesPerCompressedPixel.
	"Built the palette and count the number of single pixels and runs."
	runs := 0.
	singlePixels := 0.
	ptr := 1.
	end := bits size + 1.
	[ptr < end]
		whileTrue:
			[pix := bits at: ptr.
			 ((ptr := ptr + 1) == end or: [pix ~= (bits at: ptr)])
				ifTrue: [singlePixels := singlePixels + 1]
				ifFalse:
					[[(ptr := ptr + 1) < end and: [(bits at: ptr) = pix]] whileTrue.
					 runs := runs + 1].
			 palette insert: pix].
	"Solid tile (palette contains only one pixel) is a special case."
	palette size == 1
		ifTrue:
			[^aStream
				nextPut: 1;
				nextPutCPixel: palette pixels first].
	"Determine whether to use RLE and/or the palette.  We do this by
	 estimating the number of uncompressed bytes that will be generated
	 and choosing the method that generates the fewest.  Of course, this
	 may not result in the fewest bytes after compression."
	usePalette := false.
	estimatedBytes := width * height * bpcp.		"Raw encoding size."
	plainRleBytes := bpcp + 1 * (runs + singlePixels).
	(useRle := plainRleBytes < estimatedBytes)
		ifTrue: [estimatedBytes := plainRleBytes].
	palette size < 128
		ifTrue:
			[paletteRleBytes := (bpcp * palette size) + (2 * runs) + singlePixels.
			 paletteRleBytes < estimatedBytes
				ifTrue:
					[useRle := true.
					 usePalette := true.
					 estimatedBytes := paletteRleBytes].
			 palette size < 17
				ifTrue:
					[packedBytes := bpcp * palette size
						+ (width * height * (RfbZrleBitsPerPackedPixel at: palette size) // 8).
			 packedBytes < estimatedBytes
				ifTrue:
					[useRle := false.
					 usePalette := true.
					 estimatedBytes := packedBytes]]].
	usePalette ifFalse: [palette size: 0].

	aStream nextPut: ((useRle ifTrue: [128] ifFalse: [0]) bitOr: palette size).
	1 to: palette size do: [:i | aStream nextPutCPixel: (palette pixels at: i)].
	useRle
		ifTrue:
			[ptr := 1.
			 end := 1 + (width * height).
			 [ptr < end]
				whileTrue:
					[runStart := ptr.
					 pix := bits at: ptr.
					 ptr := ptr + 1.
					 [ptr < end and: [(bits at: ptr) = pix]] whileTrue: [ptr := ptr + 1].
					 len := ptr - runStart.
					 (len <= 2 and: [ usePalette ])
						ifTrue:
							[index := palette lookup: pix.
							 len == 2 ifTrue: [aStream nextPut: index].
							 aStream nextPut: index]
						ifFalse:
							[usePalette
								ifTrue:
									[index := palette lookup: pix.
									 aStream nextPut: (index bitOr: 128)]
								ifFalse:
									[aStream nextPutCPixel: pix].
							 len := len - 1.
							 [len >= 255]
								whileTrue:
									[aStream nextPut: 255.
									 len := len - 255].
							 aStream nextPut: len]]]
		ifFalse:
			[usePalette
				ifTrue:
					[ptr := 1.
					 bppp := RfbZrleBitsPerPackedPixel at: palette size.
					 0 to: height - 1 do:
						[:i |
						 nbits := 0.
						 byte := 0.
						 eol := ptr + width.
						 [ptr < eol]
							whileTrue:
								[pix := bits at: ptr.
								 ptr := ptr + 1.
								 index := palette lookup: pix.
								 byte := (byte bitShift: bppp) bitOr: index.
								 nbits := nbits + bppp.
								 nbits >= 8
									ifTrue:
										[aStream nextPut: byte.
										 nbits := byte := 0]].
						 nbits > 0
							ifTrue:
								[byte := byte bitShift: 8 - nbits.
								 aStream nextPut: byte]]]
				ifFalse:	"raw"
					[bits do: [:pixel | aStream nextPutCPixel: pixel]]]
]
