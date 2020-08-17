"
I am a fragment of a RFBMessage representing an update in the RRE encoding.
"
Class {
	#name : #RFBRREHeader,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBRREHeader class >> new [
	"Answer a new, empty RRE encoding header message."

	^super new: 4
]

{ #category : #accessing }
RFBRREHeader >> nSubrects [
	"Answer the number of RRE-encoded rectangles that follow this message."

	^self unsignedLongAt: 1
]

{ #category : #accessing }
RFBRREHeader >> nSubrects: n [
	"Set the number of RRE-encoded rectangles that follow this message."

	self unsignedLongAt: 1 put: n
]
