"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBClientCutText,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBClientCutText class >> new [

	"RFBClientCutText new"

	^super
		new: 8					"card1(type) + pad(3) + card32(length)"
		type: RfbClientCutText
]

{ #category : #accessing }
RFBClientCutText >> length [
	"Answer the length of the byte data following this message."

	^self unsignedLongAt: 5
]

{ #category : #accessing }
RFBClientCutText >> length: anInteger [
	"Set the length of the byte data following this message."

	self unsignedLongAt: 5 put: anInteger
]
