"
I am a kind of Stream over a ByteArray.  I understand both #nextPut: (to append bytes to my contents) and #nextPutPixel: (to append 8-, 16- or 32-bit pixel data, possibly byte-swapped, according to a ""pixel format"" specified when you instantiate me).  I cooperate with RFBSocket to send my contents over a network connection with ""zero copy"".

You instantiate me by sending ""forDepth: bitsPerPixel byteSwapped: swapFlag"".  If bitsPerPixel is 8 then you get back an instance of me.  If bitsPerPixel is not 8 then you get back an instance of one of my four subclasses that deal with 16- and 32-bit pixels in native or byte-swapped order.
"
Class {
	#name : #RFBStream,
	#superclass : #WriteStream,
	#category : #'RFB-Communication'
}

{ #category : #'instance creation' }
RFBStream class >> forDepth: depth mask: pixelMask byteSwapped: swapped [
	"Answer a new RFBStream suitable for storing pixels at the given depth with natural or swapped byte order."

	depth == 8 ifTrue: [^RFBStream new].
	depth == 16 ifTrue: [^(swapped ifTrue: [RFBStreamSwap16] ifFalse: [RFBStream16]) new].
	depth == 32 ifFalse: [self error: 'this cannot happen'].
	^pixelMask < 16r01000000
		ifTrue: [(swapped ifTrue: [RFBStreamSwap24] ifFalse: [RFBStream24]) new]
		ifFalse: [(swapped ifTrue: [RFBStreamSwap32] ifFalse: [RFBStream32]) new]
]

{ #category : #'instance creation' }
RFBStream class >> new [
	"Answer an empty stream suitable for storing 8-, 16- or 32-bit pixel values, with or without byte order swapping, depending on the receiver."

	^super on: (ByteArray new: 256)
]

{ #category : #accessing }
RFBStream >> at: index put: aByte [
	"Store a byte in the receiver at the given index (which must be less than the current write position) without changing the write position."

	self
		position: index;
		nextPut: aByte;
		setToEnd
]

{ #category : #accessing }
RFBStream >> bytesPerCompressedPixel [
	"Answer the minimum number of bytes required to represent just the bits covered by the RGB channels in the pixels stored by the receiver."

	^1
]

{ #category : #accessing }
RFBStream >> nextPutCPixel: pv [
	"Store an individual 'compressed' pixel value on the receiver."

	^self nextPutPixel: pv
]

{ #category : #accessing }
RFBStream >> nextPutForm: aForm in: bounds [
	"Write the contents of aForm to the receiver.  Note: this is VERY inefficient.  Encoders generally convert their Form to a ByteArray (using a BitBlt) and then write the resulting ByteArray (which is much faster).  See RFBForm>>asByteArray."

	| peek |
	peek := RFBBitBlt bitPeekerFromForm: aForm.
	bounds top to: bounds bottom - 1 do:
		[:y | bounds left to: bounds right - 1 do:
			[:x | self nextPutPixel: (peek pixelAt: x@y)]]
]

{ #category : #accessing }
RFBStream >> nextPutPixel: pv [
	"Store an individual 8-bit pixel value on the receiver."

	^self nextPut: pv
]

{ #category : #positioning }
RFBStream >> resetTo: offset [
	"Set the current write position to the given offset."

	position := readLimit := offset.
]
