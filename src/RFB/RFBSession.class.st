"
I am an active RFB session between a remote viewer and this image.  I implement the full version 3.7 RFB protocol (which is the most recent specification published by RealVNC.com), as well as some of the extensions defined by the popular 'TightVNC' viewer.

You should not instantiate me directly.  See the class comment in RFBServer for further details.

"
Class {
	#name : #RFBSession,
	#superclass : #Object,
	#instVars : [
		'server',
		'socket',
		'process',
		'state',
		'protocolMinor',
		'interactive',
		'reverseConnection',
		'readyForSetColourMapEntries',
		'preferredEncoding',
		'sendRect',
		'countRects',
		'correMaxWidth',
		'correMaxHeight',
		'authChallenge',
		'modifiedRegion',
		'requestedRegion',
		'format',
		'zlibCompressLevel',
		'zlibStream',
		'enableLastRectEncoding',
		'enableCursorShapeUpdates',
		'enableCursorPosUpdates',
		'useRichCursorEncoding',
		'modifiers',
		'updateProcess',
		'updateSemaphore',
		'currentCursor',
		'clientCursor',
		'mousePosition',
		'clientPosition',
		'fixColourMapEntries',
		'framebufferUpdateRequest',
		'framebufferUpdate',
		'updateRectHeader',
		'keyEvent',
		'pointerEvent',
		'clientCutText',
		'rreHeader',
		'zrleHeader',
		'xCursorColoursHeader',
		'rfbStream',
		'damageFilter',
		'incremental',
		'allocationCount',
		'bytesLeft',
		'updateCount',
		'lowWaterMark',
		'highWaterMark',
		'meanSeaLevel',
		'updateTime',
		'totalTime'
	],
	#classVars : [
		'Encodings',
		'KeyCodesFF',
		'Logging',
		'MessageTypes',
		'ModifierMap',
		'ProtocolMajor',
		'ProtocolMinor',
		'ProtocolVersion',
		'RfbEncodingCoRRE',
		'RfbEncodingCopyRect',
		'RfbEncodingHextile',
		'RfbEncodingLastRect',
		'RfbEncodingPointerPos',
		'RfbEncodingRRE',
		'RfbEncodingRaw',
		'RfbEncodingRichCursor',
		'RfbEncodingTight',
		'RfbEncodingXCursor',
		'RfbEncodingZRLE',
		'RfbEncodingZlib',
		'RfbEncodingZlibHex',
		'SecurityTypeNone',
		'SecurityTypeVNC',
		'SpecialEncodings',
		'UseLastRect'
	],
	#pools : [
		'EventSensorConstants'
	],
	#category : #'RFB-Server'
}

{ #category : #'class initialisation' }
RFBSession class >> initialiseKeyCodes [
	"Initialise the tables used to map incoming key event codes to MacRoman characters, and the viewer's modifier key bits to local modifier bits."
	"RFBSession initialize"

	"The viewer sends 16-bit X11R6 keysyms.  There are hundreds of these.  The following are just the most common."
	KeyCodesFF := Array new: 256.
	#(	(16r08 8)	"bs"
		(16r09 9)	"tab"
		(16r0A 10)	"lf"
		(16r0D 13)	"cr"
		(16r1B 27)	"esc"
		(16r50 1)		"home (new keycode)"
		(16r51 28)	"left"
		(16r52 30)	"up"
		(16r53 29)	"right"
		(16r54 31)	"down"
		(16r55 11)	"prior"
		(16r56 12)	"next"
		(16r57 4)		"end"
		(16rE1 -1)	"shift:=l"
		(16rE2 -1)	"shift:=r"
		(16rE3 -2)	"control:=l"
		(16rE4 -2)	"control:=r"
		(16rE5 -3)	"caps lock"
		(16rE7 -4)	"meta:=l"
		(16rE8 -4)	"meta:=r"
		(16rE9 -5)	"alt:=l"
		(16rEA -5)	"alt:=r"
		(16rFF 127)	"del"
	) do: [:posKey | KeyCodesFF at: posKey first put: posKey second].
	"The following works well for Apple keyboards.  Anyone who doesn't have an Apple keyboard may well suffer from a classic case of garbage-in, garbage-out"
	(ModifierMap := Array new: 5)
		at: 1 put: ShiftKeyBit;
		at: 2 put: CtrlKeyBit;
		at: 3 put: 0;
		at: 4 put: CommandKeyBit;
		at: 5 put: CommandKeyBit 	"Should be OptionKeyBit, but Windoze is broken."
]

{ #category : #'class initialisation' }
RFBSession class >> initialize [
	"RFBSession initialize"

	ProtocolMajor := 3.
	ProtocolMinor := 7.
	ProtocolVersion := RFBMessage protocolVersionMajor: ProtocolMajor minor: ProtocolMinor.
	Logging := false.

	MessageTypes := #(
		"0"	rfbSetPixelFormat
		"1"	rfbFixColourMapEntries
		"2"	rfbSetEncodings
		"3"	rfbFramebufferUpdateRequest
		"4"	rfbKeyEvent
		"5"	rfbPointerEvent
		"6"	rfbClientCutText).

	(Encodings := Dictionary new)				"allow for gaps and LargeInts"
		"rfb 3.3"
		at: (RfbEncodingRaw		:= 0) put: #rfbEncodingRaw;
		at: (RfbEncodingCopyRect	:= 1) put: #rfbEncodingCopyRect;
		at: (RfbEncodingRRE			:= 2) put: #rfbEncodingRRE;
		at: (RfbEncodingCoRRE		:= 4) put: #rfbEncodingCoRRE;
		at: (RfbEncodingHextile		:= 5) put: #rfbEncodingHextile;
		"tight vnc"
		at: (RfbEncodingZlib			:= 6) put: #rfbEncodingZlib;
		at: (RfbEncodingTight		:= 7) put: #rfbEncodingTight;
		at: (RfbEncodingZlibHex		:= 8) put: #rfbEncodingZlibHex;
		"protocol version 3.7"
		at: (RfbEncodingZRLE		:= 16) put: #rfbEncodingZRLE;
		"special encodings"
		at: (RfbEncodingXCursor		:= 16rFFFFFF10) put: #rfbEncodingXCursor;
		at: (RfbEncodingRichCursor	:= 16rFFFFFF11) put: #rfbEncodingRichCursor;
		at: (RfbEncodingPointerPos	:= 16rFFFFFF18) put: #rfbEncodingPointerPos;
		at: (RfbEncodingLastRect	:= 16rFFFFFF20) put: #rfbEncodingLastRect.

	(SpecialEncodings := IdentityDictionary new)			"allow for gaps"
		at: 0	put: #rfbEncodingCompressLevel:;
		at: 14	put: #rfbEncodingQualityLevel:.

	SecurityTypeNone := 1.
	SecurityTypeVNC := 2.

	UseLastRect := 16rFFFF.

	self initialiseKeyCodes
]

