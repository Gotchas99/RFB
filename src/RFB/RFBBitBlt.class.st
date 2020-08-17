"
I am a regular BitBlt with slightly modified behaviour:

	- I provide instance creation methods that work for 8-bit Forms that are RGB (rather than indexed, a rather gross assumption on the part of BitBlt)
	- I support filling areas with pixel values (rather than Colors)
	- I provide some additional accessing methods (to eliminate a few message sends here and there)
	- I take care to unhibernate my destForm correctly after snapshot (avoiding a nasty bug that affects cached ""bit peekers"")
"
Class {
	#name : #RFBBitBlt,
	#superclass : #BitBlt,
	#category : #'RFB-Server'
}

{ #category : #'instance creation' }
RFBBitBlt class >> bitFillerToForm: destForm [
	"Answer a BitBlt suitable for filling regions of destForm with pixel values (not Colors, regardless of the destForm depth)."

	destForm unhibernate.
	^self
		destForm: destForm
	 	sourceForm: nil
		halftoneForm: (Form extent: 1@1 depth: destForm depth)
		combinationRule: Form over
		destOrigin: 0@0
		sourceOrigin: 0@0
		extent: 1@1
		clipRect: destForm boundingBox
]

{ #category : #'instance creation' }
RFBBitBlt class >> bitPeekerFromForm: destForm [
	"Answer a BitBlt suitable for peeking pixel values out of destForm."

	^(super bitPeekerFromForm: destForm) colorMap: nil
]

{ #category : #'instance creation' }
RFBBitBlt class >> bitPokerToForm: destForm [
	"Answer a BitBlt suitable for poking pixel values into destForm."

	^(super bitPokerToForm: destForm) colorMap: nil
]

{ #category : #copying }
RFBBitBlt >> pixelsIn: aRectangle put: aPixel [
	"Fill aRectangle in destForm with aPixel."

	| depth pv |
	depth := halftoneForm depth.
	pv := aPixel.
	depth < 32
		ifTrue:
			[pv := pv bitOr: (pv bitShift: 16).
			 depth < 16 ifTrue: [pv := pv bitOr: (pv bitShift: 8)]].
	halftoneForm bits at: 1 put: pv.
	self destRect: aRectangle; copyBits
]

{ #category : #accessing }
RFBBitBlt >> sourceAndDestRect: aRectangle [
	"Set source and destination rectangles in one operation.  Avoids additional message sends."

	| origin corner x y |	
	origin := aRectangle origin.
	corner := aRectangle corner.
	sourceX := destX := (x := origin x).
	sourceY := destY := (y := origin y).
	width := corner x - x.
	height := corner y - y.
]

{ #category : #accessing }
RFBBitBlt >> sourceForm: aForm sourceAndDestRect: aRectangle [
	"Set the source form and the source and destination Ractangles.  Avoids several message sends."

	| origin corner x y |
	origin := aRectangle origin.
	corner := aRectangle corner.
	sourceForm := aForm.
	sourceX := destX := x := origin x.
	sourceY := destY := y := origin y.
	width := corner x - x.
	height := corner y - y.
]

{ #category : #accessing }
RFBBitBlt >> sourceX: x width: w [
	"Set the horizontal source position and the width.  Avoids an additional message send from inner loops."

	sourceX := x.
	width := w
]

{ #category : #accessing }
RFBBitBlt >> sourceY: y height: h [
	"Set the vertical source position and the height.  Avoids an additional message send from inner loops."

	sourceY := y.
	height := h
]

{ #category : #'fileIn/Out' }
RFBBitBlt >> unhibernate [

	"Unhibernate my destForm when coming back from snapshot.  Avoids a problem with pixelAt: storing zero in the first field of destForm bits, which might be a ByteArray when the form is hibernating."

	destForm isNil ifFalse: [destForm unhibernate]
]
