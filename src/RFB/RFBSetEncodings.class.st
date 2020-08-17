"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBSetEncodings,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBSetEncodings class >> new [

	"RFBSetEncodings new"

	^super
		new: 4					"type + pad[1] + nEncodings"
		type: RfbSetEncodings
]

{ #category : #'instance creation' }
RFBSetEncodings class >> new: nEncodings [

	"RFBSetEncodings new: 3"

	^(super
		new: 4 + (nEncodings * 4)		"type + pad[1] + nEncodings + CARD32[nEncodings]"
		type: RfbSetEncodings)
		nEncodings: nEncodings;
		yourself
]

{ #category : #accessing }
RFBSetEncodings >> encodingAt: index [
	"Answer the 32-bit encoding number stored in the receiver at the given index.  The index is 1-relative and counts encodings, not bytes."

	^self unsignedLongAt: 1 + (index * 4)
]

{ #category : #accessing }
RFBSetEncodings >> encodingAt: index put: encoding [
	"Store the encoding in the receiver at the given index.  The index is 1-relative and counts encodings, not bytes."

	^self unsignedLongAt: 1 + (index * 4) put: encoding
]

{ #category : #accessing }
RFBSetEncodings >> nEncodings [
	"Answer the number of encodings stored in the receiver."

	^self unsignedShortAt: 3
]

{ #category : #accessing }
RFBSetEncodings >> nEncodings: anInteger [
	"Set the number of encodings stored in the receiver."

	^self unsignedShortAt: 3 put: anInteger
]
