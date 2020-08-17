"
I am a SystemWindow with additional support for working with RFBClients.
"
Class {
	#name : #RFBSystemWindow,
	#superclass : #SystemWindow,
	#category : #'RFB-Viewer'
}

{ #category : #'event handling' }
RFBSystemWindow >> blueButtonDown: anEvent [
	"Pass the event to the client.  Override to avoid halo."

	(model isActive and: [model blueButtonDown: anEvent])
		ifFalse: [^super blueButtonDown: anEvent]
]

{ #category : #'event handling' }
RFBSystemWindow >> blueButtonUp: anEvent [
	"Pass the event to the client only if active."

	(model isActive and: [model blueButtonUp: anEvent])
		ifFalse: [^super blueButtonDown: anEvent]
]

{ #category : #'as yet unclassified' }
RFBSystemWindow >> buildWindowMenu [
	^ model getMenu: super buildWindowMenu 
]

{ #category : #submorphs }
RFBSystemWindow >> delete [
	"Abort the client's connection before closing the window."

	model abort.
	^super delete
]
