"
I am a kind of DisplayScreen that also forwards screen updates and beep requests to the active RFBServer.  I replace the usual Display whenever a RFBServer is running, and remove myself gracefully whenever the RFBServer is shut down.
"
Class {
	#name : #RFBDisplayScreen,
	#superclass : #DisplayScreen,
	#instVars : [
		'rfbServer',
		'colourMap'
	],
	#category : #'RFB-Server'
}

{ #category : #private }
RFBDisplayScreen >> argb8888ColourMap [
	"Answer a ColorMap that clears the alpha channel of all pixels to zero."

	^ColorMap shifts: #(0 0 0 0) masks: #(16rFFFFFF 0 0 0)
]

{ #category : #'user interface' }
RFBDisplayScreen >> beep [
	"Emit an audible warning sound on the local Display and on all remote Displays."

	Beeper beep.
	rfbServer isNil ifFalse: [rfbServer beep]
]

{ #category : #'user interface' }
RFBDisplayScreen >> beepPrimitive [
	"Emit an audible warning on the local Display and all remote viewers."

	Beeper beepPrimitive.
	rfbServer isNil ifFalse: [rfbServer beep]
]

{ #category : #private }
RFBDisplayScreen >> bgr233ColourMap [
	"Answer a ColorMap that maps pixels from 32-bit ARGB8888 space into the BGR233 space used by viewers running in 8-bit 'true colour' mode."

	^ColorMap colors:
		((Color cachedColormapFrom: 8 to: 32) collect: [:pv |
			((((pv bitShift: -16-5)) bitAnd: 7) bitShift: 0)
			bitOr: (((((pv bitShift: -8-5)) bitAnd: 7) bitShift: 3)
			bitOr: ((((pv bitShift: -0-6)) bitAnd: 3) bitShift: 6))])
]

{ #category : #bordering }
RFBDisplayScreen >> border: rect width: borderWidth rule: rule fillColor: fillColor [
	"Paint a border in the given rect and propagate the corresponding damage regions to all active remote viewers."

	| w h hx vx |
	super border: rect width: borderWidth rule: rule fillColor: fillColor.
	rfbServer isNil
		ifFalse:
		[w := rect width.
		 h := rect height.
		 hx := w @ borderWidth.
		 vx := borderWidth @ h.
		 rfbServer
			invalidate: (rect topLeft extent: hx);
			invalidate: (rect topLeft extent: vx);
			invalidate: (rect topRight - (borderWidth @ 0) extent: vx);
			invalidate: (rect bottomLeft - (0 @ borderWidth) extent: hx)]
]

{ #category : #displaying }
RFBDisplayScreen >> forceToScreen: aRectangle [
	"Force the contents of the Display within aRectangle to be drawn on the physical screen and in all remote viewers."

	super forceToScreen: aRectangle.
	rfbServer isNil ifFalse: [rfbServer invalidate: aRectangle]
]

{ #category : #private }
RFBDisplayScreen >> newDepthNoRestore: pixelDepth [
	"Change the depth of the receiver, propagating the change to all remote viewers."

	super newDepthNoRestore: pixelDepth.
	self setColourMap.
	rfbServer isNil ifFalse: [rfbServer newDepth: pixelDepth]
]

{ #category : #accessing }
RFBDisplayScreen >> rfbServer: server [
	"Set the receiver's RFB server."

	rfbServer := server.
	self setColourMap
]

{ #category : #private }
RFBDisplayScreen >> setColourMap [
	"Set the colourMap of the receiver based on its current depth.  If the depth is 32, use a colour map that clears the alpha channel (see #rgbContents: for the rationale).  If the depth is 8, use a colour map that converts Squeak's indexed pixel values into RFB's BGR233 pixel format."

	colourMap := depth == 32
		ifTrue: [self argb8888ColourMap]
		ifFalse:
			[depth == 8
				ifTrue: [self bgr233ColourMap]]
]
