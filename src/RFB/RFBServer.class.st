"
I provide interaction with the Squeak display for remote ""viewers"" using the RFB (Remote Frame Buffer, sometimes also called ""VNC"" for Virtual Network Computing) protocol developped (initially) by AT&T and (later) by RealVNC.

** CONTROL THE SERVER WITH A MENU

The easiest way to configure and control the server is to open the menu:

	RFBServerGUI open

(which you can pin to the desktop if you like).



** CONTROL THE SERVER WITH CONVENIENCE METHODS

There are handy methods to quickly start/stop the server (using the default preferences and allowing empty
 passwords).

To start the server on the default display #0

     RFBServer start

To start the server on other display:

     RFBServer start: 1

To stop the server:

	RFBServer stop.
	
	
	
** CONTROL THE SERVER PROGRAMMATICALLY

The PREFERED way to interact, configure and control the server is programmatically.

The server is implemented as a singleton because only a server can run at any time. 
Access the singleton with:

     RFBServer current

You can completely configure the server by sending messages to the singleton.  The most important of these is:

	RFBServer current configureForMemoryConservation
	
that set the preferences in a way to conserve memory on the server side.

To set the view-only and full (interactive) passwords:

	RFBServer current setFullPassword: aFullPassword.
	RFBServer current setViewPassword: aViewPassword.
	
To disable the empty passwords

	RFBServer current allowEmptyPasswords: false.
	
To reset the preferences to their default values:

	RFBServer current initializePreferences.
	
To start the server on a given display:

	RFBServer current start: aDisplayNumber.
	
To stop the server:

	RFBServer current stop.
	
This is a full example for configuring the server by code:

	RFBServer current
 		initializePreferences;
		configureForMemoryConservation;
		allowEmptyPasswords: false;
		setFullPassword: 'secret';
		setViewPassword: 'secret too';
		start: 0.

See the comments in the methods of the RFBServer for more options.

** PERFORMANCE HINTS

If you are running Squeak and the viewer on the same machine (which might happen if you start the image ""headless"" and suddenly need to interact with it), or if there is a fast connection (100Mbps or better) between you and Squeak, then always use ""raw"" encoding.  (If you're running a non-headless Unix Squeak remotely over a 100Mbps connection then you shouldn't be using RFB/VNC at all: use X11 instead.)

When using any encoding other than ""raw"", avoid running the (native) Squeak display at depth 32; use 8 or 16 instead.  This permits various optimisations using BitBlt that significantly decrease the computation needed to analyse the contents of large screen areas.  Although this won't (generally) affect the speed at which remote viewers receive screen updates, it will reduce the load on your running image and free up the processor for doing useful stuff instead.

Avoid ""RRE"" encoding if you can.  This encoding must analyse the entire update area before sending anything to the viewer.  The result is a long pause (while analysing the update area) followed by saturation of the connection while the entire area is sent at once.  Two time-consuming activities that are strictly sequential when using ""RRE"".  Conversely, ""Hextile"" and ""CoRRE"" split the update area into subrectangles and send each one independently.  This is better for two reasons.  Firstly, it introduces parallelism by overlapping the communication and computation.  Secondly, it's psychologically (much) less stressful on you, since the viewer will update the window contents incrementally -- giving you something to watch while waiting for a large update to complete.  (Note that some viewers deliberately increase your stress level by deferring all graphical output while receiving the initial framebuffer contents.  Ho hum.)

If you are on a slow connection then (obviously) avoid leaving anything on your desktop that 'moves' (a ClockMorph, the Squeak logo with the roving eyes, etc...).

In general:  When running locally, always use ""Raw"" encoding at any bit depth.  When running remotely, over a medium or slow speed connection, always use ""Hextile"" encoding at depth 8 or 16, unless you have a good reason not to.

If you have a really hopeless connection (e.g., a very slow modem) consider using ""ZRLE"" (if your viewer supports it).  This behaves somewhat like Hextile but also ""zip"" compresses the data before sending it.  Needless to say, ZRLE is extremely CPU-intensive at the server (Squeak) end.

** AESTHETIC HINTS

