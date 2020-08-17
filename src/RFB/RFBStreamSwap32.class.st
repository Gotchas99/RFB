"
I am a kind of RFBStream for writing byte-swapped 32-bit pixel data.  See the comment in that class for more information.
"
Class {
	#name : #RFBStreamSwap32,
	#superclass : #RFBStream,
	#category : #'RFB-Communication'
}

{ #category : #accessing }
RFBStreamSwap32 >> bytesPerCompressedPixel [
	"Answer the minimum number of bytes required to represent just the bits covered by the RGB channels in the pixels stored by the receiver."

	^4
]

{ #category : #accessing }
RFBStreamSwap32 >> nextPutPixel: pv [
	"Write a 32-bit pixel to the receiver, in little-endian order."

	^pv class == LargePositiveInteger
		ifTrue:
			[self
				nextPut: (pv at: 1);
				nextPut: (pv at: 2);
				nextPut: (pv at: 3);
				nextPut: (pv at: 4)]
		ifFalse:
			[self
				nextPut: (pv  bitAnd: 255);
				nextPut: ((pv bitShift: -8) bitAnd: 255);
				nextPut: ((pv bitShift: -16) bitAnd: 255);
				nextPut: ((pv bitShift: -24) bitAnd: 255)]
]
