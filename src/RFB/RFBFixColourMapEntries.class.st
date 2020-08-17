"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBFixColourMapEntries,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBFixColourMapEntries class >> firstColour: firstColour nColours: nColours [

	"RFBFixColourMapEntries firstColour: 0 nColours: 256"

	^(self new: nColours)
		firstColour: firstColour;
		nColours: nColours
]

{ #category : #'instance creation' }
RFBFixColourMapEntries class >> new [

	"RFBFixColourMapEntries new"

	^super
		new: 6					"card8(type) + pad[1] + CARD16(firstColour) + CARD16(nColours)
								+ card16[3*nColours]"
		type: RfbFixColourMapEntries
]

{ #category : #'instance creation' }
RFBFixColourMapEntries class >> new: nColours [

	"RFBFixColourMapEntries new: 42"

	^super
		new: 6					"card8(type) + pad[1] + CARD16(firstColour) + CARD16(nColours)"
			+ (6 * nColours)		"+ card16[3*nColours]"
		type: RfbFixColourMapEntries
]

{ #category : #accessing }
RFBFixColourMapEntries >> firstColour [
	"Answer the index of the first colour represented in the pixel data following this message."

	^self unsignedShortAt: 3
]

{ #category : #accessing }
RFBFixColourMapEntries >> firstColour: firstColour [
	"Set the first colour index in the pixel data following this message."

	self unsignedShortAt: 3 put: firstColour
]

{ #category : #accessing }
RFBFixColourMapEntries >> nColours [
	"Answer the number of colours represented in the pixel data following this message."

	^self unsignedShortAt: 5
]

{ #category : #accessing }
RFBFixColourMapEntries >> nColours: nColours [
	"Set the number of colours following this message."

	self unsignedShortAt: 5 put: nColours
]
