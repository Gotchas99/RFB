"
We (myself and my subclasses) represent a message sent to, or received from, a remote RFB viewer.  We implement accessing protocol that makes it easy to read and write the fields within messages, but we are also a kind of ByteArray (which makes it east to read and write us over a network connection).
"
Class {
	#name : #RFBMessage,
	#superclass : #ByteArray,
	#type : #bytes,
	#classVars : [
		'RfbBell',
		'RfbClientCutText',
		'RfbConnFailed',
		'RfbFixColourMapEntries',
		'RfbFramebufferUpdate',
		'RfbFramebufferUpdateRequest',
		'RfbKeyEvent',
		'RfbNoAuth',
		'RfbPointerEvent',
		'RfbServerCutText',
		'RfbSetColourMapEntries',
		'RfbSetEncodings',
		'RfbSetPixelFormat',
		'RfbVncAuth',
		'RfbVncAuthFailed',
		'RfbVncAuthOK',
		'RfbVncAuthTooMany'
	],
	#category : #'RFB-Messages'
}

{ #category : #'class initialisation' }
RFBMessage class >> initialize [
	"RFBMessage initialize"

	"Handshake message opcodes."
	RfbConnFailed := 0.
	RfbNoAuth := 1.
	RfbVncAuth := 2.

	"Authentication message opcodes."
	RfbVncAuthOK := 0.
	RfbVncAuthFailed := 1.
	RfbVncAuthTooMany := 2.

	"Server -> Client message types."
	RfbFramebufferUpdate := 0.
	RfbSetColourMapEntries := 1.
	RfbBell := 2.
	RfbServerCutText := 3.

	"Client -> Server message types."
	RfbSetPixelFormat := 0.
	RfbFixColourMapEntries := 1.
	RfbSetEncodings := 2.
	RfbFramebufferUpdateRequest := 3.
	RfbKeyEvent := 4.
	RfbPointerEvent := 5.
	RfbClientCutText := 6
]

{ #category : #'instance creation' }
RFBMessage class >> new [
	"Answer a new, empty message.  Only my subclasses know how big each kind of message should be, so always defer to them."

	^self subclassResponsibility
]

{ #category : #handshake }
RFBMessage class >> new: size opcode: opcode [

	"RFBMessage new: 4 opcode: 42"

	^(super new: size) unsignedLongAt: 1 put: opcode; yourself
]

{ #category : #protocol }
RFBMessage class >> new: size type: type [
	"Answer an empty normal message of the given size and type."

	^(super new: size) type: type
]

{ #category : #handshake }
RFBMessage class >> newConnFailed: reason [
	"RFBMessage newConnFailed: 'no idea why'"

	^(self new: 8 + reason size opcode: RfbConnFailed)
		unsignedLongAt: 5 put: reason size;
		replaceFrom: 9 to: 8 + reason size with: reason
]

{ #category : #handshake }
RFBMessage class >> newNoAuth [
	"RFBMessage newNoAuth"

	^self new: 4 opcode: RfbNoAuth
]

{ #category : #handshake }
RFBMessage class >> newVncAuth: challenge [
	"RFBMessage newVncAuth: ((ByteArray new: 16) atAllPut: 42)"

	^(self
		new: 20					"card32(rfbVncAuth) + card8[16](challenge)"
		opcode: RfbVncAuth)
		replaceFrom: 5 to: 20 with: challenge
]

{ #category : #handshake }
RFBMessage class >> newVncAuthFailed [
	"RFBMessage newVncAuthFailed"

	^self new: 4 opcode: RfbVncAuthFailed
]

{ #category : #handshake }
RFBMessage class >> newVncAuthOK [
	"RFBMessage newVncAuthOK"

	^self new: 4 opcode: RfbVncAuthOK
]

{ #category : #protocol }
RFBMessage class >> protocolVersionMajor: majorNumber minor: minorNumber [
	"Answer a protocol version string suitable for exchange during handshake."
	"RFBMessage protocolVersionMajor: 42 minor: 666"

	| protocolVersion major minor |
	(protocolVersion := 'RFB 000.000 ' copy) at: 12 put: Character lf.
	major := majorNumber printString.
	minor := minorNumber printString.
	protocolVersion
		replaceFrom: 8 - major size to: 7 with: major;
		replaceFrom: 12 - minor size to: 11 with: minor.
	^protocolVersion
]

{ #category : #constants }
RFBMessage class >> rfbNoAuth [
	"Answer the number representing authentication/security type 'none'."

	^RfbNoAuth
]

{ #category : #constants }
RFBMessage class >> rfbVncAuth [
	"Answer the number representing authentication/security type 'VNC'."

	^RfbVncAuth
]

{ #category : #constants }
RFBMessage class >> rfbVncAuthOK [
	"Answer the opcode representing authentication success."

	^RfbVncAuthOK
]

{ #category : #handshake }
RFBMessage >> opcode [
	"Answer the 4-byte opcode of the connection handshake message represented by the receiver."

	^self unsignedLongAt: 1
]

{ #category : #handshake }
RFBMessage >> opcode: card32 [
	"Set the opcode of the protocol handshake message represented by the receiver."

	self unsignedLongAt: 1 put: card32
]

{ #category : #comparing }
RFBMessage >> species [
	"Answer the class in which RFBMessage should be copied and compared."

	^ByteArray
]

{ #category : #protocol }
RFBMessage >> type [
	"Answer the (1-byte) type of the normal message represented by the receiver."

	^self byteAt: 1
]

{ #category : #protocol }
RFBMessage >> type: card8 [
	"Set the type of the normal message represented by the receiver."

	self byteAt: 1 put: card8
]

{ #category : #accessing }
RFBMessage >> unsignedLongAt: index [
	"Answer the CARD32 data stored in the receiver at the given 1-relative index."

	^self unsignedLongAt: index bigEndian: true
]

{ #category : #accessing }
RFBMessage >> unsignedLongAt: index put: value [
	"Store a CARD32 value into the receiver at the given 1-relative index."

	^self unsignedLongAt: index put: value bigEndian: true
]

{ #category : #accessing }
RFBMessage >> unsignedShortAt: index [
	"Answer the CARD16 data at the given 1-relative index in the receiver."

	^self unsignedShortAt: index bigEndian: true
]

{ #category : #accessing }
RFBMessage >> unsignedShortAt: index put: value [
	"Store a CARD16 value into the receiver at the given 1-relative index."

	^self unsignedShortAt: index put: value bigEndian: true
]
