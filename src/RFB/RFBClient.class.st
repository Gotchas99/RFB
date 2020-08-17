"
I am a RFB/VNC viewer.  If you send me #open then I will open a window with a menu (on the scrollbar button) for connecting to a remote RFB/VNC server.
"
Class {
	#name : #RFBClient,
	#superclass : #ImageMorph,
	#instVars : [
		'scrollPane',
		'window',
		'socket',
		'sendLock',
		'state',
		'process',
		'protocolMinor',
		'serverExtent',
		'serverFormat',
		'serverName',
		'updateRequestPending',
		'currentCursor',
		'savedCursor',
		'hasCursor',
		'modifierState',
		'zlibStream'
	],
	#classVars : [
		'CommandKeySym',
		'CtrlKeySym',
		'DefaultEncoding',
		'Enable8Bit',
		'EnableExpandOnBell',
		'EnableExpandOnConnection',
		'EnableShared',
		'EnableViewOnly',
		'EnableXCursor',
		'Encodings',
		'FastUpdate',
		'KeySyms',
		'MessageTypes',
		'ModifierMap',
		'OptionKeySym',
		'ProtocolMajor',
		'ProtocolMinor',
		'RfbEncodingAuto',
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
		'ShiftKeySym',
		'WindowLabel'
	],
	#pools : [
		'EventSensorConstants'
	],
	#category : #'RFB-Viewer'
}

{ #category : #'class initialisation' }
RFBClient class >> initialiseConstants [
	"RFBClient initialiseConstants"

	WindowLabel := 'PharoVNC'.

	ProtocolMajor := 3.
	ProtocolMinor := 7.

	MessageTypes := #(
		"0"	rfbFramebufferUpdate
		"1"	rfbSetColourMapEntries
		"2"	rfbBell
		"3"	rfbServerCutText).

	RfbEncodingAuto := -1.

	(Encodings := Dictionary new)				"allow for gaps and LargeInts"
		"version 3.3"
		at: (RfbEncodingRaw		:= 0) put: #rfbEncodingRaw:;
		at: (RfbEncodingCopyRect	:= 1) put: #rfbEncodingCopyRect:;
		at: (RfbEncodingRRE			:= 2) put: #rfbEncodingRRE:;
		at: (RfbEncodingCoRRE		:= 4) put: #rfbEncodingCoRRE:;
		at: (RfbEncodingHextile		:= 5) put: #rfbEncodingHextile:;
		"tight vnc"
		at: (RfbEncodingZlib			:= 6) put: #rfbEncodingZlib:;
		at: (RfbEncodingTight		:= 7) put: #rfbEncodingTight:;
		at: (RfbEncodingZlibHex		:= 8) put: #rfbEncodingZlibHex:;
		"version 3.7"
		at: (RfbEncodingZRLE		:= 16) put: #rfbEncodingZRLE:;
		"special encodings"
		at: (RfbEncodingXCursor		:= 16rFFFFFF10) put: #rfbEncodingXCursor:;
		at: (RfbEncodingRichCursor	:= 16rFFFFFF11) put: #rfbEncodingRichCursor:;
		at: (RfbEncodingPointerPos	:= 16rFFFFFF18) put: #rfbEncodingPointerPos:;
		at: (RfbEncodingLastRect	:= 16rFFFFFF20) put: #rfbEncodingLastRect:
]

{ #category : #'class initialisation' }
RFBClient class >> initialiseKeySyms [
	"Initialise the tables used to map MacRoman key event codes to X11 keysyms, and local modifier key bits to server modifier bits."
	"RFBClient initialiseKeySyms"

	"The viewer sends 16-bit X11R6 keysyms.  There are hundreds of these.  The following are just the most common."
	KeySyms := Array new: 256.
	#(	(16rFF08 8)		"bs"
		(16rFF09 9)		"tab"
		(16rFF0A 10)		"lf"
		(16rFF0D 13)		"cr"
		(16rFF1B 27)		"esc"
		(16rFF51 28)		"left"
		(16rFF52 30)		"up"
		(16rFF53 29)		"right"
		(16rFF54 31)		"down"
		(16rFF55 11)		"prior"
		(16rFF56 12)		"next"
		(16rFF57 4)		"end"
		(16rFFFF 127)	"del"
	) do: [:symKey | KeySyms at: symKey second put: symKey first].
	"The following works well for Apple keyboards.  Anyone who doesn't have an Apple keyboard may well suffer from a classic case of garbage-in, garbage-out"
	ShiftKeySym		:= 16rFFE1.	"shift:=l"
	CtrlKeySym			:= 16rFFE3.	"control:=l"
	CommandKeySym	:= 16rFFE7.	"meta:=l"
	OptionKeySym		:= 16rFFE9.	"alt:=l"

	(ModifierMap := Array new: 5)
		at: 1 put: ShiftKeySym;
		at: 2 put: CtrlKeySym;
		at: 3 put: OptionKeySym;
		at: 4 put: CommandKeySym;
		at: 5 put: CommandKeySym
]