If you are using the TightVNC viewer then always enable the 'x11cursor' extension.  This (greatly) improves the behaviour of the cursor (it should be identical to the behaviour you'd see if running Squeak locally), eliminates the annoying dot that normally tracks your local cursor position, and decreases (slightly) the bandwidth used.

If you want to use 8-bit colour in the viewer then either:

	- Run Squeak in 8-bit depth and enable 'own colourmap' in the viewer.  Depending on your window system, this may introduce unpleasant artefacts when the pointer enters/leaves the viewer window.

	- Run Squeak in 16-bit depth and use the 'bgr223' pixel format in the viewer.  This provides the most accurate mapping of Squeak colours into the standard 8-bit 'true'-colour pallette of the viewer.  (The results are better than you might expect.)

** CAVEATS

While I am running (between sending me #start and #stop) I replace the Display and Sensor objects with something (almost but not quite entirely) equivalent.  When I am not running I do not leave any trace of my existence behind.

Active sessions to remote viewers involve several inter-communicating processes running at higher than user priority.  In the unlikely event that you hit the interrupt key while one of these processes is in a critical region, quitting the resulting debugger will effectively freeze the remote session.

RealVNC (and many other) viewers do not support the ""X11Cursor"" extension, which was introduced by TightVNC.

TightVNC (and many other) viewers do not support ""ZRLE"" encoding, which was introduced by RealVNC.

** BUGS

Screen updates correspond faithfully to the ""damaged regions"" maintained by Morphic.  This often results in undamaged parts of the display being updated unnecessarily.  This isn't too bad when running locally (you probably won't even notice it most of the time), but can be disasterous when viewing remotely over a slow connection.  The correct solution would be to fix Morphic so that damaged regions accurately reflect the parts of the Display that have been modified (and not simply repainted with the same content) -- so that local screen updates benefit too.  The pragmatic solution (adopted here) is to filter the damage reported by Morphic to eliminate the bogus regions.  (The classes RFBDamageRecorder and RFBDamageFilter take care of the unpleasant details.)
"
Class {
	#name : #RFBServer,
	#superclass : #Object,
	#instVars : [
		'socket',
		'sessions',
		'sessionsSema',
		'process',
		'port',
		'localHostName',
		'loopbackAddress',
		'isRunning',
		'fixedKey',
		'vncPasswords',
		'allowEmptyPasswords',
		'allowInputEvents',
		'allowLocalConnections',
		'allowRemoteConnections',
		'connectionPriority',
		'allowZRLE',
		'conserveMemory',
		'enableDamageFilter',
		'enableRawFilter',
		'enableDebugging',
		'enableLogging',
		'enableMemoryLog'
	],
	#classVars : [
		'Current'
	],
	#category : #'RFB-Server'
}

