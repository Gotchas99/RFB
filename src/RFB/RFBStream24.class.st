"
I am a kind of RFBStream for writing 32-bit pixel data or 24-bit 'compressed' pixel data for ZRLE encoding.  See the comment in that class for more information.
"
Class {
	#name : #RFBStream24,
	#superclass : #RFBStream32,
	#category : #'RFB-Communication'
}

{ #category : #accessing }
RFBStream24 >> bytesPerCompressedPixel [
	"Answer the minimum number of bytes required to represent just the bits covered by the RGB channels in the pixels stored by the receiver."

	^3
]

{ #category : #accessing }
RFBStream24 >> nextPutCPixel: pv [
	"Write a 24-bit 'compressed' pixel to the receiver, in natural (big-endian) order."

	^pv class == LargePositiveInteger
		ifTrue:
			[self
				nextPut: (pv at: 3);
				nextPut: (pv at: 2);
				nextPut: (pv at: 1)]
		ifFalse:
			[self
				nextPut: ((pv bitShift: -16) bitAnd: 255);
				nextPut: ((pv bitShift: -8) bitAnd: 255);
				nextPut: (pv  bitAnd: 255)]
]
