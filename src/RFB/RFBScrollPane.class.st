"
I an a TwoWayScrollPane optimised for use with a RFBClient.
"
Class {
	#name : #RFBScrollPane,
	#superclass : #ScrollPane,
	#category : #'RFB-Viewer'
}

{ #category : #geometry }
RFBScrollPane >> contentBounds [
	"Answer the visible bounds of my contents in their local coordinate system."

	| box |
	box := scroller innerBounds translateBy: scroller transform offset.
	"Clip the corner since ScrollPane does not calculate its deltas properly and overshoots."
	^((box origin max: 0 @ 0) corner: (box corner min: scroller localSubmorphBounds corner)) truncated
]

{ #category : #geometry }
RFBScrollPane >> extent: aPoint [
	"Someone just resized the window.  Inform the model that it needs to refresh its contents in any newly-exposed areas."

	| prevBounds newBounds |
	(model isNil or: [model isActive not]) ifTrue: [^super extent: aPoint].
	prevBounds := self contentBounds.
	super extent: aPoint.
	newBounds := self contentBounds.
	model sendFullUpdateRequestForRegion: (newBounds areasOutside: prevBounds); changed
]

{ #category : #menu }
RFBScrollPane >> getMenu: shiftKeyState [
	"Answer a menu for the scrollbar button."

	^model getMenu: shiftKeyState
]

{ #category : #events }
RFBScrollPane >> handleMouseMove: anEvent [
	"Handle a motion event.  Override to always pass motion events to the client."

	model isActive ifFalse: [^super handleMouseMove: anEvent].
	anEvent wasHandled ifTrue:[^self]. "not interested"
	(anEvent hand hasSubmorphs) ifTrue:[^self].
	(anEvent anyButtonPressed and:[anEvent hand mouseFocus ~~ self]) ifTrue:[^self].
	anEvent wasHandled: true.
	self mouseMove: anEvent.
]

{ #category : #events }
RFBScrollPane >> handlesKeyboard: anEvent [
	"Answer whether we want to process keyboard input."

	^model isActive
]

{ #category : #events }
RFBScrollPane >> handlesMouseDown: evt [
	"Answer whether we want to handle the event."

	^model isActive and: [self innerBounds containsPoint: evt position]
]

{ #category : #events }
RFBScrollPane >> handlesMouseOver: evt [
	"Answer whether we are interested in mouse events."

	^model isActive and: [self handlesMouseDown: evt]
]

{ #category : #events }
RFBScrollPane >> keyDown: anEvent [
	"Pass the event to the client."

	model keyDown: anEvent
]

{ #category : #events }
RFBScrollPane >> keyStroke: anEvent [
	"Pass the event to the client."

	model keyStroke: anEvent
]

{ #category : #events }
RFBScrollPane >> keyUp: anEvent [
	"Pass the event to the client."

	model keyUp: anEvent
]

{ #category : #events }
RFBScrollPane >> mouseDown: evt [
	"Pass the event to the client."

	model mouseDown: (evt transformedBy: (scroller transformFrom: self))
]

{ #category : #events }
RFBScrollPane >> mouseEnter: evt [

	"model mouseEnter: evt"
]

{ #category : #events }
RFBScrollPane >> mouseLeave: evt [

	"model mouseLeave: evt"
]

{ #category : #events }
RFBScrollPane >> mouseMove: evt [
	"Pass the event to the client."

	model mouseMove: (evt transformedBy: (scroller transformFrom: self))
]

{ #category : #events }
RFBScrollPane >> mouseUp: evt [
	"Pass the event to the client."

	model mouseUp: (evt transformedBy: (scroller transformFrom: self))
]

{ #category : #accessing }
RFBScrollPane >> rfbClient: aClient [
	"Set the receiver's model."

	model := aClient
]

{ #category : #geometry }
RFBScrollPane >> xScrollBarValue: scrollValue [ 
	"The window just scrolled.  Pass the message up and then have the client update any newly-exposed regions."

	| prevBounds newBounds |
	prevBounds := self contentBounds.
	super xScrollBarValue: scrollValue.
	newBounds := self contentBounds.
	model sendFullUpdateRequestForRegion: (newBounds areasOutside: prevBounds)
]

{ #category : #geometry }
RFBScrollPane >> yScrollBarValue: scrollValue [
	"The window just scrolled.  Pass the message up and then have the client update any newly-exposed regions."

	| prevBounds newBounds |
	prevBounds := self contentBounds.
	super yScrollBarValue: scrollValue.
	newBounds := self contentBounds.
	model sendFullUpdateRequestForRegion: (newBounds areasOutside: prevBounds)
]
