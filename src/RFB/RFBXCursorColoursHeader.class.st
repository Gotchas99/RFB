"
I am a fragment of a RFBMessage representing the foreground and background colours of a cursor shape.
"
Class {
	#name : #RFBXCursorColoursHeader,
	#superclass : #RFBMessage,
	#type : #bytes,
	#classVars : [
		'StandardCursorColours'
	],
	#category : #'RFB-Messages'
}

{ #category : #'class initialisation' }
RFBXCursorColoursHeader class >> initialize [

	"RFBXCursorColoursHeader initialize"

	StandardCursorColours := self new
		foreRed: 0 foreGreen: 0 foreBlue: 0
		backRed: 255 backGreen: 255 backBlue: 255
]

{ #category : #'instance creation' }
RFBXCursorColoursHeader class >> new [
	"Answer a new, empty cursor colours header message."

	^self new: 6
]

{ #category : #constants }
RFBXCursorColoursHeader class >> standardColours [
	"Answer a cursor colours header message describing the standard cursor colours: white background, black foreground."

	^StandardCursorColours
]

{ #category : #accessing }
RFBXCursorColoursHeader >> foreRed: fr foreGreen: fg foreBlue: fb backRed: br backGreen: bg backBlue: bb [
	"Set the receiver's foreground and background pixel colours."

	self
		byteAt: 1 put: fr;
		byteAt: 2 put: fg;
		byteAt: 3 put: fb;
		byteAt: 4 put: br;
		byteAt: 5 put: bg;
		byteAt: 6 put: bb
]
