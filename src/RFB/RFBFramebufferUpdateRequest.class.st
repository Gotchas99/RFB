"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBFramebufferUpdateRequest,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBFramebufferUpdateRequest class >> bounds: boundingBox incremental: incrementalFlag [
	"Answer a framebuffer update request for the given boundingBox."
	"RFBFramebufferUpdateRequest bounds: (10@20 extent: 30@40) incremental: true"

	^self new bounds: boundingBox incremental: incrementalFlag
]

{ #category : #'instance creation' }
RFBFramebufferUpdateRequest class >> new [

	"RFBFramebufferUpdateRequest new"

	^super
		new: 10					"type + incremental + x y w h"
		type: RfbFramebufferUpdateRequest
]

{ #category : #accessing }
RFBFramebufferUpdateRequest >> bounds: boundingBox incremental: incrementalFlag [
	"Set the bounds of the update request."

	self
		byteAt: 2 put: (incrementalFlag ifTrue: [1] ifFalse: [0]);
		unsignedShortAt: 3 put: boundingBox left;
		unsignedShortAt: 5 put: boundingBox top;
		unsignedShortAt: 7 put: boundingBox width;
		unsignedShortAt: 9 put: boundingBox height
]

{ #category : #accessing }
RFBFramebufferUpdateRequest >> h [
	"Answer the height of the update represented by the receiver."

	^self unsignedShortAt: 9
]

{ #category : #accessing }
RFBFramebufferUpdateRequest >> incremental [
	"Answer whether the update represented by the receiver is incremental.  Incremental updates are just that: updates.  The server is free to send less data than requested if no damage has occurred in the requested region.  Non-incremental updates are to repair pixels lost in the viewer, and all requested data should be sent."

	^(self byteAt: 2) ~~ 0
]

{ #category : #accessing }
RFBFramebufferUpdateRequest >> w [
	"Answer the width of the update represented by the receiver."

	^self unsignedShortAt: 7
]

{ #category : #accessing }
RFBFramebufferUpdateRequest >> x [
	"Answer the x coordinate of the update represented by the receiver."

	^self unsignedShortAt: 3
]

{ #category : #accessing }
RFBFramebufferUpdateRequest >> y [
	"Answer the y coordinate of the update represented by the receiver."

	^self unsignedShortAt: 5
]
