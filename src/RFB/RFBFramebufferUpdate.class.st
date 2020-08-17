"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBFramebufferUpdate,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBFramebufferUpdate class >> new [

	"RFBFramebufferUpdate new"

	^super
		new: 4					"type + pad[1] + CARD16(nrects)"
		type: RfbFramebufferUpdate
]

{ #category : #accessing }
RFBFramebufferUpdate >> nRects [
	"Answer the number of rectangles following this message."

	^self unsignedShortAt: 3
]

{ #category : #accessing }
RFBFramebufferUpdate >> nRects: nRects [
	"Set the number of rectangles to be sent/received in this message."

	self unsignedShortAt: 3 put: nRects
]
