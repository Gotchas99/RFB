"
I describe the pixel format being used by a remote RFB viewer, including:

	- the byte order (big or little endian)
	- whether pixels are RGB (true colour) or indices into a colour lookup table (pseudo colour)
	- for true colour, I also remember the shifts and masks that describe each of the three colour channels (R, G and B) in a pixel.
"
Class {
	#name : #RFBPixelFormat,
	#superclass : #Object,
	#instVars : [
		'bitsPerPixel',
		'depth',
		'bigEndian',
		'trueColour',
		'redMax',
		'greenMax',
		'blueMax',
		'redShift',
		'greenShift',
		'blueShift',
		'orderMap',
		'colourMap'
	],
	#category : #'RFB-Server'
}

{ #category : #'instance creation' }
RFBPixelFormat class >> forForm: aForm [
	"Answer a pixel format describing the pixels in aForm, in host byte order."

	^self new forForm: aForm bigEndian: self isBigEndian
]

{ #category : #'instance creation' }
RFBPixelFormat class >> forForm: aForm bigEndian: endianFlag [
	"Answer a pixel format that describes the pixels in aForm, in the specified byte order."

	^self new forForm: aForm bigEndian: endianFlag
]

{ #category : #'instance creation' }
RFBPixelFormat class >> fromByteArray: aByteArray [
	"Answer a new pixel format initialised from the wire representation in aByteArray."

	^(self new fromByteArray: aByteArray) setMaps
]

{ #category : #testing }
RFBPixelFormat class >> isBigEndian [
	"test for pharo < 5.0"
	(SmalltalkImage current respondsTo: #isBigEndian)
		ifTrue: [ ^ SmalltalkImage current isBigEndian ].
	"test for pharo 5.0"
	Smalltalk globals at: #EndianDetector ifPresent: [:cls|
		^ cls isBigEndian ].
	Error signal: 'cannot determine endianess'
]

{ #category : #'instance creation' }
RFBPixelFormat class >> serverFormat [

	"RFBPixelFormat serverFormat"

	^self forForm: Display
]

{ #category : #converting }
RFBPixelFormat >> asByteArray [
	"Answer a ByteArray containing the wire representation of the receiver, suitable for inclusion in a protocol message."

	^(ByteArray new: 16)
		byteAt: 1 put: bitsPerPixel;
		byteAt: 2 put: depth;
		byteAt: 3 put: (bigEndian ifTrue: [1] ifFalse: [0]);
		byteAt: 4 put: (trueColour ifTrue: [1] ifFalse: [0]);
		unsignedShortAt: 5 put: redMax bigEndian: true;
		unsignedShortAt: 7 put: greenMax bigEndian: true;
		unsignedShortAt: 9 put: blueMax bigEndian: true;
		byteAt: 11 put: redShift;
		byteAt: 12 put: greenShift;
		byteAt: 13 put: blueShift;
		yourself
]

{ #category : #'colour maps' }
RFBPixelFormat >> bgr233ColourMap [
	"Answer a ColorMap that maps pixels from 32-bit ARGB8888 space into the BGR233 space used by viewers running in 8-bit 'true colour' mode."

	^ColorMap colors:
		((Color cachedColormapFrom: 8 to: 32) collect: [:pv |
			((((pv bitShift: -16-5)) bitAnd: 7) bitShift: 0)
			bitOr: (((((pv bitShift: -8-5)) bitAnd: 7) bitShift: 3)
			bitOr: ((((pv bitShift: -0-6)) bitAnd: 3) bitShift: 6))])
]

{ #category : #accessing }
RFBPixelFormat >> bigEndian [
	"Answer whether pixels in the format described by the receiver are big-endian (have most significant byte first in memory order)."

	^bigEndian
]

{ #category : #accessing }
RFBPixelFormat >> bigEndian: aBoolean [
	"Set the flag indicating that the format represented by the receiver stores pixels with the most significant byte first in memory order."

	bigEndian := aBoolean
]

{ #category : #accessing }
RFBPixelFormat >> bitsPerPixel [
	"Answer the number of bits required to store a single pixel in the format described by the receiver.  This will always be 8, 16 or 32."

	^bitsPerPixel
]

{ #category : #'pixel formats' }
RFBPixelFormat >> bppForDepth: squeakDepth [
	"Answer the number of bits per pixel for a pixel format corresponding to the given Squeak display depth."

	squeakDepth <= 8 ifTrue: [^8].
	squeakDepth == 16 ifTrue: [^16].
	squeakDepth == 32 ifTrue: [^32].
	self error: 'Ian is confused'
]

{ #category : #'colour maps' }
RFBPixelFormat >> colormapFromARGB [
	"Answer a ColorMap that converts ARGB8888 into the pixel format described by the receiver."

	^trueColour
		ifTrue: [ColorMap mappingFromARGB: self rgbMasks]
		ifFalse: [(Form extent: 0@0 depth: depth) colormapFromARGB]
]

{ #category : #accessing }
RFBPixelFormat >> colourMap [
	"Answer the ColorMap used to convert pixels from server format to the viewer format described by the receiver."

	^colourMap
]

{ #category : #printing }
RFBPixelFormat >> description [
	"Answer a terse, human-readable description of the receiver."

	^String streamContents: [:s | s
		nextPutAll: bitsPerPixel printString;
		nextPutAll: 'bpp, depth ';
		nextPutAll: depth printString;
		nextPutAll: ' ';
		nextPutAll: (bigEndian ifTrue: ['BE, '] ifFalse: ['LE, ']);
		nextPutAll: (trueColour ifTrue: ['true'] ifFalse: ['pseudo']); nextPutAll: ' colour';
		nextPutAll: ' ';
		nextPutAll: redMax printString; nextPutAll: ',';
		nextPutAll: greenMax printString; nextPutAll: ',';
		nextPutAll: blueMax printString; nextPutAll: ' ';
		nextPutAll: redShift printString; nextPutAll: '+';
		nextPutAll: greenShift printString; nextPutAll: '+';
		nextPutAll: blueShift printString]
]

{ #category : #encoding }
RFBPixelFormat >> display: sourceForm on: destForm at: destOrigin [
	"Display the sourceForm on the destForm at destOrigin with pixels converted from the format described by the receiver."
	"Note: pixel zero is transparent, so first fill the affected region with black (#000001) and then combine with Form paint instead of Form over."

	destForm fill: (destOrigin extent: sourceForm extent) fillColor: Color black.
	(BitBlt toForm: destForm)
		sourceForm: sourceForm;
		combinationRule: Form paint;
		destOrigin: destOrigin;
		"colorMap: colourMap;"
		copyBits
]

{ #category : #encoding }
RFBPixelFormat >> displayContents: bounds [
	"Answer a Form containing a copy of the Display within the given bounds, with pixels stored in the format described by the receiver."

	| form |
	form := RFBForm fromDisplay: bounds format: self.
	colourMap isNil
		ifFalse:
			[(BitBlt toForm: form)
				sourceForm: form;
				combinationRule: 3;
				colorMap: colourMap;
				copyBits].
"
	orderMap isNil
		ifFalse:
			[(BitBlt toForm: form)
				sourceForm: form;
				combinationRule: 3;
				colorMap: orderMap;
				copyBits].
"
	^form
]

{ #category : #'initialise-release' }
RFBPixelFormat >> forForm: aForm bigEndian: endianFlag [
	"Initialise the contents of the receiver to represent pixels as stored in aForm and with the specified byte order."

	bitsPerPixel := self bppForDepth: (depth := aForm depth).
	bigEndian := endianFlag.
	bitsPerPixel == 8
		ifTrue:
			[trueColour := false.
			 redMax := greenMax := blueMax := 0.
			 redShift := greenShift := blueShift := 0].
	bitsPerPixel == 16
		ifTrue:
			[trueColour := true.
			 redMax := greenMax := blueMax := (1 bitShift: 5) - 1.
			 redShift := 10.
			 greenShift := 5.
			 blueShift := 0].
	bitsPerPixel == 32
		ifTrue:
			[trueColour := true.
			 redMax := greenMax := blueMax := (1 bitShift: 8) - 1.
			 redShift := 16.
			 greenShift := 8.
			 blueShift := 0]
]

{ #category : #'initialise-release' }
RFBPixelFormat >> fromByteArray: bytes [
	"Initialise the contents of the receiver from a pixel format received in a protocol message."

	bitsPerPixel := bytes byteAt: 1.
	depth := bytes byteAt: 2.
	bigEndian := (bytes byteAt: 3) ~~ 0.
	trueColour := (bytes byteAt: 4) ~~ 0.
	redMax := bytes unsignedShortAt: 5 bigEndian: true.
	greenMax := bytes unsignedShortAt: 7 bigEndian: true.
	blueMax := bytes unsignedShortAt: 9 bigEndian: true.
	redShift := bytes byteAt: 11.
	greenShift := bytes byteAt: 12.
	blueShift := bytes byteAt: 13.
]

{ #category : #'pixel formats' }
RFBPixelFormat >> pixelMask [
	"Answer a mask covering all three RGB channels in the format described by the receiver."

	^((redMax bitShift: redShift)
		bitOr: (greenMax bitShift: greenShift))
		bitOr: (blueMax bitShift: blueShift)
]

{ #category : #printing }
RFBPixelFormat >> printOn: aStream [
	"Print a description of the receiver on aStream."

	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: self description;
		nextPut: $).
]

{ #category : #encoding }
RFBPixelFormat >> rfbStream [
	"Answer a new RFBStream suitable for writing bytes and pixels in the format described by the receiver."

	^RFBStream forDepth: bitsPerPixel mask: self pixelMask byteSwapped: bigEndian not
]

{ #category : #'pixel formats' }
RFBPixelFormat >> rgbMasks [

	"RFBPixelFormat serverFormat rgbMasks collect: [:m | m hex8]"
	"ColorMap mappingFrom: RFBPixelFormat serverFormat rgbMasks to: #(16rFF0000 16r00FF00 16r0000FF 0)"
	"ColorMap mappingFrom: RFBPixelFormat serverFormat rgbMasks to:  #(16r7C00 16r3E0 16r1F 0)"

	^Array
		with: (redMax bitShift: redShift)
		with: (greenMax bitShift: greenShift)
		with: (blueMax bitShift: blueShift)
		with: 0
]

{ #category : #private }
RFBPixelFormat >> setColourMap: serverFormat [
	"Set the ColorMap used to convert screen pixels to viewer pixels in local byte order.  For depth 32, ensure that the map clears (sets to zero) the alpha channel."
	"Rationale:  Remote viewers ignore the alpha channel in 32-bit pixels.  Locally it is stored in the top 8 bits of each word, and is almost always fully-opaque (i.e., 255) for pixels in the Display.  The vast majority of pixels in the underlying Bitmap are therefore LargePositiveIntegers.  Clearing the alpha to zero means the resulting Bitmap contains only SmallIntegers, eliminating entirely the creation of temporary LargeInts (along with any subsequent LargeInt arithmetic on them and the consequent GC overheads) during encoding.  This reduces the overall cost (in processor time) of encoding by at least 30% for all non-raw encodings."

	| form |
	form := Form extent: 0@0 depth: bitsPerPixel.
	(trueColour and: [(self rgbMasks = form rgbaBitMasks) not])
		ifTrue:
			[colourMap := bitsPerPixel == 8
				ifTrue: [self bgr233ColourMap]
				ifFalse: [form colormapFromARGB mappingTo: self colormapFromARGB]].
	(colourMap notNil and: [colourMap masks notNil])
		ifTrue:
			[colourMap masks at: 4 put: 0.
			 colourMap shifts at: 4 put: 0]
]

{ #category : #'pixel formats' }
RFBPixelFormat >> setMaps [
	"The receiver describes a remote pixel format.  Initialise the cached ColorMaps used for local->remote pixel format conversion."

	^self setMaps: self species serverFormat
]

{ #category : #'pixel formats' }
RFBPixelFormat >> setMaps: serverFormat [
	"Set the receiver's ColorMaps that describe the mapping from screen pixels to viewer pixels."
	"Note that this involves up to two corrections: pixel format conversion (mask and shift to resize and/or reposition each RGB channel) and byte order reversal (to correct for server/client endian differences).  Both corrections could be combined into a single operation (a single ColorMap), but are kept seperate such that encoding is always performed on pixels in *viewer* format but *server* byte order (RFBPixelFormat>>displayContents:), with any required byte order correction being delayed until pixels are actually sent down the wire (RFBSession>>nextPutForm:in:).  See RFBPixelFormat>>setColourMap: for an explanation of the rationale behind this."

	self
		setColourMap: serverFormat;		"pixel format conversion (if needed)"
		setOrderMap: serverFormat		"byte order reversal (if needed)"
]

{ #category : #private }
RFBPixelFormat >> setOrderMap: serverFormat [
	"Set the ColorMap used to convert local byte order to viewer byte order.  This map is effective only when sending an entire Bitmap to the remote viewer.  (Individual pixel values are always sent in big-endian order; see RFBStream{16,32}>>nextPutPixel:.)"

	orderMap := bigEndian == self class isBigEndian	"no map if byte order is commensurate"
		ifFalse:
			[bitsPerPixel == 16
				ifTrue: [ColorMap
							masks: #(16r00FF 16rFF00 0 0)
							shifts: #(8 -8 0 0)]
				ifFalse: [bitsPerPixel == 32
					ifTrue: [ColorMap
								masks: #(16r000000FF 16r0000FF00 16r00FF0000 16rFF000000)
								shifts: #(24 8 -8 -24)]]]
]

{ #category : #private }
RFBPixelFormat >> setReverseColourMap: serverFormat [
	"Set the ColorMap used to convert viewer pixels to screen pixels in local byte order."

	| form |
	form := Form extent: 0@0 depth: bitsPerPixel.
	(trueColour and: [(self rgbMasks = form rgbaBitMasks) not])
		ifTrue:
			[colourMap := bitsPerPixel == 8
				ifTrue: [self bgr233ColourMap]
				ifFalse: [self colormapFromARGB mappingTo: form colormapFromARGB]]
]

{ #category : #'pixel formats' }
RFBPixelFormat >> setReverseMaps [
	"The receiver describes a remote pixel format.  Initialise the cached ColorMaps used for remote->local pixel format conversion."

	^self setReverseMaps: self species serverFormat
]

{ #category : #'pixel formats' }
RFBPixelFormat >> setReverseMaps: serverFormat [
	"Set the receiver's ColorMaps that describe the mapping from viewer pixels to screen pixels."

	self
		setReverseColourMap: serverFormat;		"pixel format conversion (if needed)"
		setOrderMap: serverFormat				"byte order reversal (if needed)"
]

{ #category : #encoding }
RFBPixelFormat >> swapBytesIfNeeded: aForm [
	"Swap the byte order of all pixels within aForm, if the pixel format described by the receiver requires it."

	orderMap isNil ifTrue: [^aForm].
	^aForm applyColourMap: orderMap
]
