"
This class is the GUI driver to the RFBServer.

To configure the RFBServer using menus and a GUI evaluate in a workspace:

RFBServerGUI open

Also, when this class was loaded, it registered itelf o the world menu (maybe you must find it over several
submenus) as 'RFB/VNC Server'. There you cn find the RFBServerGUI menu.

"
Class {
	#name : #RFBServerGUI,
	#superclass : #Object,
	#instVars : [
		'server'
	],
	#category : #'RFB-Server'
}

{ #category : #private }
RFBServerGUI class >> menu [
	| serverGUI |
	serverGUI := self new.
	
	^(RFBMenuMorph new)
		defaultTarget: serverGUI;
		addTitle: '' updatingSelector: #menuTitle updateTarget: serverGUI;
		add: [serverGUI startStopLabel] action: #doStartStop help: 'Start or stop the server.';
		addLine;
		add: 'passwords' subMenu: ((RFBMenuMorph new)
			defaultTarget: serverGUI;
			add: 'set interactive password...' action: #setFullPassword
				help: 'Set the password required for full (interactive) connections.';
			add: 'set view-only password...' action: #setViewPassword
				help: 'Set the password required for view-only (non-interactive) connections.';
			addLine;
			add: 'allow empty passwords'
				get: [serverGUI server allowEmptyPasswords] set: [serverGUI toggleAllowEmptyPasswords]
				help: 'Allow connections even when no server passwords are set.';
			yourself);
		add: 'connections' subMenu: ((RFBMenuMorph new)
			defaultTarget: serverGUI;
			add: 'allow local connections'
				get: [serverGUI server allowLocalConnections] set: [serverGUI toggleAllowLocalConnections]
				help: 'Allow connections from local clients (the loopback address).';
			add: 'allow remote connections'
				get: [serverGUI server allowRemoteConnections] set: [serverGUI toggleAllowRemoteConnections]
				help: 'Allow connections from remote clients (non-loopback addresses).';
			add: 'allow interactive connections'
				get: [serverGUI server allowInputEvents] set: [serverGUI toggleAllowInputEvents]
				help: 'Allow remote viewers to send mouse and keyboard events.';
			addLine;
			add: 'view current connections...' action: #doViewConnections
				help: 'View a list of the current connections.';
			add: 'close all connections...' action: #doCloseAllConnections
				help: 'Close all open connections (without restarting the server).';
			addLine;
			add: 'open reverse connection...' action: #doReverseConnection
				help: 'Open a connection from this server to a listening viewer.  (The viewer needs to have been started in "listen" mode and you need to know its host IP address or name.)';
			yourself);
		add: 'sharing' subMenu: ((RFBMenuMorph new)
			defaultTarget: serverGUI;
			add: 'automatically share connections'
				get: [serverGUI server isConnectionTypeShared] set: [serverGUI server connectionTypeShared]
				help: 'New connections are automatically shared with existing connections.';
			add: 'disconnect exising clients'
				get: [serverGUI server isConnectionTypeDisconnect] set: [serverGUI server connectionTypeDisconnect]
				help: 'Disconnect all existing connections whenever a new connection is accepted.';
			add: 'refuse concurrent connections'
				get: [serverGUI server isConnectionTypeRefuse] set: [serverGUI server connectionTypeRefuse]
				help: 'Refuse new connections if a client is already connected.';
			yourself);
		add: 'performance' subMenu: ((RFBMenuMorph new)
			defaultTarget: serverGUI;
			add: 'allow ZRLE encoding'
				get: [serverGUI server allowZRLE] set: [serverGUI toggleAllowZRLE]
				help: 'Allow clients to use ZRLE encoding (very CPU instensive on the server).';
			add: 'conserve memory'
				get: [serverGUI server conserveMemory] set: [serverGUI toggleConserveMemory]
				help: 'Conserve memory by splitting large updates into many smaller ones.';
			add: 'enable damage filtering'
				get: [serverGUI server enableDamageFilter] set: [serverGUI toggleEnableDamageFilter]
				help: 'Try hard to avoid updating undamaged screen areas.  This consumes vast quantities of memory.';
			add: 'filter damage for raw encoding'
				get: [serverGUI server enableRawFilter] set: [serverGUI toggleEnableRawFilter]
				help: 'Use damage filering (if enabled) even with raw encoding.';
			yourself);
		add: 'debugging' subMenu: ((RFBMenuMorph new)
			defaultTarget: serverGUI;
			add: 'enable debugging' get: [serverGUI server enableDebugging] set: [serverGUI toggleEnableDebugging]
				help: 'Open a Debugger if an error occurs.  (If this option
is not set then errors are silently ignored
and the offending connection is closed.)';
			add: 'enable logging' get: [serverGUI server enableLogging] set: [serverGUI toggleEnableLogging]
				help: 'Retain a log of client connections.  (Reset each time the server is started.)';
			add: 'enable verbose logging' get: [RFBSession logging] set: [RFBSession logging: RFBSession logging not]
				help: 'Write detailed information to the server log.';
			add: 'monitor memory use' get: [serverGUI server enableMemoryLog] set: [serverGUI toggleEnableMemoryLog]
				help: 'Monitor memory usage.  To see the results, choose "view current connections".  (Data reset each time the connections are viewed.)';
			addLine;
			add: 'view server log...' action: #doViewLog
			help: 'Open a window containing the current contents of the server log.';
			yourself);
		addLine;
		add: 'help...' action: #doShowHelpWindow help: 'Open a window describing this menu in detail.';
		add: 'about...' action: #doShowAboutWindow help: 'Open the Cheezoid About Window.';
		addStayUpItem;
		stayUp: true
]

