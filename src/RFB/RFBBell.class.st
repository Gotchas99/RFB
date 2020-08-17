"
I am a kind of RFBMessage.  See the comment in that class for more information.
"
Class {
	#name : #RFBBell,
	#superclass : #RFBMessage,
	#type : #bytes,
	#category : #'RFB-Messages'
}

{ #category : #'instance creation' }
RFBBell class >> new [

	"RFBBell new"

	^super
		new: 1					"card1(type)"
		type: RfbBell
]
