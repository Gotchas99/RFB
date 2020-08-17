"
I am a kind of RFBStream for writing 16-bit pixel data.  See the comment in that class for more information.
"
Class {
	#name : #RFBStream16,
	#superclass : #RFBStream,
	#category : #'RFB-Communication'
}

{ #category : #accessing }
RFBStream16 >> bytesPerCompressedPixel [
	"Answer the minimum number of bytes required to represent just the bits covered by the RGB channels in the pixels stored by the receiver."

	^2
]

{ #category : #accessing }
RFBStream16 >> nextPutPixel: pv [
	"Write a 16-bit pixel value to the receiver, in natural (big-endian) order."

	^self
		nextPut: ((pv bitShift: -8) bitAnd: 255);
		nextPut: (pv  bitAnd: 255)
]