{ #category : #snapshot }
RFBServer class >> addToSnapshotList [
	Smalltalk addToStartUpList: self;
		addToShutDownList: self
]

{ #category : #accessing }
RFBServer class >> current [
	"Answer the singleton RFBServer instance"
	
	Current ifNil: [ Current := RFBServer basicNew initialize ].
	^ Current
]

{ #category : #'instance creation' }
RFBServer class >> new [
	"There is only one of these, so don't let the user make a new one!!"
	^ self error: 'Class ', self name, ' cannot create new instances. Try ', self name, ' current'
]

{ #category : #snapshot }
RFBServer class >> removeFromSnapshotList [
	Smalltalk removeFromStartUpList: self;
		removeFromShutDownList: self
]

{ #category : #private }
RFBServer class >> reset [
	"Reset the only instance of this class." 
	self current isRunning ifTrue: [ self current stop ].
	Current := nil
]

{ #category : #accessing }
RFBServer class >> server [
	"Answer the singleton RFBServer instance."

	^ self current
]

{ #category : #controlling }
RFBServer class >> start [
	"RFBServer start"

	^self start: 0 "Starts on display 0 by default"
]

{ #category : #controlling }
RFBServer class >> start: displayNumber [
	"RFBServer start"

	self current isRunning
		ifFalse:
			[ self current start: displayNumber ]
		ifTrue:
			[self current log: 'server already running?']
]

{ #category : #snapshot }
RFBServer class >> startUp: resuming [
	"If we're coming back from snapshot and quit and the server was running we restart the server."

	resuming ifTrue: [
		self current isRunning ifTrue: [ 
			self current stop.
			self current start: self current displayNumber ]]
]

{ #category : #controlling }
RFBServer class >> stop [
	"RFBServer stop"

	self current isRunning
		ifFalse:
			[self current log: 'server not running?']
		ifTrue:
			[self current stop ]
]

{ #category : #'class initialisation' }
RFBServer class >> unload [
	"RFBServer is being removed from the image."

	self current stop
]

{ #category : #sessions }
RFBServer >> addSession: rfbSession [
	"Add rfbSession to the list of active sessions."

	sessionsSema critical: [sessions add: rfbSession]
]

{ #category : #sessions }
RFBServer >> allowConnection: clientSocket [
	"Answer whether the connection from clientSocket should be allowed."

	| peer |
	(sessions notEmpty and: [self isConnectionTypeRefuse])
		ifTrue: [^false].
	(self allowLocalConnections and: [ self allowRemoteConnections ])
		ifTrue: [^true].
	peer := clientSocket remoteAddress.
	(peer = loopbackAddress or: [peer = NetNameResolver localHostAddress])
		ifTrue: [^ self allowLocalConnections ]
		ifFalse: [^ self allowRemoteConnections ]
]

{ #category : #accessing }
RFBServer >> allowEmptyPasswords [
	"Allow connections even when no server passwords are set?"
	^ allowEmptyPasswords
]

{ #category : #accessing }
RFBServer >> allowEmptyPasswords: anObject [
	allowEmptyPasswords := anObject
]

{ #category : #accessing }
RFBServer >> allowInputEvents [
	"Allow remote clients to send mouse and keyboard events"
	^ allowInputEvents
]

{ #category : #accessing }
RFBServer >> allowInputEvents: anObject [
	allowInputEvents := anObject
]

{ #category : #accessing }
RFBServer >> allowInteractiveConnections [
	"Answer whether the server allows clients to send mouse and keyboard events."

	^ self allowInputEvents 
]

{ #category : #accessing }
RFBServer >> allowInteractiveConnections: aBoolean [
	self allowInputEvents: aBoolean
]

{ #category : #accessing }
RFBServer >> allowLocalConnections [
	"Allow connections from local clients (the loopback address)"
	^ allowLocalConnections
]

{ #category : #accessing }
RFBServer >> allowLocalConnections: anObject [
	allowLocalConnections := anObject
]

{ #category : #accessing }
RFBServer >> allowRemoteConnections [
	"Allow connections from remote clients (non-loopback addresses)"
	^ allowRemoteConnections
]

{ #category : #accessing }
RFBServer >> allowRemoteConnections: anObject [
	allowRemoteConnections := anObject
]

{ #category : #accessing }
RFBServer >> allowZRLE [
	"Allow clients to use ZRLE encoding (very CPU instensive on the server)."
	
	^ allowZRLE
]

{ #category : #accessing }
RFBServer >> allowZRLE: anObject [
	allowZRLE := anObject
]

{ #category : #authenticating }
RFBServer >> authenticateChallenge: authChallenge response: authResponse [
	"Authenticate the response to the given challenge.  Answer true if authentication succeeds for an interactive connection, false if it succeeds for a view-only connection, or nil if the authentication fails for any reason."

	| password encryptedChallenge |
	self hasPassword ifFalse: [^nil].		"We should not be here."
	1 to: 2 do: [:type |
		(vncPasswords at: type) isNil
			ifFalse:
				[password := ByteArray new: 8.
				 encryptedChallenge := ByteArray new: 16.
				 RFB3DES new
					decryptionKey: fixedKey;
					des: (vncPasswords at: type) to: password;
					encryptionKey: password;
					des: authChallenge to: encryptedChallenge.
				 password atAllPut: 0.
				 encryptedChallenge = authResponse ifTrue: [^type == 1]]].
	^nil
]

{ #category : #'server events' }
RFBServer >> beep [
	"The Display just beeped.  Tell all sessions to ring their viewer's bell."

	sessionsSema critical: [sessions do: [:session | session beep]]
]

{ #category : #accessing }
RFBServer >> configureForMemoryConservation [
	self conserveMemory: true.
	self enableDamageFilter: false.
	self enableRawFilter: false
]

{ #category : #accessing }
RFBServer >> connectionTypeDisconnect [
	"Disconnect all existing connections whenever a new connection is accepted"
	
	connectionPriority := #disconnect
]

{ #category : #accessing }
RFBServer >> connectionTypeRefuse [
	"Refuse new connections if a client is already connected"
	
	connectionPriority := #refuse
]

{ #category : #accessing }
RFBServer >> connectionTypeShared [
	"New connections are automatically shared with existing connections"
	
	connectionPriority := #shared
]

{ #category : #private }
RFBServer >> connections [
	"Answer an Array of all the active sessions."

	^sessions asArray
]

{ #category : #accessing }
RFBServer >> conserveMemory [
	"Answer whether the session should try to conserve memory by splitting large screen updates into a series of smaller upodates.  Note that this is a space/speed tradeoff: when not conserving memory, large updates might require (very briefly) temporary objects toalling three times the size of the Display screen."
	
	^ conserveMemory
]

{ #category : #accessing }
RFBServer >> conserveMemory: anObject [
	conserveMemory := anObject
]

{ #category : #'server events' }
RFBServer >> currentCursor: newCursor [
	"Squeak just changed the cursor shape.  Inform the sessions."

	sessionsSema critical: [sessions do: [:session | session currentCursor: newCursor]]
]

{ #category : #accessing }
RFBServer >> displayNumber [
	"Answer the display number on which this server is listening."

	^self displayNumberFromPortNumber: port
]

{ #category : #private }
RFBServer >> displayNumberFromPortNumber: portNumber [
	"Answer the RFB display number corresponding to the given IP portNumber."

	^portNumber - RFBSocket serverPortOffset
]

{ #category : #accessing }
RFBServer >> enableDamageFilter [
	"Answer whether the session should use a damage filter to eliminate bogus screen damage.  Note that this is a space/speed tradeoff: the damage filter hangs onto a verbatim copy of the entire Display screen.
	Try hard to avoid updating undamaged screen areas.  This consumes vast quantities of memory"
	
	^ enableDamageFilter
]

{ #category : #accessing }
RFBServer >> enableDamageFilter: anObject [
	enableDamageFilter := anObject
]

{ #category : #accessing }
RFBServer >> enableDebugging [
	"Open a Debugger if an error occurs.  (If this option is not set then errors are silently ignored
and the offending connection is closed.)"

	^ enableDebugging
]

{ #category : #accessing }
RFBServer >> enableDebugging: anObject [
	enableDebugging := anObject
]

{ #category : #accessing }
RFBServer >> enableLogging [
	"Retain a log of client connections.  (Reset each time the server is started.)"
	
	^ enableLogging
]

{ #category : #accessing }
RFBServer >> enableLogging: anObject [
	enableLogging := anObject
]

{ #category : #accessing }
RFBServer >> enableMemoryLog [
	"Answer whether the session should monitor how much memory it is using when sending screen updates (Data reset each time the connections are viewed.)"
	
	^ enableMemoryLog
]

{ #category : #accessing }
RFBServer >> enableMemoryLog: anObject [
	enableMemoryLog := anObject
]

{ #category : #accessing }
RFBServer >> enableRawFilter [
	"Answer whether the session should use a damage filter to eliminate bogus screen damage even when using raw encoding (and presumably running on the local host).
	Use damage filering (if enabled) even with raw encoding."
	
	^ enableRawFilter
]

{ #category : #accessing }
RFBServer >> enableRawFilter: anObject [
	enableRawFilter := anObject
]

{ #category : #authenticating }
RFBServer >> encryptPassword: password [
	"Encrypt a password."

	| block |
	block := ByteArray new: 8.
	1 to: (password size min: 8) do: [:i | block at: i put: (password at: i) asciiValue].
	password atAllPut: (Character value: 0).
	RFB3DES new
		encryptionKey: self fixedKey;
		des: block to: block.
	^block
]

{ #category : #sessions }
RFBServer >> enforcePriorityFor: rfbSession shared: sharedFlag [
	"The rfbSession has just been authenticated.  According to the connection priority in effect either disconnect existing clients or do nothing."

	(sharedFlag or: [ self isConnectionTypeShared]) ifTrue: [^self].
	(sessions reject: [:session | session == rfbSession]) do: [:session | session stop]
]

{ #category : #private }
RFBServer >> fixedKey [
	"Return the fixed key used to encode the session password before storing it."

	^ fixedKey
]

{ #category : #accessing }
RFBServer >> hasConnections [
	^ sessions isEmptyOrNil not
]

{ #category : #authenticating }
RFBServer >> hasFullPassword [
	^ (vncPasswords at: 1) notNil
]

{ #category : #authenticating }
RFBServer >> hasPassword [
	"Answer whether the server has one or both passwords set."

	^ self allowEmptyPasswords not or: [self hasViewPassword or: [self hasFullPassword]]
]

{ #category : #authenticating }
RFBServer >> hasViewPassword [
	^ (vncPasswords at: 2) notNil
]

{ #category : #'initialise-release' }
RFBServer >> initialize [
	"Set the initial state of the server."

	localHostName := NetNameResolver localHostName.
	fixedKey := #(23 82 107 6 35 78 88 7) asByteArray.
	loopbackAddress  := #(127 0 0 1) asByteArray.
	vncPasswords := Array new: 2 withAll: ''.
	isRunning := false.
	self initializePreferences.
	self log: 'initialised'
]

{ #category : #'initialise-release' }
RFBServer >> initializePreferences [
	"These are the default settings for the RFBServer preferences"

	self allowEmptyPasswords: true.
	self allowInputEvents: true.
	self allowLocalConnections: true.
	self allowRemoteConnections: true.
	self allowZRLE: false.
	self connectionTypeShared.
	self enableDebugging: false.
	self enableLogging: false.
	self enableMemoryLog: false.

	"By default doesn't try to conserve memory"
	self conserveMemory: false.
	self enableDamageFilter: true.
	self enableRawFilter: true.
]

{ #category : #private }
RFBServer >> installDisplay [
	"The RFBServer has just been started.  Install replacement, RFB-aware equivalents of the Display (for screen updates) and Sensor (for keyboard, mouse and cursor)."

	((Display isMemberOf: RFBDisplayScreen) and: [Sensor isMemberOf: RFBEventSensor])
		ifTrue:
			[Display rfbServer: self.
			 ^Sensor rfbServer: self].
	((Display isMemberOf: DisplayScreen) and: [Sensor isMemberOf: InputEventSensor])
		ifFalse: [^self error: 'Cowardly refusing to start RFB server over '
								, Display printString , ' '
								, Sensor printString].
	(Display := RFBDisplayScreen new copyFrom: Display) rfbServer: self; beDisplay.
	Sensor become: ((RFBEventSensor new copyFrom: Sensor) rfbServer: self).
	self log: 'RFBDisplayScreen, RFBEventSensor installed'
]

{ #category : #'server events' }
RFBServer >> invalidate: damagedRectangle [
	"The Display just changed in the given damageRectangle.  Inform each session."

	sessionsSema critical: [sessions do: [:session | session invalidate: damagedRectangle]]
]

{ #category : #accessing }
RFBServer >> isConnectionTypeDisconnect [
	^ connectionPriority == #disconnect
]

{ #category : #accessing }
RFBServer >> isConnectionTypeRefuse [
	^ connectionPriority == #refuse
]

{ #category : #accessing }
RFBServer >> isConnectionTypeShared [
	^ connectionPriority == #shared
]

{ #category : #accessing }
RFBServer >> isRunning [
	^ isRunning
]

{ #category : #accessing }
RFBServer >> localHostName [
	"Answer the name of the host on which the server is running."

	^localHostName
]

{ #category : #logging }
RFBServer >> log: aMessage [
	"Write a messageString on the log."
	
	^ RFBLog log: 'RFBServer ', aMessage
]

{ #category : #'server events' }
RFBServer >> mousePosition: mousePoint [
	"The pointer just moved.  Inform each session."

	sessionsSema critical: [sessions do: [:session | session mousePosition: mousePoint]]
]

{ #category : #'server events' }
RFBServer >> newDepth: depth [
	"Squeak just changed the Display depth.  Warn the sessions."

	sessionsSema critical: [sessions do: [:session | session newDepth: depth]]
]

{ #category : #accessing }
RFBServer >> numConnections [
	^ sessions ifNil: [0] ifNotNil: [ sessions size ]
]

{ #category : #private }
RFBServer >> portNumberFromDisplayNumber: displayNumber [
	"Answer the IP port number associated with the given RFB displayNumber."

	^RFBSocket serverPortOffset + displayNumber
]

{ #category : #private }
RFBServer >> removeDisplay [
	"The RFB server is shutting down.  Remove our fake Display and Sensor, replacing them with the originals."

	((Display isMemberOf: RFBDisplayScreen) and: [Sensor isMemberOf: RFBEventSensor])
		ifFalse: [^self].
	(Display := DisplayScreen new copyFrom: Display) beDisplay.
	Sensor become: (Sensor copyTo: InputEventSensor new).
	self log: 'RFBDisplayScreen. RFBEventSensor removed'
]

{ #category : #sessions }
RFBServer >> removeSession: rfbSession [
	"Remove a rfbSession from the list of active sessions."

	sessionsSema critical: [sessions remove: rfbSession].
	self enableLogging ifTrue: [Transcript endEntry].
]

{ #category : #'server process' }
RFBServer >> runLoop [
	"Run the server's connection accept loop."

	| connection |
	self log: 'running'.
	[ [ socket isValid ] whileTrue: [
		connection := socket waitForAcceptFor: 10.
		connection ifNotNil: [ self runSession: connection ] ] ]
			ifCurtailed: [ socket destroy ]
]

{ #category : #sessions }
RFBServer >> runSession: clientSocket [
	"Start a new session for the viewer connected on clientSocket."

	| peer |
	peer := clientSocket peerName.
	peer isNil ifTrue: [peer := NetNameResolver stringFromAddress: clientSocket remoteAddress].
	self log: 'connection from ', peer.
	self enableLogging ifTrue: [Transcript endEntry].
	(self allowConnection: clientSocket)
		ifTrue:
			[(RFBSession withServer: self socket: clientSocket reverse: false) start]
		ifFalse:
			[self log: 'connection refused because of server policy'.
			 clientSocket closeAndDestroy]
]

{ #category : #'scheduling priorities' }
RFBServer >> serverPriority [
	"Answer the scheduling priority at which the RFB server should run."

	^Processor lowIOPriority
"
		Processor userSchedulingPriority
		+ Processor userInterruptPriority
		// 2
"
]

{ #category : #'scheduling priorities' }
RFBServer >> sessionPriority [
	"Answer the priotity at which each viewer session should run."

	^Processor lowIOPriority
"
		Processor userSchedulingPriority
		+ Processor userInterruptPriority
		// 2
"
]

{ #category : #authenticating }
RFBServer >> setFullPassword: password [
	vncPasswords at: 1 put: (self encryptPassword: password)
]

{ #category : #authenticating }
RFBServer >> setViewPassword: password [
	vncPasswords at: 2 put: (self encryptPassword: password)
]

{ #category : #controlling }
RFBServer >> start: displayNumber [
	"Start an RFB server listening on the given displayNumber."

	self log: 'start'.
	
	"Reset the log on start"
	RFBLog resetLog.
	
	"Reset the session registry"
	sessions := IdentitySet new.
	sessionsSema := Semaphore forMutualExclusion.
	
	"Replace the display for a RFB enabled one"
	self installDisplay.

	"Start the server"	
	port := self portNumberFromDisplayNumber: displayNumber.
	socket := RFBSocket newTCP.
	socket listenOn: port backlogSize: 5.
	socket isValid ifFalse: [^self error: 'Could not create RFB server socket'].
	process := [self runLoop] forkAt: self serverPriority named: 'rfb'.
	isRunning := true.
	
	"Registers itself in the startup and shutdown image lists"
	self class addToSnapshotList.
	
	self log: 'started'
]

{ #category : #controlling }
RFBServer >> stop [
	"Stop the RFB server, closing all open viewer connections."

	self log: 'stop'.
	
	"Stop the server "
	process ifNotNil: [ process terminate ].
	process := nil.
	socket ifNotNil: [ socket closeAndDestroy ].
	isRunning := false.
	
	"Reset the session registry"
	self terminateSessions.
	sessions := nil.
	sessionsSema := nil.

	"Restore the normal RFB-less display"
	self removeDisplay.
	
	"Unregisters itself from the startup and shutdown image lists"
	self class removeFromSnapshotList.

	self log: 'stopped'.
]

{ #category : #sessions }
RFBServer >> terminateSessions [
	"Close down all active sessions."

	| moribund |
	[sessions isEmptyOrNil]
		whileFalse:
			[sessionsSema critical: [moribund := sessions copy].
			 moribund do: [:session | session stop]].
]
