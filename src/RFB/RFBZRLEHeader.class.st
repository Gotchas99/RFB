"
I am a header for an update rectangle in ZRLE (Zlib Run Length Encoding) format.
"
Class {
	#name : #RFBZRLEHeader,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBZRLEHeader class >> new [
	"Answer a new, empty ZRLE encoding header message."

	^super new: 4
]

{ #category : #accessing }
RFBZRLEHeader >> length [
	"Answer the length of zlib-compressed RLE data following this message."

	^self unsignedLongAt: 1
]

{ #category : #accessing }
RFBZRLEHeader >> length: n [
	"Set the length of zlib-compressed RLE data following this message."

	self unsignedLongAt: 1 put: n
]