{ #category : #'user interface' }
RFBServerGUI class >> open [
	"RFBServerGUI open"

	self menu openInHand
]

{ #category : #private }
RFBServerGUI class >> worldMenuOn: aBuilder [ 
	<worldMenu>
	
	(aBuilder item: #vncServer)
		parent: #Tools;
		label: 'VNC Server';
		action: [ self open ];
		help: 'Configure access to this desktop from remote VNC viewers.'
]

{ #category : #private }
RFBServerGUI >> aboutString [
	"Answer the contents of the about window."

	^'
		*** RFBServer: a RFB/VNC server written entirely in Squeak. ***

  (If you don''t know what RFB and VNC are, go look at "http://www.realvnc.com"
  and/or "http://www.tightvnc.com".)

	Copyright (C) 2004 by Ian Piumarta
	All Rights Reserved.

	Commissioned (and then donated to the Squeak community) by:

		Hewlett-Packard Laboratories
		1501 Page Mill Road
		Palo Alto, CA 94304
		http://hpl.hp.com

	Released under the terms of: The Squeak License

	Send bug reports, suggestions, unsolicited gifts, etc., to: ian.piumarta@inria.fr

	Send complaints and other negative vibes to: nobody@localhost

  Enjoy!'
]

{ #category : #authentication }
RFBServerGUI >> askForPassword: type [
	"Ask for a password.  If the user refuses to supply one, try insisting.  Answer the password (if one is supplied) or an empty String (if the user wants no password) or nil (if the user gives up)."
	
	| pass |
	pass := UIManager default requestPassword: 'Password for ' , type , ' VNC connections?'.
	pass isNil ifTrue: [ ^ nil ].
	pass isEmpty 
		ifTrue: [ 
			(UIManager default confirm: 'Do you really want to allow anyone to connect to this server?')
				ifTrue: [^pass]
				ifFalse:
						[self inform: 'Password unchanged.'.
						 ^nil]].
	^pass
]

{ #category : #'user interface' }
RFBServerGUI >> doCloseAllConnections [
	"Close all active connections."

	self server isRunning ifFalse: [^self].
	self server hasConnections ifFalse: [^self].
	(self confirm: 'Really close the ', self server numConnections printString, ' active connection(s)?')
		ifTrue: [ self server terminateSessions ]
]

{ #category : #'user interface' }
RFBServerGUI >> doReverseConnection [
	"Open a reverse connection to a remote, listening viewer."

	| clientSocket |
	self server isRunning ifFalse: [^self inform: 'The RFBServer is not running.'].
	(clientSocket := RFBSocket connectedToViewer) isNil ifTrue: [^self].
	self log: 'reverse connection to ', clientSocket peerName.
	self server enableLogging ifTrue: [Transcript endEntry].
	(RFBSession withServer: self server socket: clientSocket reverse: true) start
]

{ #category : #'user interface' }
RFBServerGUI >> doShowAboutWindow [
	"Display a cheesy about window."

	(StringHolder new contents: self aboutString)
		openLabel: 'About the RFB/VNC Server'
]

{ #category : #'user interface' }
RFBServerGUI >> doShowHelpWindow [
	"Display a help window."

	(StringHolder new contents: self helpString)
		openLabel: 'Help for the RFB/VNC Server'
]

{ #category : #'user interface' }
RFBServerGUI >> doStartServer [
	"Start the server."

	| display |
	display := UIManager default request: 'Display number?' initialAnswer: '0'.
	display isEmptyOrNil ifTrue: [^self].
	display := display asInteger.
	display isNil ifTrue: [^self].
	self server start: display
]

{ #category : #'user interface' }
RFBServerGUI >> doStartStop [
	"Start or stop the server."

	self server isRunning ifFalse: [self doStartServer] ifTrue: [self doStopServer]
]

{ #category : #'user interface' }
RFBServerGUI >> doStopServer [
	"Stop the server."

	self server hasConnections
		ifTrue:
			[(self confirm: 'Really stop the server?  (All connections will be closed.)')
				ifFalse: [^self]].
	self server stop
]

{ #category : #'user interface' }
RFBServerGUI >> doViewConnections [
	"Open a window containing a summary of the currently active connections."

	| details |
	self server isRunning ifFalse: [^self inform: 'The server is not running'].
	self server hasConnections ifFalse: [^self inform: 'There are no connections at this time.'].
	details := String streamContents: [:stream |
		self server connections do: [:conn |
			stream nextPutAll: conn description; cr]].
	(StringHolder new contents: details)
		openLabel: 'Current RFB/VNC connections' 
]

{ #category : #'user interface' }
RFBServerGUI >> doViewLog [
	"Open a window containing the current contents of the server log."

	(StringHolder new contents: RFBLog contents)
		openLabel: 'Current RFB/VNC server log' 
]

{ #category : #private }
RFBServerGUI >> helpString [
	"Answer the contents of the help window."

	^
'*** Configuration and control

To open the configuration/control menu, evaluate the following expression:

	RFBServerGUI open

Limited configuration and control is possible via messages to RFBServer.  See the RFBServer class comment (included below) for more information.

*** Menu items

** Title bar

The title includes an indication of the server status.  If it shows "(stopped)" then the server isn''t running.  If it shows ":<n>" for some integer <n> then the server is running and is accepting connections for display number <n>.

** start/stop server...

This item toggles the server between running and stopped.  If the server is running and there are no connections, it will be labeled simply "stop server".  If there are active connections it will labeled "stop server..." to indicate a subsequent confirmation panel that gives you a chance to change your mind.

** Sub menu: passwords

Everything to do with configuring server passwords.

* Set full password...

Opens a prompter in which you can enter a password for "full" (interactive) connections.  If you leave the password blank then you will be prompted whether you really mean to let absolutely anyone connect.  If you say "yes" then the password will be cleared.  If you say no then the password will remain unchanged.

* Set view password...

As above but concerns the password that is used for view-only (non-interactive) connections.  The (remote) viewer is asked only once for a password, and the (local) server tries to authenticate it twice: once for a full connection and if that fails once again for a view-only connection.

* allow empty passwords

When selected, this option will permit connections even when there is no password set.  Be very careful if you enable this: if you have no interactive password then this option will allow anyone on the planet (who is able to reach your machine via the Internet) to connect to your running image and interact with it.  (Note that this includes opening a fie list and/or a "command shell" to do arbitrary damage to your machine.  You Have Been Warned.)

** Sub menu: connections

Everything to do with connection management.

* allow local connections

If enabled then connections coming from the loopback address (or the IP address of the local interface) will be allowed.

* allow remote connections

If enabled then connections coming from non-local addresses will be allowed.  If both this and "allow local connections" are disabled then (obviously) nobody will be able to connect.

* allow interactive connections

If this is set then connections can be fully-interactive (mouse and keyboard events will be processed).  If this is not set then incoming mouse and keyboard events will be ignored (regardless of whether the remote user managed to guess the "full connection" password or not).

* view current connections...

Pops open a window containing a list of the currently-active connections.

* close all connections...

Closes all active connections without restarting the server.  You will be required to confirm that you really mean to do this.

* open reverse connection...

Opens an outgoing connection from the server to some remote viewer.  The viewer must have been started in "listen" mode (it sits there waiting for a server to contact it, then pops open its viewer window).  You will be asked for the IP address or host name of the machine on which the listening viewer is running.

** Sub menu: sharing

Everything to do with managing multiple connections.  The following three options are mutually-exclusive (and they will behave like "radio buttons").

* automatically share connections

If this is set then incoming connections that are not explicitly "shared" (willing to coexist with other remote viewers) will be implicitly shared.  There will be no restriction on how many concurrent connections can be active at any one time.

* disconnect existing clients

An incoming connection that is not explicitly "shared" will cause all existing connections to be closed.  This guarantees exclusive access for the most recent non-shared connection.

* refuse concurrent connections

Any incoming connection will be refused systematically if there is already an active connection.  This guarantees exclusive access on a first-come first-served basis.

** Sub menu: performance

Everything to do with stuff you can tweak to trade CPU time and memory against bandwidth and speed.

* allow ZRLE encoding

ZRLE encoding is the most compact of all encodings defined by the RFB protocol.  It constructs a colour palette (so that pixels can be represented by 1, 2, 4 or 8 bits rather than up to 32 bits of true-colour), and then run-length encodes the update region using the palette.  It then "zip" compresses the result before sending it to the remote viewer.  In other words, it is very CPU-intensive.  This option gives you a chance to refuse to supply ZRLE updates to a remote viewer, should you value your CPU time more highly than their response time.

* conserve memory

When sending an update to a remote viewer, the server generally captures the entire update region from the screen into a single Form.  This Form might be huge (e.g., during the initial screen update or when you''re dragging a window around).  If you select this option then updates will always be chopped up so that they do not exceed 16384 pixels (64 Kbytes at depth 32).  This will mean slower updates, less efficient encoding, and slightly more data being sent down the wire.  On the other hand, it spares you from potential transient peak memory usage measured in megabytes for a very large screen update.

* enable damage filtering

Morphic is really bad at repainting only damaged areas.  The World damage recorder (usually) manages to eliminate duplicated damage rectangles, but it makes no attempt to verify that the damage is real.  Selecting this option enables an algorithm in the server that verifies the validity of all damage reported by Morphic.  It does this by retaining a copy of the entire Display and then comparing the ostensibly-damaged regions with that copy.  Only areas in which differences are found are retained for subsequent screen update messages.  This is very effective, but will cost you a verbatim copy of your Display object (which might be an additional 7Mbytes of memory overhead, if your screen is 1600x1200x32).

* filter damage for raw encoding

Raw encoding (in which updates are just rectangles of raw pixels) are generally only used when the viewer and server are running on the same machine.  In such cases, the damage filtering described above may well be pointless since the time taken to just send the (undamaged) pixels down the wire might be less than the time required to verify the damage.  This option lets you choose whether to filter the damage (option set) or just send everything that Morphic reports as damage (option not set).  Note that this only applies when using raw encoding and with the previous option (enable damage filtering) turned on.

** Sub menu: debugging

Everything to keep the determined hacker happy.

* enable debugging

Error conditions are normally dealt with silently: the error is squashed, the offending connection closed, and the associated server processes terminated.  This is what happens when this option is not enabled.  Conversely, if this option is set, then any error condition (including a broken or closed connection) will cause a Debugger window to pop open.  This is very useful if you think you''ve found a bug in the RFBServer code and you want to track it down.

* enable logging

Setting this option will cause connection and disconnection information to be written to a server log (and probably to the Transcript too, if you have one of those open).

* enable verbose logging

Setting this increases the level of detail in the information written to the server log.  (For example, it will include most of the interesting information exchanged during connection handshake including preferred encodings, server and client pixel formats, etc.)  This option has no effect unless the previous option (enable logging) is set.

* monitor memory use

If this is selected then the server will measure (approximately) the amount of CPU time consumed and transient heap memory allocated when sending screen updates.  The information is displayed along with each connection in the "view current connections..." window described above.  This option is only intended to be used to adjust the "performance" options to a confortable level.  Leaving it turned on is not recommended.  (For example: when this option is set, for every screen update message sent to the viewer, the server performs a garbage collection and then disables any allocation count-based triggering of collections for the duration of the update.  You probably don''t want to run your image for long with this kind of abuse happening.)

** help...

You already know about this one (otherwise you wouldn''t be reading this text).

** about...

Displays a cheesy little "about" window.  It doesn''t contain anything of interest, except maybe for an email address where you can report bugs and/or confusion.

*** The RFBServer class comment

As promised at the beginning off this tirade, below is a copy of the class comment for RFBServer.  It includes some performance/aesthetics considerations as well as information about how to control the server by sending it messages.  Here it comes, verbatim:

' , RFBServer comment
]

{ #category : #initialization }
RFBServerGUI >> initialize [
	 server := RFBServer current
]

{ #category : #logging }
RFBServerGUI >> log: aMessage [
	"Write a messageString on the log."
	
	^ RFBLog log: 'RFBServerGUI ', aMessage
]

{ #category : #private }
RFBServerGUI >> menuTitle [
	"Answer a suitable title for the server control panel, depending on whether a server is running at this time."

	^'RFBServer ', (self server isRunning
						ifFalse: ['(stopped)']
						ifTrue: [':', self server displayNumber printString])
]

{ #category : #accessing }
RFBServerGUI >> server [
	^ server
]

{ #category : #authentication }
RFBServerGUI >> setFullPassword [
	| password |
	password := self askForPassword: 'interactive'.
	password isNil ifFalse: [ self server setFullPassword: password ]
]

{ #category : #authentication }
RFBServerGUI >> setViewPassword [
	| password |
	password := self askForPassword: 'view-only'.
	password isNil ifFalse: [ self server setViewPassword: password ]
]

{ #category : #private }
RFBServerGUI >> startStopLabel [
	^ self server isRunning
		ifFalse: ['start server...']
		ifTrue: ['stop server' , (self server hasConnections ifFalse: [''] ifTrue: ['...'])]
]

{ #category : #'user interface' }
RFBServerGUI >> toggleAllowEmptyPasswords [
	self server allowEmptyPasswords: (self server allowEmptyPasswords not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleAllowInputEvents [
	self server allowInputEvents: (self server allowInputEvents not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleAllowLocalConnections [
	self server allowLocalConnections: (self server allowLocalConnections not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleAllowRemoteConnections [ 
	self server allowRemoteConnections: (self server allowRemoteConnections not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleAllowZRLE [
	self server allowZRLE: (self server allowZRLE not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleConserveMemory [
	self server conserveMemory: (self server conserveMemory not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleEnableDamageFilter [
	self server enableDamageFilter: (self server enableDamageFilter not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleEnableDebugging [
	self server enableDebugging: (self server enableDebugging not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleEnableLogging [
	self server enableLogging: (self server enableLogging not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleEnableMemoryLog [
	self server enableMemoryLog: (self server enableMemoryLog not)
]

{ #category : #'user interface' }
RFBServerGUI >> toggleEnableRawFilter [
	self server enableRawFilter: (self server enableRawFilter not)
]
