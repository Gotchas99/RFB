"
I am a kind of RFBStream for writing byte-swapped 16-bit pixel data.  See the comment in that class for more information.
"
Class {
	#name : #RFBStreamSwap16,
	#superclass : #RFBStream,
	#category : #'RFB-Communication'
}

{ #category : #accessing }
RFBStreamSwap16 >> bytesPerCompressedPixel [
	"Answer the minimum number of bytes required to represent just the bits covered by the RGB channels in the pixels stored by the receiver."

	^2
]

{ #category : #accessing }
RFBStreamSwap16 >> nextPutPixel: pv [
	"Write a 16-bit pixel to the receiver, in little-endian order."

	^self
		nextPut: (pv  bitAnd: 255);
		nextPut: ((pv bitShift: -8) bitAnd: 255)
]
