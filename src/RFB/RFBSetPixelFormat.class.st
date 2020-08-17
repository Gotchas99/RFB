"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBSetPixelFormat,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBSetPixelFormat class >> new [

	"RFBSetPixelFormat new"

	^super
		new: 20					"type + pad[3] + pixelFormat"
		type: RfbSetPixelFormat
]

{ #category : #accessing }
RFBSetPixelFormat >> pixelFormat [
	"Answer the pixel format stored in the pixel format message represented by the receiver."

	^RFBPixelFormat fromByteArray: (self copyFrom: 5 to: 20)
]

{ #category : #accessing }
RFBSetPixelFormat >> pixelFormat: pixelFormat [
	"Set the pixel format in the message represented by the receiver."

	self replaceFrom: 5 to: 20 with: pixelFormat asByteArray
]