{ #category : #logging }
RFBSession class >> logging [
	"Answer whether informational messages are logged or not."

	^Logging
]

{ #category : #logging }
RFBSession class >> logging: loggingFlag [
	"Set the flag that controls whether informational messages are logged or not."

	Logging := loggingFlag
]

{ #category : #'instance creation' }
RFBSession class >> withServer: rfbServer socket: aSocket reverse: reverseFlag [
	"Answer a new RFBSession for the given rfbServer, communicating with the remote viewer over aSocket."

	^self new initServer: rfbServer socket: aSocket reverse: reverseFlag
]

{ #category : #private }
RFBSession >> abort [
	"Something very bad happened.  Give up immediately.  Serious developer lossage."

	self log: 'aborted'.
	socket closeAndDestroy.
]

{ #category : #authenticating }
RFBSession >> authenticateClient [
	"Authenticate the client according to our stored password.  The details of the exchange depend on the minor version."

	protocolMinor <= 5 ifTrue: [^self authenticateClient3v3].
	protocolMinor <= 7 ifTrue: [^self authenticateClient3v7].
	self log: 'minor protocol version ', protocolMinor printString, ' not supported'.
	socket close
]

{ #category : #authenticating }
RFBSession >> authenticateClient3v3 [
	"Authenticate the client according to our stored password using version 3.3 protocol.  If it is nil, tell the client to continue without authentication.  Otherwise insist on VNC-style 3DES challenge-response authentication."

	server hasPassword
		ifTrue:
			[authChallenge := self randomBytes.
			 socket sendData: (RFBMessage newVncAuth: authChallenge).
			 state := #rfbAuthentication]
		ifFalse:
			[socket sendData: (RFBMessage newNoAuth).
			 state := #rfbInitialisation]
]

{ #category : #authenticating }
RFBSession >> authenticateClient3v7 [
	"Authenticate the client according to our stored password using version 3.7 protocol.  If it is nil, tell the client to continue without authentication.  Otherwise insist on VNC-style 3DES challenge-response authentication."

	socket sendData:
		((RFBMessage new: 2)
			at: 1 put: 1;							"Number of security types."
			at: 2 put: (server hasPassword
						ifTrue: [SecurityTypeVNC]
						ifFalse: [SecurityTypeNone]);
			yourself).
	state := #rfbSecurityType
]

{ #category : #'display events' }
RFBSession >> beep [
	"The Display has just beeped.  Tell the viewer to beep too."

	self sendBell
]

{ #category : #private }
RFBSession >> beginUpdate [
	"Just about to send a screen update message.  If we're logging memory usage, note initial conditions."

	server enableMemoryLog ifFalse: [^self].
	allocationCount := SmalltalkImage current vmParameterAt: 5.
	bytesLeft := Smalltalk garbageCollectMost; primBytesLeft.
	updateTime := Time millisecondClockValue.
]

{ #category : #'encoding-corre' }
RFBSession >> countRectsEncodingCoRRE: region [
	"Answer the number of update rectangles that will be generated for the given region using compressed RRE encoding."

	| nRects |
	nRects := 0.
	region do: [:rect |
		nRects := nRects
			+ (((rect width - 1) // correMaxWidth + 1)
				* ((rect height - 1) // correMaxHeight + 1))].
	^nRects
]

{ #category : #'encoding-hextile' }
RFBSession >> countRectsEncodingHextile: region [
	"Answer the number of update rectangles that will be generated for an update of the given region using hextile encoding."

	^region size
]

{ #category : #'encoding-rre' }
RFBSession >> countRectsEncodingRRE: region [
	"Answer the number of update rectangles that will be generated for the given region using RRE encoding."

	^region size
]

{ #category : #'encoding-raw' }
RFBSession >> countRectsEncodingRaw: region [
	"Answer the number of update rectangles that will be generated for the given region using raw encoding."

	^region size
]

{ #category : #'encoding-zrle' }
RFBSession >> countRectsEncodingZRLE: region [
	"Answer the number of update rectangles that will be generated for an update of the given region using ZRLE encoding."

	^region size
]

{ #category : #'display events' }
RFBSession >> currentCursor: newCursor [
	"Squeak just changed the cursor shape.  Note the new shape and schedule an update message, if the viewer is at all interested in these things."

	(enableCursorShapeUpdates and: [ clientCursor ~~ newCursor ])
		ifTrue:
			[currentCursor := newCursor.
			 updateSemaphore signal]
]

{ #category : #'client state' }
RFBSession >> decodeButtons: mask modified: modifierMask [
	"Convert the RFB button mask into a Squeak button mask taking the current modifierMask into account for yellow/blue button equivalence.  Answer an Integer with the low 3 bits containing the Squeak button mask and bits 4 and higher containing a copy of modifierMask with any equivalence modifier(s) removed."
	"Note #1: button1 + Ctrl = yellow and button1 + Cmnd = blue, however, some idiot at some time swapped them in the EventSensorConstants.  Grrr."
	"Note #2: this is, depressingly, identical to a bunch of code I've written in every single display driver that exists for Unix Squeak.  Why can't EventSensor figure all of this stuff out?  Ho hum."

	"#(1 2 4 8) collect: [:b | RFBSession new decodeButtons: b]"

	| buttons modified |
	buttons := 0.
	modified := modifierMask.
	#((1 2) (2 0) (4 -2)) do:
		[:maskShift |
		 buttons := buttons bitOr: ((mask bitAnd: maskShift first) bitShift: maskShift second)].
	buttons == RedButtonBit
		ifTrue:
			[(modified anyMask: CtrlKeyBit)
				ifTrue:
					[buttons := BlueButtonBit.								"YELLOW button"
					 modified := modified bitXor: CtrlKeyBit]
			 	ifFalse:
					[(modified anyMask: CommandKeyBit)
						ifTrue:
							[buttons := YellowButtonBit.						"BLUE button"
							 modified := modified bitXor: CommandKeyBit]]].
	^buttons bitOr: (modified bitShift: 3)
]

{ #category : #'client state' }
RFBSession >> decodeKey: keysym [
	"Answer the MacRoman character code corresponding to the given X11 keysym.  Note: we don't attempt any of the clever stuff suggested in the RFB protocol specification related to dealing with bizarre modifier key behaviour on some keyboards."

	keysym < 128 ifTrue: [^keysym].
	(keysym bitShift: -8) == 16rFF ifTrue: [^KeyCodesFF at: (keysym bitAnd: 16rFF)].
	^nil
]

{ #category : #printing }
RFBSession >> description [
	"Answer a description of the receiver's session."

	^String streamContents: [:stream |
		stream
			nextPutAll: socket peerName;
			nextPutAll: ' (';
			nextPutAll: (NetNameResolver stringFromAddress: socket remoteAddress);
			nextPutAll: '), ';
			nextPutAll: (interactive ifTrue: ['interactive'] ifFalse: ['view only']);
			nextPutAll: ', prefers ';
			nextPutAll: preferredEncoding.
		server enableMemoryLog
			ifTrue:
				[stream
					cr; tab;
					nextPutAll: 'conserve memory: '; print: server conserveMemory;
					nextPutAll: ', damage filter: '; print: damageFilter notNil;
					nextPutAll: ', filter raw encoding: '; print: server enableRawFilter;
					cr; tab;
					print: updateCount; nextPutAll: ' updates in ';
					print: totalTime; nextPutAll: 'ms (';
					print: totalTime // updateCount; nextPutAll: 'ms per update)';
					cr; tab;
					nextPutAll: 'heap per update: ';
					print: lowWaterMark; nextPutAll: ' min, ';
					print: highWaterMark; nextPutAll: ' max, ';
					print: meanSeaLevel // updateCount; nextPutAll: ' average'.
				 meanSeaLevel := updateCount := 0.
				 lowWaterMark := highWaterMark := nil]]
]

{ #category : #private }
RFBSession >> desktopName [
	"Answer the name of the desktop, constructed from the image, host and platform names."
	"RFBSession new desktopName"

	^String streamContents: [:stream |
		stream
			nextPutAll: self imagePath asFileReference basename;
			nextPut: $@;
			nextPutAll: server localHostName;
			nextPutAll: ' [';
			nextPutAll: Smalltalk os name; space; nextPutAll: Smalltalk os version;
			nextPut: $].
		interactive ifFalse: [stream nextPutAll: ' - view only']]
]

{ #category : #private }
RFBSession >> endUpdate [
	"Just sent a screen update.  If we're logging memory usage, update the cumulative counters accordingly."

	| bytesUsed |
	server enableMemoryLog ifFalse: [^self].
	totalTime := totalTime + (Time millisecondsSince: updateTime).
	bytesUsed := bytesLeft - Smalltalk primBytesLeft.		"A vague approximation, at best..."
	SmalltalkImage current vmParameterAt: 5 put: allocationCount.
	bytesUsed < 0 ifTrue: [Beeper beepPrimitive.  ^self].
	updateCount := updateCount + 1.
	meanSeaLevel := meanSeaLevel + bytesUsed.
	lowWaterMark isNil
		ifTrue: [lowWaterMark := highWaterMark := bytesUsed]
		ifFalse:
			[lowWaterMark := lowWaterMark min: bytesUsed.
			 highWaterMark := highWaterMark max: bytesUsed]
]

{ #category : #private }
RFBSession >> fragmentRegion: rectangleList [
	"The user has a really small computer with only a few Kbytes to spare.  Break the update region into smaller chunks so as to avoid swapping pages out to drum or magtape."

	| partySnax count delta bottom |
	partySnax := OrderedCollection new.
	rectangleList do:
		[:rect |
		 rect area <= 16384
			ifTrue: [partySnax add: rect]
			ifFalse:
				[count := rect area // 16384 + 1.
				 delta := rect height // count max: 1.
				 rect top to: rect bottom - 1 by: delta do:
					[:y |
					 bottom := y + delta min: rect bottom.
					 partySnax add: ((rect left @ y) corner: (rect right @ bottom))]]].
	^partySnax
]

{ #category : #private }
RFBSession >> imagePath [
	"avoid deprecation warning through change from imageName to imagePath"
	^ (SmalltalkImage current respondsTo: #imagePath)
		ifTrue: [ SmalltalkImage current imagePath ]
		ifFalse: [ SmalltalkImage current imageName ]
]

{ #category : #'initialize-release' }
RFBSession >> initServer: rfbServer socket: aSocket reverse: reverseFlag [
	"RFBSession withServer: nil socket: 42"

	server := rfbServer.
	socket := aSocket.
	state := #rfbProtocolVersion.
	interactive := true.
	reverseConnection := reverseFlag.
	readyForSetColourMapEntries := false.
	correMaxWidth := 48.
	correMaxHeight := 48.
	modifiedRegion := RFBRegion new.
	requestedRegion := 0@0 extent: 0@0.
	format := RFBPixelFormat serverFormat.
	rfbStream := format rfbStream.
	enableCursorShapeUpdates := false.
	enableCursorPosUpdates := false.
	enableLastRectEncoding := false.
	zlibCompressLevel := 5.
	modifiers := 0.
	updateSemaphore := Semaphore new.
	updateProcess := [self updateLoop] forkAt: server sessionPriority.
	currentCursor := Cursor currentCursor.
	clientCursor := nil.
	mousePosition := nil.
	clientPosition := -1 @ -1.

	fixColourMapEntries := RFBFixColourMapEntries new.
	framebufferUpdateRequest := RFBFramebufferUpdateRequest new.
	framebufferUpdate := RFBFramebufferUpdate new.
	updateRectHeader := RFBFramebufferUpdateRectHeader new.
	keyEvent := RFBKeyEvent new.
	pointerEvent := RFBPointerEvent new.
	clientCutText := RFBClientCutText new.
	rreHeader := RFBRREHeader new.
	zrleHeader := RFBZRLEHeader new.
	xCursorColoursHeader := RFBXCursorColoursHeader new.

	damageFilter := server enableDamageFilter ifTrue: [RFBDamageFilter forDisplay].
	incremental := true.

	updateCount := 0.
	meanSeaLevel := 0.
	totalTime := 0.

	self log: 'initialised'.
	server isNil ifFalse: [server addSession: self]
]

{ #category : #'display events' }
RFBSession >> invalidate: aRectangle [
	"Add aRectangle to the region modified since the last update message was sent.  Signal the updateSemaphore to nudge the update process into sending a framebuffer update message sometime in the near future."

	modifiedRegion add: aRectangle.
	updateSemaphore signal
]

{ #category : #private }
RFBSession >> log: aString [
	"Write aString to the server log."

	^Logging ifTrue: [RFBLog log: 'RFBSession ' , aString] ifFalse: [aString]
]

{ #category : #'display events' }
RFBSession >> mousePosition: aPoint [
	"The local pointer has moved.  If the viewer has registered an interest in cursor position updates, store the new location for inclusion in the next update message sent."

	(enableCursorPosUpdates and: [ clientPosition ~= aPoint ])
		ifTrue:
			[mousePosition := aPoint.
			 updateSemaphore signal]
]

{ #category : #'display events' }
RFBSession >> newDepth: depth [
	"The Squeak Display has just changed depth.  Reinitialise the pixel format and screen damage filter (both of which depend on the Display depth) and ensure that the next update will not filter any damage from the screen (which Squeak is about to redraw)."

	format setMaps.
	damageFilter isNil ifFalse: [damageFilter := RFBDamageFilter forDisplay].
	incremental := false.
]

{ #category : #'client state' }
RFBSession >> processMetaKey: key down: down [
	"Update our idea of the modifier key state in the viewer."

	| mod |
	mod := ModifierMap at: key.
	modifiers := down
		ifTrue: [modifiers bitOr: mod]
		ifFalse: [modifiers bitAnd: (mod bitXor: 16rFF)].
]

{ #category : #authenticating }
RFBSession >> randomBytes [
	"RFBSession new randomBytes"

	| random |
	random := Random seed: (Time millisecondClockValue).
	^((1 to: 16) collect: [:i | (random next * 256) truncated]) asByteArray
]

{ #category : #'initialize-release' }
RFBSession >> release [
	"Release the session.  The main purpose of this is to ensure that neither the input nor the output process (or anything else) ever touch server or socket again."

	updateProcess terminate.
	process == Processor activeProcess ifFalse: [process terminate].
	server isNil ifFalse: [server removeSession: self].
	damageFilter isNil ifFalse: [damageFilter release].
	server := nil.
	socket := nil.
	modifiedRegion := nil.
	zlibStream := nil.
	rfbStream := nil.
	damageFilter := nil.
	self log: 'released'.
]

{ #category : #'message dispatching' }
RFBSession >> rfbAuthentication [
	"Read and process an incoming protocol authentication message."

	| response |
	response := socket receiveData: (RFBMessage new: 16).
	interactive := server authenticateChallenge: authChallenge response: response.
	interactive isNil
		ifTrue:
			[self log: 'authentication failed'.
			 socket sendData: RFBMessage newVncAuthFailed.
			 ^socket close].
	socket sendData: RFBMessage newVncAuthOK.
	state := #rfbInitialisation
]

{ #category : #'client messages' }
RFBSession >> rfbClientCutText [
	"Read and process a client cut text message from the viewer."

	| msg text |
	self log: 'received rfbClientCutText'.
	msg := socket receive: clientCutText.
	text := ByteArray new: msg length.
	socket receiveData: text.
"	self unimplemented"
]

{ #category : #configuring }
RFBSession >> rfbEncodingCoRRE [
	"Note the client's interest in receiving updates using compressed RRE encoding."

	self setPreferredEncoding: 'CoRRE'
]

{ #category : #configuring }
RFBSession >> rfbEncodingCompressLevel: level [
	"Register the client's interest in receiving update messages with the given level of zlib compression."

	self log: 'rfbEncodingCompressLevel ' , level printString.
	zlibCompressLevel := level.
	self log: 'using compression level ' , level printString
]

{ #category : #configuring }
RFBSession >> rfbEncodingCopyRect [
	"Record the client's interest in receiving updates using copy rect encoding.  Since we cannot obtain (from Morphic) the information needed to implement this, we ignore it."

	self log: 'rfbEncodingCopyRect'.
]

{ #category : #configuring }
RFBSession >> rfbEncodingHextile [
	"Record the client's interest in receiving updates in hextile encoding."

	self setPreferredEncoding: 'Hextile'
]

{ #category : #configuring }
RFBSession >> rfbEncodingLastRect [
	"Record the client's ability to deal with last rect encoding (which is a way to avoid having to count the number of rectangles to be sent in an update message in advance)."

	self log: 'rfbEncodingLastRect'.
	enableLastRectEncoding
		ifFalse:
			[self log: 'enabling LastRect protocol extension'.
			 enableLastRectEncoding := true]
]

{ #category : #configuring }
RFBSession >> rfbEncodingPointerPos [
	"Register the viewer's interest in receiving pointer position update messages."

	self log: 'rfbEncodingPointerPos'.
	enableCursorPosUpdates
		ifFalse:
			[self log: 'enabling cursor position updates'.
			 enableCursorPosUpdates := true]
]

{ #category : #configuring }
RFBSession >> rfbEncodingQualityLevel: level [
	"Record the viewer's interest in receiving tight encoding at the given quality setting."

	self log: 'rfbEncodingQualityLevel ' , level printString
]

{ #category : #configuring }
RFBSession >> rfbEncodingRRE [
	"Record the client's interest in receiving framebuffer update messages in RRE encoding."

	self setPreferredEncoding: 'RRE'
]

{ #category : #configuring }
RFBSession >> rfbEncodingRaw [
	"Record the client's ability to receive rectangles in raw encoding."

	self setPreferredEncoding: 'Raw'
]

{ #category : #configuring }
RFBSession >> rfbEncodingRichCursor [
	"Record the client's interest in receiving rich (full-colour) cursor shape updates."

	self log: 'rfbEncodingRichCursor'.
	enableCursorShapeUpdates
		ifFalse:
			[self log: 'enabling full-colour cursor updates'.
			 enableCursorShapeUpdates := true.
			 useRichCursorEncoding := true]
]

{ #category : #configuring }
RFBSession >> rfbEncodingTight [
	"Register the client's interest in receiving update messages using tight encoding."

	self log: 'rfbEncodingTight'
]

{ #category : #configuring }
RFBSession >> rfbEncodingUnknown: encoding [
	"Write a message to the log indicating that an unknown encoding number has been received during the protocol handshake."

	self log: 'ignoring unknown encoding: ' , encoding asString .
]

{ #category : #configuring }
RFBSession >> rfbEncodingXCursor [
	"Record the client's ability to receive X11-style cursor shape update messages."

	self log: 'rfbEncodingXCursor'.
	self log: 'enabling X-style cursor updates'.
	enableCursorShapeUpdates := true.
	useRichCursorEncoding := false
]

{ #category : #configuring }
RFBSession >> rfbEncodingZRLE [
	"Record the client's interest in receiving updates in Zlib Run-Length Encoding."

	server allowZRLE
		ifTrue:
			[self setPreferredEncoding: 'ZRLE'.
			 zlibStream := RFBZLibWriteStream on: ByteArray new]
		ifFalse:
			[self log: 'ignoring request for ZRLE encoding']
]

{ #category : #configuring }
RFBSession >> rfbEncodingZlib [
	"Record the client's interest in receiving update messages using zlib encoding."

	self log: 'rfbEncodingZlib'
]

{ #category : #configuring }
RFBSession >> rfbEncodingZlibHex [
	"Record the client's capability to receive ZLibHex encoded rectangles.  Note: This encoding is deprecated and is no longer described in the RFB protocol specification.  We ignore it."

	self log: 'ignoring deprecated protocol ZlibHex'.
	self unimplemented
]

{ #category : #'client messages' }
RFBSession >> rfbFixColourMapEntries [
	"Read and process a fix colourmap entries message."

	| msg nColours colours |
	self log: 'received rfbFixColourMapEntries'.
	msg := socket receive: fixColourMapEntries.
	nColours := msg nColours.
	colours := ByteArray new: 3 * 2 * nColours.
	socket receiveData: colours.
	self unimplemented
]

{ #category : #'client messages' }
RFBSession >> rfbFramebufferUpdateRequest [
	"Read and process an incoming framebuffer update request."

	| msg box |
	msg := socket receive: framebufferUpdateRequest.
	box := Rectangle origin: msg x @ msg y extent: msg w @ msg h.
"	self log: 'update region request ' , box printString."
	requestedRegion := requestedRegion merge: box.
"
	readyForSetColourMapEntries
		ifFalse:
			[readyForSetColourMapEntries := true.
			 format trueColour
				ifFalse:
					[self setClientColourMap: format from: 0 count: 0]].
"
	msg incremental
		ifFalse:
			[modifiedRegion add: box.
			 incremental := false].
	updateSemaphore signal.
]

{ #category : #'message dispatching' }
RFBSession >> rfbInitialisation [
	"Receive and process an incoming protocol initialisation message."

	| clientInitMessage serverInitMessage sharedFlag |
	clientInitMessage := socket receiveData: (RFBMessage new: 1).
	sharedFlag := (clientInitMessage byteAt: 1) ~~ 0.
	self log: 'client shared: ' , sharedFlag printString.
	interactive := interactive and: [server allowInteractiveConnections].
	interactive ifFalse: [self log: 'client is view only'].
	serverInitMessage := RFBServerInitialisation
		extent: Display extent
		format: RFBPixelFormat serverFormat
		name: self desktopName.
	socket sendData: serverInitMessage.
	self log: socket printString, ' connected'.
	RFBServer current enableDebugging ifTrue: [Transcript endEntry].
	server enforcePriorityFor: self shared: sharedFlag.
	state := #rfbNormal
]

{ #category : #'client messages' }
RFBSession >> rfbKeyEvent [
	"Read and process an incoming key event message."

	| msg evt key |
	msg := socket receive: keyEvent.
	interactive ifFalse: [^self].
	(key := self decodeKey: msg key) isNil ifTrue: [^self].
	key < 0 ifTrue: [^self processMetaKey: key negated down: msg down].
	evt := (Array new: 8) atAllPut: 0.
	evt
		at: 1 put: EventTypeKeyboard;
		at: 2 put: Time millisecondClockValue;
		at: 3 put: key;
		at: 4 put: (msg down ifTrue: [EventKeyDown] ifFalse: [EventKeyUp]);
		at: 5 put: modifiers;
		at: 6 put: key.
	Sensor handleEvent: evt.
	msg down
		ifTrue:
			[evt at: 4 put: EventKeyChar.
			 Sensor handleEvent: evt]
]

{ #category : #'message dispatching' }
RFBSession >> rfbNormal [
	"Receive and process the next normal protocol message."

	| type |
	type := (socket receiveData: (RFBMessage new: 1)) byteAt: 1.
	(type < 0) | (type >= MessageTypes size)
		ifTrue:
			[self log: 'illegal message type ' , type printString , ' received'.
			 self abort].
	self perform: (MessageTypes at: 1 + type).
]

{ #category : #'client messages' }
RFBSession >> rfbPointerEvent [
	"Receive and process an incoming pointer event message."

	| message event buttons |
	message := socket receive: pointerEvent.
	interactive ifFalse: [^self].
	event := (Array new: 8) atAllPut: 0.
	buttons := self decodeButtons: message buttonMask modified: modifiers.
	event
		at: 1 put: EventTypeMouse;
		at: 2 put: Time millisecondClockValue;
		at: 3 put: message x;
		at: 4 put: message y;
		at: 5 put: (buttons bitAnd: 7);
		at: 6 put: (buttons bitShift: -3).
	"Avoid sending a useless pointer update."
	enableCursorPosUpdates ifTrue: [clientPosition := message x @ message y].
	Sensor handleEvent: event
]

{ #category : #'message dispatching' }
RFBSession >> rfbProtocolVersion [
	"Read and process an incoming protocol version message.  Reject the viewer's connection attempt if it is too old for us to cope with."

	| buf protocolMajor |
	buf := socket receiveData: (String new: 12).
	self log: buf.
	protocolMajor := (buf copyFrom: 5 to: 7) asInteger.
	protocolMinor := (buf copyFrom: 9 to: 11) asInteger.
	self log: 'viewer using protocol ' , protocolMajor printString , '.' , protocolMinor printString.
	protocolMajor == ProtocolMajor
		ifFalse:
			[self log: 'major version mismatch'.
			 ^self sendConnectionFail:
				'RFB protocol version mismatch - server ' ,
				ProtocolMajor printString , '.' , ProtocolMinor printString ,
				' client ' , protocolMajor printString , '.' , protocolMinor printString].
	protocolMinor == ProtocolMinor
		ifFalse: [self log: 'ignoring minor version mismatch'].
	self authenticateClient
]

{ #category : #'message dispatching' }
RFBSession >> rfbSecurityType [
	"Read and process an incoming security type message.  This must correspond to the presence of a password on the server."

	| response type |
	response := socket receiveData: (RFBMessage new: 1).
	type := response byteAt: 1.
	(type == SecurityTypeNone and: [server hasPassword])
		ifTrue:
			[self log: 'authentication failed'.
			 socket sendData: RFBMessage newVncAuthFailed.
			 ^socket close].
	type == SecurityTypeNone
		ifTrue:
			[^state := #rfbInitialisation].
	type == SecurityTypeVNC
		ifTrue:
			[socket sendData: (authChallenge := self randomBytes).
			 ^state := #rfbAuthentication].
	self log: 'unknown security type response: ' , type printString.
	socket close
]

{ #category : #'client messages' }
RFBSession >> rfbSetEncodings [
	"Receive and process a set encodings message from the viewer."

	| msg enc number name nameArg |
	preferredEncoding := nil.
	msg := socket receiveNew: RFBSetEncodings.
	enc := socket receiveData: (RFBMessage new: 4 * msg nEncodings).
	0 to: msg nEncodings - 1 do: [:i |
		number := enc unsignedLongAt: i * 4 + 1.
		name := Encodings at: number ifAbsent: [nil].
		name isNil
			ifTrue:
				[nameArg := self specialEncodingAt: number.
				 self perform: nameArg first with: nameArg second]
			ifFalse:
				[self perform: name]].
	preferredEncoding isNil ifTrue: [self setPreferredEncoding: 'Raw'].
	(enableCursorPosUpdates and: [enableCursorShapeUpdates not])
		ifTrue:
			[self log: 'disabling cursor position updates'.
			 enableCursorPosUpdates := false]
]

{ #category : #'client messages' }
RFBSession >> rfbSetPixelFormat [
	"Read and process a set pixel format message from the viewer."

	| msg |
	self log: 'received rfbSetPixelFormat'.
	msg := socket receiveNew: RFBSetPixelFormat.
	format := msg pixelFormat.
	rfbStream := format rfbStream.
	self log: 'set pixel format: ' , format description.

	format colourMap isNil
		ifFalse:
			[self log: 'colour map ' , format colourMap masks printString , ' ' , format colourMap shifts printString.
			 format colourMap colors isNil
				ifFalse:
					[self log: 'colour table ' , format colourMap colors size printString]]
]

{ #category : #'server processes' }
RFBSession >> runLoop [
	"Run the incoming half of the session.  Send the client a protocol version message, then set the session state to expect an incoming protocol version reply from the viewer.  Then loop forever reading and dispatching messages from the viewer.  See RFBSession>>runSafely:, which exists only when an error (hopefully 'connection closed' ;-) is signalled."

	self log: 'running'.
	state := #rfbProtocolVersion.
	self log: 'send protocol version'.
	socket sendData: ProtocolVersion.
	socket runSafely:
		[socket waitForData.
		 self perform: state].
	self log: 'run loop exiting'.
	self release
]

{ #category : #'server messages' }
RFBSession >> sendBell [
	"Send a message that will ring the terminal bell on the viewer's machine."

	socket sendData: RFBBell new
]

{ #category : #'server messages' }
RFBSession >> sendConnectionFail: reason [
	"Send a connection failure message to the client, then terminate the session."

	socket sendData: (RFBMessage newConnFailed: reason).
	socket closeAndDestroy
]

{ #category : #sending }
RFBSession >> sendCursorForm: cursorForm extent: extent bytesPerPixel: bytesPerPixel [
	"Send a cursorForm (a CursorWithMask) to the remote viewer as part of a cursor shape update message."

	| w bits bytes byteRow wordRow |
	w := extent x.
	bits := cursorForm bits.
	bytes := ByteArray new: extent x * extent y.
	1 to: extent y do: [:y |
		byteRow := y - 1 * w.
		wordRow := y - 1 * 4.
		1 to: w do: [:x | bytes at: byteRow + x put: (bits byteAt: wordRow + x)]].
	socket sendData: bytes
]

{ #category : #'server messages' }
RFBSession >> sendCursorPosition: aPoint [
	"Send a cursor position update message."

	socket sendData: (updateRectHeader cursorPos: aPoint type: RfbEncodingPointerPos)
]

{ #category : #'server messages' }
RFBSession >> sendCursorShape: newCursor [
	"Send a cursor shape update message to the viewer."

	| cursorExtent |
	cursorExtent := newCursor extent + (7@0) // (8@1).
	self
		sendData: (updateRectHeader
						cursorHotSpot: newCursor offset negated
						extent: newCursor extent
						type: RfbEncodingXCursor);
		sendData: (RFBXCursorColoursHeader standardColours);
		sendCursorForm: newCursor extent: cursorExtent bytesPerPixel: 1;
		sendCursorForm: newCursor maskForm extent: cursorExtent bytesPerPixel: 1
]

{ #category : #sending }
RFBSession >> sendData: aByteArray [
	"Send the contents of aByteArray to the viewer."

	^socket sendData: aByteArray
]

{ #category : #sending }
RFBSession >> sendForm: form [
	"Even though #sendData: supports sending word data directly, we cannot use it because of a bug in the SocketPlugin logic.  (A partial write may not send an integral number of words, and there is no way to detect this inside the image: the plugin gives us back the number of bytes sent converted back into an integral number of words, which could be up to 3 bytes short of the amount of data actually sent.  Bummer, huh?)"

	| bytesPerLine bytesPerScan byte buf |
	bytesPerLine := form width * form bytesPerPixel.
	bytesPerScan := bytesPerLine + 3 bitAnd: -4.
	buf := ByteArray new: bytesPerScan * form height.
	format swapBytesIfNeeded: form.
	(RFBForm new hackBits: form bits) displayOn: (RFBForm new hackBits: buf).
	bytesPerLine == bytesPerScan
		ifTrue:
			[socket sendData: buf]
		ifFalse:
			[byte := 1.
			 1 to: form height do: [:y |
				socket sendData: buf startingAt: byte count: bytesPerLine.
				byte := byte + bytesPerScan]]
]

{ #category : #'server messages' }
RFBSession >> sendFramebufferUpdate [
	"Send a framebuffer update message to the viewer using the viewer's preferred encoding, unless raw encoding results in fewer bytes transmitted.  (All viewers are required to implement raw encoding.)"

	| updateRegion nRects sendCursor sendPosition |
	preferredEncoding ifNil: [^self].
	self beginUpdate.
	"Get the set of damaged rectangles as reported by Morphic."
	updateRegion := (modifiedRegion removeAll
						collect: [:rect | rect intersect: requestedRegion])
				 		select: [:rect | rect hasPositiveExtent].
	"Whittle them down to a much better approximation of reality."
	(damageFilter notNil and: [preferredEncoding ~~ #rfbEncodingRaw
								or: [server enableRawFilter]])
		ifTrue:
			[incremental
				ifTrue: [updateRegion := damageFilter getDamageInRegion: updateRegion]
				ifFalse: [damageFilter updateDamageInRegion: updateRegion]].
	incremental := true.
	"If we're conserving memory, break the updates into fun-size party snacks."
	server conserveMemory
		ifTrue: [updateRegion := self fragmentRegion: updateRegion].
	"Calculate how many update rectangles we need to send in total."
	nRects := updateRegion isEmpty
				ifTrue: [0]
				ifFalse: [self perform: countRects with: updateRegion].
	sendCursor := enableCursorShapeUpdates and: [currentCursor notNil].
	sendPosition := enableCursorPosUpdates and: [mousePosition notNil].
	nRects == UseLastRect
		ifFalse: [nRects := nRects
							+ (sendCursor ifTrue: [1] ifFalse: [0])
							+ (sendPosition ifTrue: [1] ifFalse: [0])].
	"Send the updates."
	nRects == 0
		ifFalse:
			[socket sendData: (framebufferUpdate nRects: nRects).
			 updateRegion do: [:rect |
				self perform: sendRect with: (format displayContents: rect)].
			 "sendCursor
				ifTrue:
					[clientCursor := currentCursor.
					 currentCursor := nil.
					 self sendCursorShape: clientCursor].
			 sendPosition
				ifTrue:
					[clientPosition := mousePosition.
					 mousePosition := nil.
					 self sendCursorPosition: clientPosition]."
			 nRects == UseLastRect
				ifTrue:
					[socket sendData: (updateRectHeader type: RfbEncodingLastRect)]].
	self endUpdate.
	server conserveMemory ifTrue: [rfbStream := format rfbStream]

]

{ #category : #'encoding-corre' }
RFBSession >> sendRectEncodingCoRRE: aForm [
	"Send a framebuffer update message covering the entire contents of aForm in compressed RRE encoding."

	^self sendRectEncodingCoRRE: aForm in: aForm boundingBox
]

{ #category : #'encoding-corre' }
RFBSession >> sendRectEncodingCoRRE: aForm in: bounds [
	"Send an update message covering the contents of aForm within the given bounds in compressed RRE encoding.  Note that this method descends recursively until bounds is no larger than 48x48."

	| x y w h |
	x := bounds left.
	y := bounds top.
	w := bounds width.
	h := bounds height.
	h > correMaxHeight
		ifTrue:
			[^self
				sendRectEncodingCoRRE: aForm in: (bounds origin extent: w@correMaxHeight);
				sendRectEncodingCoRRE: aForm in: (x@(y+correMaxHeight) extent: w@(h-correMaxHeight))].
	w > correMaxWidth
		ifTrue:
			[^self
				sendRectEncodingCoRRE: aForm in: (bounds origin extent: correMaxWidth@h);
				sendRectEncodingCoRRE: aForm in: ((x+correMaxWidth)@y extent: ((w-correMaxWidth)@h))].
	self sendSmallRectEncodingCoRRE: aForm in: bounds
]

{ #category : #'encoding-hextile' }
RFBSession >> sendRectEncodingHextile: aForm [
	"Send a framebuffer update message for the entire contents of aForm in hextile encoding."

	socket sendData: (updateRectHeader bounds: aForm bounds type: RfbEncodingHextile).
	aForm hextileEncodeOn: rfbStream resetContents forClient: socket
]

{ #category : #'encoding-rre' }
RFBSession >> sendRectEncodingRRE: aForm [
	"Send a single update rectangle in RRE encoding covering the entire contents of aForm."

	| nSubrects |
	nSubrects := aForm rreSubrectEncodeOn: rfbStream resetContents.
	nSubrects < 0 ifTrue: [^self sendRectEncodingRaw: aForm].
	socket
		sendData: (updateRectHeader bounds: aForm bounds type: RfbEncodingRRE);
		sendData: (rreHeader nSubrects: nSubrects);
		sendStream: rfbStream
]

{ #category : #'encoding-raw' }
RFBSession >> sendRectEncodingRaw: aForm [
	"Send an update rectangle for the entire contents of aForm in raw encoding."

	^self sendRectEncodingRaw: aForm in: (aForm boundingBox translateBy: aForm offset)
]

{ #category : #'encoding-raw' }
RFBSession >> sendRectEncodingRaw: aForm in: bounds [
	"Send a framebuffer update message for the contents of aForm within the given bounds using raw encoding."

	self
		sendData: (updateRectHeader bounds: bounds type: RfbEncodingRaw);
		sendForm: aForm
]

{ #category : #'encoding-zrle' }
RFBSession >> sendRectEncodingZRLE: aForm [
	"Send a framebuffer update message for the entire contents of aForm in ZRLE encoding."

	| encodedData rawData |
	aForm zrleEncodeOn: rfbStream resetContents.
	rawData := rfbStream contents.
	encodedData := zlibStream nextPutAll: rawData; synchronisedContents.
	socket
		sendData: (updateRectHeader bounds: aForm bounds type: RfbEncodingZRLE);
		sendData: (zrleHeader length: encodedData size);
		sendData: encodedData
]

{ #category : #'encoding-corre' }
RFBSession >> sendSmallRectEncodingCoRRE: aForm in: bounds [
	"Send an update message for the contents of aForm within the given bounds.  Note that this is where the recursion in RFBForm>>sendRectEncodingCoRRE: terminates."

	| nSubrects |
	nSubrects := aForm correSubrectEncodeIn: bounds on: rfbStream resetContents.
	nSubrects < 0
		ifTrue:
			[self
				sendRectEncodingRaw: (aForm subForm: bounds)
				in: (bounds translateBy: aForm offset)]
		ifFalse:
			[socket
				sendData: (updateRectHeader
							bounds: (bounds translateBy: aForm offset)
							type: RfbEncodingCoRRE);
				sendData: (rreHeader nSubrects: nSubrects);
				sendStream: rfbStream]
]

{ #category : #sending }
RFBSession >> sendStream: aStream [
	"Send the entire contents of aStream to the viewer."

	^socket sendStream: aStream
]

{ #category : #configuring }
RFBSession >> setPreferredEncoding: encodingName [
	"The client has just registered an interest in receiving updates in the encoding with the given name.  If this is the first encoding in the list of acceptable encodings, record it as the preferred encoding for the client."

	preferredEncoding isNil
		ifTrue:
			[preferredEncoding := Symbol intern: 'rfbEncoding' , encodingName.
			 sendRect := Symbol intern: 'sendRectEncoding' , encodingName , ':'.
			 countRects := Symbol intern: 'countRectsEncoding' , encodingName , ':'.
			 self log: 'using ' , encodingName , ' encoding']
]

{ #category : #configuring }
RFBSession >> specialEncodingAt: encodingNumber [
	"Answer the special encoding represented by the given 32-bit encodingNumber."

	| type name arg |
	type := encodingNumber bitAnd: 16rFFFFFF00.
	type = 16rFFFFFF00 ifFalse: [^Array with: #rfbEncodingUnknown: with: encodingNumber].
	type := (encodingNumber bitAnd: 16rF0) bitShift: -4.
	name := SpecialEncodings at: type ifAbsent: [^Array with: #rfbEncodingUnknown: with: encodingNumber].
	arg := encodingNumber bitAnd: 16r0F.
	^Array with: name with: arg
]

{ #category : #controlling }
RFBSession >> start [
	"Start the server input process."

	process := [self runLoop] forkAt: server sessionPriority.
	self log: 'started ' , process printString.
]

{ #category : #controlling }
RFBSession >> stop [
	"Close down the receiver's session."

	socket closeAndDestroy.
	Processor yield.
	self log: 'stopped'.
	self release
]

{ #category : #private }
RFBSession >> unimplemented [
	"Make some noise when encountering an unimplemented feature.  Strictly developer lossage."

	self log: 'unimplemented'.
	Beeper beepPrimitive.
	Transcript endEntry
]

{ #category : #'server processes' }
RFBSession >> updateLoop [
	"Run the outgoing half of the connection.  Wait for a screen update to occur, send a corresponding framebuffer update message, rinse and repeat until clean.  Note the processor yield which is there to give the input loop chance to run (think: interrupt keycode) in the case of abusive screen updates."

	socket runSafely:
		[updateSemaphore wait.
		 self updatePending
			ifTrue:
				[self sendFramebufferUpdate.
				 Processor yield]].
	self log: 'update loop exiting'.
]

{ #category : #testing }
RFBSession >> updatePending [
	"Answer whether an update message is required.  Update messages can contain damage repair, cursor shape changes, or pointer position updates -- so allow for each of these situations while formulating the answer."

	^ (mousePosition notNil and: [ mousePosition ~= clientPosition ])
		or:	[ (currentCursor notNil and: [ currentCursor ~~ clientCursor ])
		or:	[ modifiedRegion isEmpty not ] ]
]