{ #category : #'class initialisation' }
RFBClient class >> initialisePreferences [
	"RFBClient initialisePreferences"

	DefaultEncoding := RfbEncodingAuto.		"Automatically select encoding."
	Enable8Bit := false.						"Default is local screen depth."
	EnableShared := true.					"Default is to share connections."
	EnableExpandOnBell := false.
	EnableExpandOnConnection := false.		"For listen mode only."
	EnableViewOnly := false.
	EnableXCursor := true.
	FastUpdate := false
]

{ #category : #'class initialisation' }
RFBClient class >> initialize [
	"RFBClient initialize"

	self
		initialiseConstants;
		initialisePreferences;
		initialiseKeySyms
]

{ #category : #'instance creation' }
RFBClient class >> new [

	^super new initialise
]

{ #category : #opening }
RFBClient class >> open [
	"Open a RFBClient window."

	^self new open
]

{ #category : #private }
RFBClient class >> worldMenuOn: aBuilder [ 
	<worldMenu>
	
	(aBuilder item: #vncViewer)
		parent: #Tools;
		label: 'VNC Viewer';
		action: [ self open ];
		help: 'Open a VNC viewer to access a remote VNC server.'
]

{ #category : #private }
RFBClient >> abort [
	"Abort the connection."

	self isConnected
		ifTrue:
			[socket closeAndDestroy.
			 socket := nil.
			 zlibStream := nil.
			 process ~~ Processor activeProcess ifTrue: [process terminate].
			 serverExtent := 0@0.
			 self setExtent.
			 currentCursor := nil.
			 hasCursor := false.
			 savedCursor isNil ifFalse: [savedCursor beCursor].
			 savedCursor := nil.
			 window setLabel: WindowLabel]
]

{ #category : #private }
RFBClient >> aboutString [
	"Answer the contents of the about window."

	^'
		*** RFBClient: a RFB/VNC viewer written entirely in Smalltalk. ***

  (If you don''t know what RFB and VNC are, go look at "http://www.realvnc.com"
  and/or "http://www.tightvnc.com".)

	Copyright (C) 2004 by Ian Piumarta
	All Rights Reserved.

	Released under the terms of: The Squeak License (what else did you expect? ;-)

	Send bug reports, suggestions, unsolicited gifts, etc., to: ian.piumarta@inria.fr

	Send complaints and other negative vibes to: nobody@localhost

  Enjoy!'
]

{ #category : #events }
RFBClient >> blueButtonDown: anEvent [
	"Override to avoid halo."

	self mouseDown: anEvent.
	^true
]

{ #category : #events }
RFBClient >> blueButtonUp: anEvent [
	"Override to avoid halo."

	self mouseUp: anEvent.
	^true
]

{ #category : #'client process' }
RFBClient >> clientPriority [
	"Answer the scheduling priority at which the client should run."
	"Note: since the client performs Morphic screen updates, it is highly likely that it will break Morphic if it runs at anything higher than userSchedulingPriority."

	^Processor userSchedulingPriority
]

{ #category : #'client process' }
RFBClient >> clientRunLoop [
	"Run the loop in which the client sends and receives messages."

	state := #rfbProtocolVersion.
	socket runSafely:
		[socket waitForData.
		 self perform: state]
]

{ #category : #connecting }
RFBClient >> connect [
	"Open a new connection."

	self isConnected ifTrue: [^self inform: 'This viewer is already connected.'].
	(socket := RFBClientSocket connectedToServer) isNil ifTrue: [^self].
	process := [self clientRunLoop] forkAt: self clientPriority
]

{ #category : #private }
RFBClient >> connectionFailed [
	"The server failed the connection attempt in an orderly fashion.  Read the failure reason then inform the user that the connection attemp failed and bail."

	| message count |
	message := socket receiveData: (RFBMessage new: 4).
	count := message opcode.
	message := socket receiveData: (String new: count).
	self connectionFailed: message
]

{ #category : #private }
RFBClient >> connectionFailed: reason [
	"Inform the user that the connection attemp failed, then bail."

	| message |
	message := 'Connection failed: ', reason.
	self log: message; inform: message.
	self abort
]

{ #category : #testing }
RFBClient >> connectionIsLocal [
	"Answer whether the receiver is connected to a server on the same machine."

	| peer |
	peer := socket remoteAddress.
	^peer = #(127 0 0 1) asByteArray or: [peer = NetNameResolver localHostAddress]
]

{ #category : #accessing }
RFBClient >> contentBounds [

	^scrollPane contentBounds
]

{ #category : #connecting }
RFBClient >> disconnect [
	"Close the new connection."

	self isConnected ifFalse: [^self inform: 'This viewer is not connected.'].
	(self confirm: 'Really disconnect?') ifTrue: [self abort]
]

{ #category : #private }
RFBClient >> display: sourceForm on: destForm in: destBounds [
	"Display the sourceForm on the destForm within destBounds and invalidate the Display accordingly.  If fast updates are disabled then yield the Processor to give other interactive processes a chance to run."

	serverFormat display: sourceForm on: destForm at: destBounds origin.
	self invalidRect: destBounds.
	FastUpdate ifFalse: [Processor yield]
]

{ #category : #private }
RFBClient >> encodeButtons: buttonMask [
	"Answer a RFB button mask equivalent to the Squeak buttonMask."

	| buttons |
	buttons := 0.
	#((1 2) (2 0) (4 -2)) do:
		[:maskShift |
		 buttons := buttons bitOr: ((buttonMask bitAnd: maskShift first) bitShift: maskShift second)].
	^buttons
]

{ #category : #private }
RFBClient >> encodeKey: keyCode [
	"Answer a key sym corresponding to the given Squeak keyCode.  Note: if the Control key is down we don't encode.  This ensures that C-l (ascii 12) remains C-l (keysym 12) rather than 'page down' (MacRoman 12) which would be 'Next' (keysym #ff56)."

	| keySym |
	(modifierState anyMask: CtrlKeyBit) ifFalse: [keySym := KeySyms at: keyCode].
	keySym isNil ifTrue: [keySym := keyCode].
	^keySym
]

{ #category : #menu }
RFBClient >> encodingsMenu [
	"Answer the encodings submenu."

	^RFBMenuMorph new
		add: 'auto' get: [DefaultEncoding == RfbEncodingAuto]
			set: [self setDefaultEncoding: RfbEncodingAuto]
			help: 'Automatically select the most appropriate encoding.';
		addLine;
		add: 'Hextile' get: [DefaultEncoding == RfbEncodingHextile]
			set: [self setDefaultEncoding: RfbEncodingHextile]
			help: 'Use Hextile encoding.';
		add: 'CoRRE' get: [DefaultEncoding == RfbEncodingCoRRE]
			set: [self setDefaultEncoding: RfbEncodingCoRRE]
			help: 'Use Compressed Rise and Run-length Encoding.';
		add: 'RRE' get: [DefaultEncoding == RfbEncodingRRE]
			set: [DefaultEncoding := RfbEncodingRRE]
			help: 'Use Rise and Run-length Encoding.';
		add: 'Raw' get: [DefaultEncoding == RfbEncodingRaw]
			set: [self setDefaultEncoding: RfbEncodingRaw]
			help: 'Use Raw encoding.';
		add: 'ZRLE' get: [DefaultEncoding == RfbEncodingZRLE]
			set: [self setDefaultEncoding: RfbEncodingZRLE]
			help: 'Use Zlib Run-Length Encoding.';
		yourself
]

{ #category : #private }
RFBClient >> encryptChallenge: challenge with: password [
	"Encrypt the 16-byte challenge with the given password.  Answer the encrypted challenge."

	| block |
	block := ByteArray new: 8.
	1 to: (password size min: 8) do: [:i | block at: i put: (password at: i) asciiValue].
	password atAllPut: (Character value: 0).
	RFB3DES new
		encryptionKey: block;
		des: challenge to: challenge.
	block atAllPut: 0.
	^challenge
]

{ #category : #accessing }
RFBClient >> fastUpdate [
	"Answer whether updates should be fast (uses more memory and impacts interactive response in other processes) or not (uses less memory and yields the Processor often)."

	^FastUpdate
]

{ #category : #menu }
RFBClient >> getMenu: shiftState [
	"Answer the menu attached to the yellow button (and to the scrollbar button if visible)."

	| menu |
	(menu := RFBMenuMorph new)		"We're NOT a text holder.  Grrr...!"
		defaultTarget: self.
	self isConnected
		ifTrue: [menu add: 'disconnect...' action: #disconnect help: 'Disconnect from the server.']
		ifFalse: [menu add: 'connect...' action: #connect help: 'Connect to a server.'].
	menu
		addLine;
		add: 'options' subMenu: self optionsMenu;
		add: 'encodings' subMenu: self encodingsMenu;
		add: 'performance' subMenu: self performanceMenu;
		addLine;
		add: 'help...' action: #showHelpWindow help: 'Open a window describing this menu in detail.';
		add: 'about...' action: #showAboutWindow help: 'Open the Cheezoid About Window.'.
	^menu
]

{ #category : #private }
RFBClient >> helpString [
	"Answer the contents of the help window."

	^
'Everything you need is on the window menu (the button at the top of the scrollbar).

*** Menu contents

** connect... / disconnect...

Depending on whether the viewer is already connected, this item lets you connect or disconnect.  When connecting, you will be asked for the IP address or name of the machine to which you want to connect.  If the machine requires a password, you will be asked for it too.  When disconnecting, you will be given a chance to change your mind.  (Disconnecting accidentally is no big deal anyway: you just connect again. ;-)

** options

Everything to do with viewer options.

* shared

If this is set then the viewer will request a shared connection.  If this is not set then the viewer will request exclusive access to the remote framebuffer.  Whether or not it gets that access depends on the server''s policy.

* local cursor

If this is enabled then the viewer will request that the server send cursor shape updates so that the viewer can track it locally.

* view-only

If this is enabled then the viewer will not send mouse or keyboard events to the server.

* 8-bit pixels

If this is enabled then the viewer will ask the server to send data using 8-bit deep pixels to reduce network traffic.

** encodings

Everything about selecting the encoding you''d like to use.

* auto

If enabled then the viewer will pick the most appropriate encoding for you.  Currently this means ''Raw'' encoding if the server is on the same machine, ''Hextile'' encoding otherwise.

* ZRLE
* Hextile
* CoRRE
* RRE
* RAW

If any of these are set then the viewer will ask the server to perform updates using that encoding.  Note that ZRLE currently has problems with some Windows VNC server implementations.  (Running it between two Pharo images works fine.)

Note that if you change the encoding while the viewer is connected, the new encoding preference will take effect immediately.  (Any other open viewers will not be affected.)

** performance

* fast update

If this is set then the viewer will consume more memory and will hog the CPU during updates to ensure the lowest possible update latencies.  In particular, while an update is in progress, no other userSchedulingPriority processes will be allowed to run.  If this option is not set then the viewer will attempt to minimise the amount of memory consumed during updates, and will yield the processor often (usually after each ''subrectangle'' in the update message).  This makes for slower update processing, and increased CPU usage while Morphic tries to catch up with screen updates at each yield, but does give other user-priority processes a chance to run.

** help...

You already know about.

** about...

Opens the Cheezoid About Window containing absolutely nothing of interest (other than an email address to which you can send bug reports or suggestions for improvements).

*** Bugs and caveat empori

* ZRLE is broken when talking to Windows servers.  I have no idea why.  The ZLibInflateStream in the image becomes hopelessly confused with the second update message that is received.  ZRLE works just fine between a Squeak server and a Unix client (or between Squeak server and Squeak viewer.

* Some of the menu options are currently unimplemented.  (The viewer was written for fun to occupy a rainy weekend and isn''t really meant to be a production-quality artefact.)  In particular, 8-bit pixels and view-only options are ignored when setting up the connection.

* The viewer currently always uses the server''s pixel format.  There should be an option to use the local pixel format instead.

* Some improvements to the way focus and mouse ''first clicks'' are handled are certainly warranted.

* The scroll bars sould vanish when the window is expanded to cover its entire contents.  The vertical scroll bar is stuck on the left too;  don''t blame me -- blame whoever wrote TwoWayScrollPane.'
]

{ #category : #private }
RFBClient >> inATwoWayScrollPane [
	"Answer a two-way scroll pane that allows the user to scroll the receiver in either direction."

	| widget |
	(widget := ScrollPane new)
		extent: ((self width min: 300 max: 100) @ (self height min: 150 max: 100));
		borderWidth: 0.
	widget scroller addMorph: self.
	widget setScrollDeltas.
	widget color: self color darker.
	^widget
]

{ #category : #'initialise-release' }
RFBClient >> initialise [
	"Initial conditions."

	image := RFBClientForm extent: 0@0 depth: Display depth.
	serverExtent := 0@0.
	sendLock := Semaphore forMutualExclusion.
	updateRequestPending := true.
	currentCursor := nil.
	savedCursor := nil.
	hasCursor := false.
	modifierState := 0
]

{ #category : #testing }
RFBClient >> isActive [
	"Answer whether the receiver is currently connected and ready to send normal protocol messages."

	^socket notNil and: [state == #rfbNormal]
]

{ #category : #testing }
RFBClient >> isConnected [
	"Answer whether the receiver is currently connected."

	^socket notNil
]

{ #category : #events }
RFBClient >> keyDown: anEvent [
	"Note: this event should be followed by a corresponding keyStroke, so we ignore the key value."

	self processModifiers: anEvent buttons
]

{ #category : #events }
RFBClient >> keyStroke: anEvent [
	"Send a key press to the server."

	self
		processModifiers: anEvent buttons;
		sendKeyEvent: (self encodeKey: anEvent keyValue) down: true;
		sendPeriodicUpdateRequest
]

{ #category : #events }
RFBClient >> keyUp: anEvent [
	"Send a key release to the server."

	self
		processModifiers: anEvent buttons;
		sendKeyEvent: (self encodeKey: anEvent keyValue) down: false
]

{ #category : #private }
RFBClient >> log: aMessage [
	"Write aMessage to the client log."

	Transcript cr; show: aMessage
]

{ #category : #events }
RFBClient >> mouseDown: anEvent [
	"Send a mouse down event to the server."
	"Note: Morphic doesn't really give us any chance to turn off button mapping.  So Ctrl+button1 yields button2, rather than button1 with the control modifier on.  While this is hunk-dory for Squeak, it's kind of a bummer when you need the vt menu in an xterm..."

	self
		processModifiers: anEvent buttons;
		sendPointerEvent: anEvent buttons position: anEvent position
]

{ #category : #events }
RFBClient >> mouseEnter: anEvent [
	"The mouse just entered the window.  Remember that we now have control of the cursor.  If the server had previously installed a cursor in the receiver, set the Squeak cursor accordingly."

	hasCursor
		ifFalse:
			[savedCursor := Cursor currentCursor.
			 hasCursor := true.
			 currentCursor isNil ifFalse: [currentCursor beCursor]]
]

{ #category : #events }
RFBClient >> mouseLeave: anEvent [
	"The mouse has just left the window.  Note the fact that we no longer have control of the cursor.  If a cursor was saved on entry to the window, restore it now."

	hasCursor
		ifTrue:
			[hasCursor := false.
			 savedCursor isNil ifFalse: [savedCursor beCursor]]
]

{ #category : #events }
RFBClient >> mouseMove: evt [
	"Send a motion event to the server."

	| inside |
	"Compensate for Morphic failing to send #mouseEnter:/Leave: correctly."
	inside := scrollPane contentBounds containsPoint: evt position.
	(inside and: [ hasCursor not ]) ifTrue: [self mouseEnter: evt].
	(inside not and: [ hasCursor ]) ifTrue: [self mouseLeave: evt].
	self
		processModifiers: evt buttons;
		sendPointerEvent: evt buttons position: evt position
]

{ #category : #private }
RFBClient >> mousePoint: aPoint [
	"Answer a sanitised mouse point: truncated and constrained to lie within the viewer's inner bounds."

	^((aPoint max: 0@0) min: image extent) truncated
]

{ #category : #events }
RFBClient >> mouseUp: anEvent [
	"Send a button release event to the server."

	self mouseMove: anEvent
]

{ #category : #opening }
RFBClient >> open [
	"Open a RFBClient window."

	(scrollPane := RFBScrollPane new)
		extent: ((self width min: 300 max: 100) @ (self height min: 150 max: 100));
		borderWidth: 0.
	scrollPane scroller addMorph: self.
	scrollPane
		setScrollDeltas;
		color: self color darker;
		model: self.
	window := (RFBSystemWindow labelled: WindowLabel) model: self.
	window addMorph: scrollPane frame: (0@0 corner: 1@1).
	window openInWorld
]

{ #category : #menu }
RFBClient >> optionsMenu [
	"Answer the options submenu."

	^RFBMenuMorph new
		add: 'shared' get: [EnableShared] set: [EnableShared := EnableShared not]
			help: 'Share the connection with other clients.';
		add: 'local cursor' get: [EnableXCursor] set: [EnableXCursor := EnableXCursor not]
			help: 'Local cursor shape tracks server cursor shape.';
		add: 'view-only' get: [EnableViewOnly] set: [EnableViewOnly := EnableViewOnly not]
			help: 'Do not send mouse and keyboard events to the server.';
		add: '8-bit pixels' get: [Enable8Bit] set: [Enable8Bit := Enable8Bit not]
			help: 'Use 8-bit depth to reduce bandwidth requirements.';
		yourself
]

{ #category : #menu }
RFBClient >> performanceMenu [
	"Answer the performance submenu."

	^RFBMenuMorph new
		add: 'fast update' get: [FastUpdate] set: [FastUpdate := FastUpdate not]
			help: 'Trade resources for update speed.  When enabled, updates will use more memory and the Processor will be devoted to processing the update (reducing interactive response in other windows).  When disabled, updates will use very little memory and the Processor will yield often (preserving response in other windows).';
		yourself
]

{ #category : #accessing }
RFBClient >> preferredEncoding [
	"Answer the preferred encoding, according to the current preferences."

	DefaultEncoding == RfbEncodingAuto ifFalse: [^DefaultEncoding].
	self connectionIsLocal
		ifTrue: [^RfbEncodingRaw]
		ifFalse: [^RfbEncodingHextile]
]

{ #category : #private }
RFBClient >> processModifiers: buttonMask [
	"Check for modifier key press/release and fake the corresponding events."

	| prevState pressed released |
	prevState := modifierState.
	modifierState := buttonMask bitShift: -3.
	pressed := (prevState bitXor: -1) bitAnd: modifierState.
	released := (modifierState bitXor: -1) bitAnd: prevState.
	self sendModifiers: released down: false.
	self sendModifiers: pressed down: true
]

{ #category : #updating }
RFBClient >> processUpdate: updateHeader [
	"Process a framebuffer update rectangle."

	| type |
	self
		perform: (Encodings at: (type := updateHeader type) ifAbsent: [#rfbEncodingUnknown:])
		with: updateHeader
]

{ #category : #receiving }
RFBClient >> receiveCursorForm: aForm extent: extent [
	"Receive aForm from the connection."

	| w h bits bytes byteRow wordRow |
	w := extent x.
	h := extent y.
	bits := aForm bits.
	bytes := ByteArray new: w * h.
	socket receiveData: bytes.
	1 to: h do: [:y |
		byteRow := y - 1 * w.
		wordRow := y - 1 * 4.
		1 to: w do: [:x | bits byteAt: wordRow + x put: (bytes at: byteRow + x)]].
	^aForm
]

{ #category : #receiving }
RFBClient >> receiveForm: aForm [
	"Read the contents of aForm from the connection."

	| bytesPerLine bytesPerScan byte buf |
	bytesPerLine := aForm width * aForm bytesPerPixel.
	bytesPerScan := bytesPerLine + 3 bitAnd: -4.
	buf := ByteArray new: bytesPerScan * aForm height.
	bytesPerLine == bytesPerScan
		ifTrue:
			[socket receiveData: buf]
		ifFalse:
			[byte := 1.
			 1 to: aForm height do: [:y |
				socket receiveData: buf startingAt: byte count: bytesPerLine.
				byte := byte + bytesPerScan]].
	(RFBForm new hackBits: buf) displayOn: (RFBForm new hackBits: aForm bits).
	serverFormat swapBytesIfNeeded: aForm.
]

{ #category : #'message dispatching' }
RFBClient >> rfbAuthentication [
	"Read and process an incoming authentication challenge.  Prompt the user for a password and send back the encrypted response."

	| message password |
	message := socket receiveData: (RFBMessage new: 16).
	password := UIManager default requestPassword: 'password?'. 
	message := self encryptChallenge: message with: password.
	socket sendData: message.
	"Read the authentication response immediately."
	message := socket receiveData: (RFBMessage new: 4).
	message opcode == RFBMessage rfbVncAuthOK ifTrue: [^self sendClientInitialisation].
	self connectionFailed: 'permission denied'
]

{ #category : #'message dispatching' }
RFBClient >> rfbAuthenticationType [
	"We're in version 3.3 handshake.  Read a 4-byte authentication type message from the server."

	| message type |
	message := socket receiveData: (RFBMessage new: 4).
	type := message opcode.
	type == RFBMessage rfbNoAuth ifTrue: [^self sendClientInitialisation].
	type == RFBMessage rfbVncAuth ifTrue: [^state := #rfbAuthentication].
	self connectionFailed: 'unknown authentication type: ', type printString
]

{ #category : #'server messages' }
RFBClient >> rfbBell [
	"Read and process a bell message".

	Beeper beepPrimitive
]

{ #category : #updating }
RFBClient >> rfbEncodingCoRRE: updateHeader [
	"Process a compressed rise and run-length encoding update."

	| form updateBounds |
	updateBounds := updateHeader bounds.
	form := RFBClientForm extent: updateBounds extent depth: serverFormat bitsPerPixel.
	form correDecode: (0@0 extent: updateBounds extent) from: socket for: nil.
	self display: form on: image in: updateBounds.
	FastUpdate ifFalse: [Processor yield]
]

{ #category : #updating }
RFBClient >> rfbEncodingCopyRect: updateHeader [
	"Process a copy rect encoding update."

	self log: 'rfbEncodingCopyRect: ', updateHeader printString.
	self connectionFailed: 'unimplemented'
]

{ #category : #updating }
RFBClient >> rfbEncodingHextile: updateHeader [
	"Process a hextile encoding update."

	| form updateBounds |
	updateBounds := updateHeader bounds.
	FastUpdate
		ifTrue:
			[form := RFBClientForm extent: updateBounds extent depth: serverFormat bitsPerPixel.
			 form hextileDecode: (0@0 extent: updateBounds extent) from: socket for: nil.
			 self display: form on: image in: updateBounds]
		ifFalse:
			[image hextileDecode: updateBounds from: socket for: self]
]

{ #category : #updating }
RFBClient >> rfbEncodingLastRect: updateHeader [
	"Process a last rectangle update."

	self log: 'rfbEncodingLastRect: ', updateHeader printString.
	self connectionFailed: 'unimplemented'
]

{ #category : #updating }
RFBClient >> rfbEncodingPointerPos: updateHeader [
	"Process a pointer position update."

	self log: 'rfbEncodingPointerPos: ', updateHeader printString.
	self connectionFailed: 'unimplemented'
]

{ #category : #updating }
RFBClient >> rfbEncodingRRE: updateHeader [
	"Process a rise and run-length encoding update."

	| form updateBounds |
	updateBounds := updateHeader bounds.
	form := RFBClientForm extent: updateBounds extent depth: serverFormat bitsPerPixel.
	form rreDecode: (0@0 extent: updateBounds extent) from: socket for: nil.
	self display: form on: image in: updateBounds.
	FastUpdate ifFalse: [Processor yield]
]

{ #category : #updating }
RFBClient >> rfbEncodingRaw: updateHeader [
	"Process a raw encoding update."

	| form updateBounds |
	updateBounds := updateHeader bounds.
	form := RFBForm extent: updateBounds extent depth: serverFormat bitsPerPixel.
	self receiveForm: form.
	self display: form on: image in: updateBounds
]

{ #category : #updating }
RFBClient >> rfbEncodingRichCursor: updateHeader [
	"Process a rich cursor update."

	self log: 'rfbEncodingRichCursor: ', updateHeader printString.
	self connectionFailed: 'unimplemented'
]

{ #category : #updating }
RFBClient >> rfbEncodingTight: updateHeader [
	"Process a tight encoding update."

	self log: 'rfbEncodingTight: ', updateHeader printString.
	self connectionFailed: 'unimplemented'
]

{ #category : #updating }
RFBClient >> rfbEncodingUnknown: updateHeader [
	"Process an unknown encoding update."

	self log: 'rfbEncodingUnknown: ', updateHeader printString.
	self connectionFailed: 'protocol error'
]

{ #category : #updating }
RFBClient >> rfbEncodingXCursor: updateHeader [
	"Process a X11-style cursor update."

	| hotSpot extent cursor mask cursorExtent realCursor realMask |
	hotSpot := updateHeader cursorHotSpot.
	extent := updateHeader cursorExtent.
	cursorExtent := extent + (7@0) // (8@1).
	socket receiveData: (RFBXCursorColoursHeader new).	"IGNORED."
	cursor := Form extent: extent depth: 1.
	mask := Form extent: extent depth: 1.
	self receiveCursorForm: cursor extent: cursorExtent.
	self receiveCursorForm: mask extent: cursorExtent.
	realCursor := CursorWithMask extent: 16@16 depth: 1.
	realMask := Form extent: 16@16 depth: 1.
	cursor displayOn: realCursor.
	mask displayOn: realMask.
	realCursor setMaskForm: realMask.
	realCursor offset: hotSpot negated.
	currentCursor := realCursor.
	hasCursor ifTrue: [realCursor beCursor]
]

{ #category : #updating }
RFBClient >> rfbEncodingZRLE: updateHeader [
	"Process a zlib run-length encoding update."

	| length updateBounds bytes form |
	updateBounds := updateHeader bounds.
	length := (socket receiveData: RFBZRLEHeader new) length.
	bytes := socket receiveData: (ByteArray new: length).
	zlibStream isNil
		ifTrue: [(zlibStream := RFBZLibReadStream on: bytes)
					getPixel: socket getPixel getCPixel: socket getCPixel]
		ifFalse: [zlibStream continueOn: bytes].
	form := RFBClientForm extent: updateBounds extent depth: serverFormat bitsPerPixel.
	form zrleDecode: (0@0 extent: updateBounds extent)
		from: zlibStream
		for: nil.
	self display: form on: image in: updateBounds.
	FastUpdate ifFalse: [Processor yield]
]

{ #category : #updating }
RFBClient >> rfbEncodingZlib: updateHeader [
	"Process a zlib encoding update."

	self log: 'rfbEncodingZlib: ', updateHeader printString.
	self connectionFailed: 'unimplemented'
]

{ #category : #updating }
RFBClient >> rfbEncodingZlibHex: updateHeader [
	"Process a zlib hextile encoding update."

	self log: 'rfbEncodingZlibHex: ', updateHeader printString.
	self connectionFailed: 'unimplemented'
]

{ #category : #'server messages' }
RFBClient >> rfbFramebufferUpdate [
	"Read and process a framebuffer update message."

	| header update |
	header := RFBFramebufferUpdateRectHeader new.
	update := socket receiveNew: RFBFramebufferUpdate.
	update nRects timesRepeat: [self processUpdate: (socket receiveData: header)]
]

{ #category : #'message dispatching' }
RFBClient >> rfbInitialisation [
	"Read and process an incoming server initialisation message."

	| message |
	message := socket receiveData: RFBServerInitialisation new.
	serverExtent := message width @ message height.
	serverFormat := message pixelFormat setReverseMaps.
	self log: 'server pixel format ', serverFormat printString.
	serverName := socket receiveString.
	self sendSetEncodings.
	self setExtent.
	window setLabel: serverName.
	socket
		initialiseForDepth: serverFormat bitsPerPixel
		mask: serverFormat pixelMask
		byteSwapped: serverFormat bigEndian not.
	state := #rfbNormal.
	updateRequestPending := false.
	self sendFullUpdateRequest
]

{ #category : #'message dispatching' }
RFBClient >> rfbNormal [
	"Receive and process an incoming normal protocol message."

	| type |
	type := (socket receiveData: (RFBMessage new: 1)) byteAt: 1.
	(type < 0) | (type >= MessageTypes size)
		ifTrue:
			[self log: 'illegal message type ' , type printString , ' received'.
			 ^self abort].
	self perform: (MessageTypes at: 1 + type).
	updateRequestPending := true.
	self sendPeriodicUpdateRequest
]

{ #category : #'message dispatching' }
RFBClient >> rfbProtocolVersion [
	"Receive and process an incoming protocol version message.  Check compatibility and reply with our protocol version, then expect an authentication type message (3.3) or a security types message (3.7)."

	| message protocolMajor |
	message := socket receiveData: (String new: 12).
	protocolMajor := (message copyFrom: 5 to: 7) asInteger.
	protocolMinor := (message copyFrom: 9 to: 11) asInteger.
	self log: 'server version ', protocolMajor printString, '.', protocolMinor printString.
	self log: 'viewer version ', ProtocolMajor printString, '.', ProtocolMinor printString.
	protocolMinor := protocolMinor min: ProtocolMinor.
	(protocolMinor < 7 and: [protocolMinor > 3]) ifTrue: [protocolMinor := 3].
	socket sendData: (RFBMessage protocolVersionMajor: ProtocolMajor minor: protocolMinor).
	protocolMajor == ProtocolMajor
		ifTrue:
			[protocolMinor == 3 ifTrue: [^state := #rfbAuthenticationType].
			 protocolMinor == 7 ifTrue: [^state := #rfbSecurityTypes]].
	self connectionFailed: 'incompatible protocol version'
]

{ #category : #'message dispatching' }
RFBClient >> rfbSecurityTypes [
	"We're in version 3.7 handshake.  Read a list of supported security schemes and reply with the one we prefer."

	| message count |
	message := socket receiveData: (RFBMessage new: 1).
	count := message type.
	count == 0 ifTrue: [^self connectionFailed].
	message := socket receiveData: (RFBMessage new: count).
	(message indexOf: RFBMessage rfbNoAuth) ~~ 0
		ifTrue:
			[socket sendData: (RFBMessage with: RFBMessage rfbNoAuth).
			 ^self sendClientInitialisation].
	(message indexOf: RFBMessage rfbVncAuth) ~~ 0
		ifTrue:
			[socket sendData: (RFBMessage with: RFBMessage rfbVncAuth).
			 ^state := #rfbAuthentication].
	^self connectionFailed: ['no supported security type']
]

{ #category : #'server messages' }
RFBClient >> rfbServerCutText [
	"Read and process a server cut text message"

	| length string |
	length := (socket receiveNew: RFBClientCutText) length.
	string := socket receiveData: (String new: length).
	Clipboard clipboardText: string asText
]

{ #category : #'server messages' }
RFBClient >> rfbSetColourMapEntries [
	"Read and process a set colourmap entries message".

	self log: 'rfbSetColourMapEntries'.
	self connectionFailed: 'unimplemented'
]

{ #category : #'client messages' }
RFBClient >> sendClientInitialisation [
	"Send a client initialisation message to the server.  This is a 1-byte flag indicating whether the connection should be shared."

	socket sendData: (RFBMessage with: (EnableShared ifTrue: [1] ifFalse: [0])).
	state := #rfbInitialisation
]

{ #category : #sending }
RFBClient >> sendData: aMessage [
	"Send aMessage to the server.  Assure mutually-exclusive access to the socket."

	sendLock critical:
		[[socket sendData: aMessage]
			on: Exception
			do: [self log: Exception printString; abort]]
]

{ #category : #'client messages' }
RFBClient >> sendFramebufferUpdateRequest: updateBounds incremental: incrementalFlag [
	"Send a framebufferUpdateRequest to the server."

	self sendData: (RFBFramebufferUpdateRequest
						bounds: updateBounds
						incremental: incrementalFlag)
]

{ #category : #private }
RFBClient >> sendFullUpdateRequest [
	"Send a full framebuffer update request for the visible area."

	self sendFramebufferUpdateRequest: scrollPane contentBounds incremental: false
]

{ #category : #private }
RFBClient >> sendFullUpdateRequestForRegion: rectangles [
	"Send a full framebuffer update request for the given rectangles."

	rectangles do:
		[:rect | self sendFramebufferUpdateRequest: rect incremental: false]
]

{ #category : #'client messages' }
RFBClient >> sendKeyEvent: keyCode down: downFlag [
	"Send a key event with keyCode to keySym translation."

	self
		sendData: (RFBKeyEvent key: keyCode down: downFlag);
		sendPeriodicUpdateRequest
]

{ #category : #private }
RFBClient >> sendModifiers: modifiers down: downFlag [
	"Send fake key press/release events for modifier keys."

	| mask |
	mask := 1.
	ModifierMap do:
		[:keySym |
		 (modifiers bitAnd: mask) ~~ 0
			ifTrue: [self sendKeyEvent: keySym down: downFlag].
		 mask := mask bitShift: 1]
]

{ #category : #private }
RFBClient >> sendPeriodicUpdateRequest [
	"Send an incremental framebuffer update request for the visible area only if a protocol message has been received since the last such request."

	updateRequestPending
		ifTrue:
			[self sendUpdateRequest.
			 updateRequestPending := false]
]

{ #category : #'client messages' }
RFBClient >> sendPointerEvent: buttonMask position: aPoint [
	"Send a pointer event."

	self
		sendData: (RFBPointerEvent
						buttonMask: (self encodeButtons: buttonMask)
						position: (self mousePoint: aPoint));
		sendPeriodicUpdateRequest
]

{ #category : #'client messages' }
RFBClient >> sendSetEncodings [
	"Send a set encodings message to the server according to the current preferences."

	| encodings preferred setEncodings |
	preferred := self preferredEncoding.
	(preferred == RfbEncodingZRLE and: [protocolMinor < 7])
		ifTrue: [preferred := RfbEncodingHextile].
	(encodings := OrderedCollection new)
		add: preferred;
		add: RfbEncodingHextile;
		add: RfbEncodingCoRRE;
		add: RfbEncodingRRE;
		add: RfbEncodingRaw.
	EnableXCursor ifTrue: [encodings add: RfbEncodingXCursor].
	setEncodings := RFBSetEncodings new: encodings size.
	encodings doWithIndex: [:encoding :index | setEncodings encodingAt: index put: encoding].
	self sendData: setEncodings
]

{ #category : #private }
RFBClient >> sendUpdateRequest [
	"Send an incremental framebuffer update request for the visible area."

	self sendFramebufferUpdateRequest: scrollPane contentBounds incremental: true
]

{ #category : #accessing }
RFBClient >> serverFormat [
	"Answer the pixel format in use on the server."

	^serverFormat
]

{ #category : #private }
RFBClient >> setDefaultEncoding: encodingNumber [
	"Set the default encoding.  If the client is connected, change the encoding in use for the session."

	DefaultEncoding := encodingNumber.
	self isActive ifTrue: [self sendSetEncodings]
]

{ #category : #private }
RFBClient >> setExtent [
	"Set the extent of the server desktop."

	| form |
	serverFormat isNil
		ifFalse:
			[form := RFBClientForm extent: serverExtent depth: serverFormat bitsPerPixel.
			 self image: form.
			 scrollPane setScrollDeltas.
			 self isActive ifTrue: [self sendFullUpdateRequest]]
]

{ #category : #menu }
RFBClient >> showAboutWindow [
	"Display a cheesy about window."

	(StringHolder new contents: self aboutString)
		openLabel: 'About the RFB/VNC Client (viewer)'
]

{ #category : #menu }
RFBClient >> showHelpWindow [
	"Display a help window."

	(StringHolder new contents: self helpString)
		openLabel: 'Help for the RFB/VNC Client (viewer)'
]
