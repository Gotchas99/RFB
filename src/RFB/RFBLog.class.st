"
I am the global log for the RFBServer.
"
Class {
	#name : #RFBLog,
	#superclass : #Object,
	#classVars : [
		'DumpLogToTranscript',
		'Log'
	],
	#category : #'RFB-Server'
}

{ #category : #'as yet unclassified' }
RFBLog class >> contents [
	^ Log contents
]

{ #category : #'as yet unclassified' }
RFBLog class >> dumpLogToTranscript: aBoolean [
	^ DumpLogToTranscript := aBoolean
]

{ #category : #'as yet unclassified' }
RFBLog class >> initialize [
	self dumpLogToTranscript: false.
	self resetLog.
	
]

{ #category : #'as yet unclassified' }
RFBLog class >> log: aMessage [
	"RFBLog log: 'a message'"

	Log nextPutAll: aMessage; cr.
	
	"If enabled, also dumps the message to the transcript"
	DumpLogToTranscript ifTrue: [ Transcript nextPutAll: aMessage; cr; endEntry ].
]

{ #category : #'as yet unclassified' }
RFBLog class >> resetLog [
	Log := WriteStream on: (String new: 32)
]
