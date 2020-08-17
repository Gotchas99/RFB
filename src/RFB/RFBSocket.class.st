"
I am a kind of Socket that understands how to transmit word objects and the originalContents of a Stream.
"
Class {
	#name : #RFBSocket,
	#superclass : #Socket,
	#instVars : [
		'hostName'
	],
	#classVars : [
		'LastServerAddress',
		'MaximumTransmissionUnit',
		'RFBSocketInstances',
		'RfbListenPortOffset',
		'RfbPortOffset',
		'SendTimeout',
		'ServerPortOffset',
		'ViewerPortOffset'
	],
	#category : #'RFB-Communication'
}

{ #category : #'instance creation' }
RFBSocket class >> acceptFrom: aSocket [
	"Answer a new RFBSocket for the connection just accepted on aSocket."

	^RFBSocketInstances add: (super acceptFrom: aSocket)
]

{ #category : #private }
RFBSocket class >> addressAndPortFor: nameAndDisplay offset: portOffset [
	"Answer the host address and port number for the given host name and display number."

	| address |
	(address := NetNameResolver addressForName: nameAndDisplay first) isNil ifTrue: [^nil].
	^Array with: address with: nameAndDisplay second + portOffset
]

{ #category : #'instance creation' }
RFBSocket class >> connectedToServer [
	"Answer a RFBSocket (forward) connected to a remote server."

	^self connectedWithPrompt: 'Server address?' offset: ServerPortOffset
]

{ #category : #'instance creation' }
RFBSocket class >> connectedToViewer [
	"Answer a RFBSocket (reverse) connected to a remote viewer."

	^self connectedWithPrompt: 'Viewer address?' offset: ViewerPortOffset
]

{ #category : #private }
RFBSocket class >> connectedWithPrompt: promptString offset: portOffset [
	"Prompt for a server or viewer address.  Answer a RFBSocket connected to the address with the given portOffset."

	| nameDisplay addrPort socket |
	(nameDisplay := self requestHostAndDisplay: promptString) isNil ifTrue: [^nil].
	(addrPort := self addressAndPortFor: nameDisplay offset: portOffset) isNil ifTrue: [^nil].
	[socket := self newTCP connectTo: addrPort first port: addrPort second]
		on: Exception
		do:
			[self inform: 'Could not connect to ' , nameDisplay first , ':' , addrPort second printString.
			 ^nil].
	^socket
]

{ #category : #'class initialisation' }
RFBSocket class >> initialize [
	"RFBSocket initialize"

	ServerPortOffset := 5900.
	ViewerPortOffset := 5500.
	LastServerAddress := 'hostName:displayNumber'.
	SendTimeout := 60.
	MaximumTransmissionUnit := 1450.	"Conservative: min MTU for PPP with NAT."
	RFBSocketInstances := IdentitySet new.
	Smalltalk
		addToStartUpList: self;
		addToShutDownList: self
]

{ #category : #'instance creation' }
RFBSocket class >> new [
	"Answer a new, unconnected, undifferentiated socket."

	^RFBSocketInstances add: super new
]

{ #category : #'instance creation' }
RFBSocket class >> newTCP [
	"Answer a new, unconnected TCP socket."

	^RFBSocketInstances add: super newTCP
]

{ #category : #private }
RFBSocket class >> requestHostAndDisplay: promptString [
	"Request and parse an address in the form 'hostname' or 'hostname:<dpy>'.  Answer an array containing the host name and display number, or nil if there was a problem."
	"RFBSocket requestHostAndDisplay: 'test me?'"

	| display hostName hostAndDisplay |
	(hostAndDisplay := UIManager default request: promptString initialAnswer: LastServerAddress) isEmptyOrNil ifTrue: [^nil].
	hostAndDisplay := hostAndDisplay findTokens: $:.
	(hostAndDisplay size < 1 or: [hostAndDisplay size > 2])
		ifTrue:
			[self inform: 'I could not parse that address.  Use: hostname[:<displayNumber>]'.
			 ^nil].
	hostName := hostAndDisplay first withBlanksTrimmed.
	display := hostAndDisplay size == 2
		ifTrue: [hostAndDisplay second withBlanksTrimmed asInteger]
		ifFalse: [0].
	display isNil
		ifTrue:
			[self inform: 'I could not parse the display number.'.
			 ^nil].
	LastServerAddress := hostName , ':' , display printString.
	^Array with: hostName with: display
]

{ #category : #constants }
RFBSocket class >> serverPortOffset [
	"Answer the offset (from the display number) of the port on which servers listen for forward connections."

	^ServerPortOffset
]

{ #category : #snapshot }
RFBSocket class >> shutDown: quitting [
	"We're about to snapshot and quit: shut down any open connections."

	RFBSocketInstances := RFBSocketInstances select: [:sock | sock isValid and: [sock isConnected]].
	(quitting and: [RFBSocketInstances notEmpty])
		ifTrue: [RFBSocketInstances do: [:sock | sock close]]
]

{ #category : #snapshot }
RFBSocket class >> startUp: resuming [
	"We're coming back from snapshot and quit.  Close any connections that were left open in the snapshot."

	(resuming and: [RFBSocketInstances notEmpty])
		ifTrue: [RFBSocketInstances do: [:sock | sock close]]
]

{ #category : #constants }
RFBSocket class >> viewerPortOffset [
	"Answer the offset (from the display number) of the port on which viewers listen for reverse connections."

	^ViewerPortOffset
]

{ #category : #connecting }
RFBSocket >> accept [
	"Accept a connection from the receiver socket.
	Return a new socket that is connected to the client"
	^(RFBSocket acceptFrom: self)
"
		setOption: 'TCP:=NODELAY' value: 1;
		yourself
"
]

{ #category : #closing }
RFBSocket >> close [
	"Close the receiver's connection and remove it from the list of active sockets."

	super close.
	RFBSocketInstances remove: self ifAbsent: [].
	semaphore isNil ifFalse: [semaphore signal].
	readSemaphore isNil ifFalse: [readSemaphore signal].
	writeSemaphore isNil ifFalse: [writeSemaphore signal].
]

{ #category : #closing }
RFBSocket >> closeAndDestroy [
	"Close and destroy the receiver."

	self close; closeAndDestroy: 1.
	RFBSocketInstances remove: self ifAbsent: []
]

{ #category : #connecting }
RFBSocket >> connectTo: host port: port [
	"Connect the receiver to the given host and port number."

	hostName := host.
	^super connectTo: hostName port: port
]

{ #category : #closing }
RFBSocket >> destroy [
	"Destroy all external resources associated with the receiver."

	super destroy.
	RFBSocketInstances remove: self ifAbsent: []
]

{ #category : #constants }
RFBSocket >> maximumTransmissionUnit [
	"A real network implementation would know the precise value.  In the meantime answer a conservative upper limit."

	^MaximumTransmissionUnit
]

{ #category : #accessing }
RFBSocket >> name [
	"Answer the name of the peer."

	^self isConnected
		ifTrue: [hostName isNil ifTrue: [NetNameResolver stringFromAddress: self remoteAddress] ifFalse: [hostName]]
		ifFalse: ['not connected']
]

{ #category : #accessing }
RFBSocket >> name: aString [
	"Set the name of the peer."

	hostName := aString
]

{ #category : #primitives }
RFBSocket >> primSocketCloseConnection: socketID [
	"Close the connection on the given port. The remote end is informed that this end has closed and will do no further sends. This is an asynchronous call; query the socket status to discover if and when the connection is actually closed.  Overriden to avoid primitive fail error in superclass."

	<primitive: 'primitiveSocketCloseConnection' module: 'SocketPlugin'>
]

{ #category : #primitives }
RFBSocket >> primSocketReceiveDataAvailable: socketID [
	"Return true if data may be available for reading from the current socket.  Overridden to avoid primitive failure when the socket is closed asynchronously (or left open across snapshot and quit)."

	<primitive: 'primitiveSocketReceiveDataAvailable' module: 'SocketPlugin'>
	^false
]

{ #category : #receiving }
RFBSocket >> receive: aMessage [
	"Receive aMessage.  The message type has already been read and stored in aMessage (which is an instance of the corresponding message class).  Fill the remainder of aMessage from incoming bytes, starting with the byte after the message type."

	^self receiveData: aMessage startingAt: 2
]

{ #category : #receiving }
RFBSocket >> receiveData: stringOrByteArray [
	"Receive an incoming message completely."

	^self receiveData: stringOrByteArray startingAt: 1
]

{ #category : #receiving }
RFBSocket >> receiveData: stringOrByteArray startingAt: initialIndex [
	"Receive an incoming message."

	| index count |
	index := initialIndex.
	[index <= stringOrByteArray size]
		whileTrue:
			[count := self receiveDataInto: stringOrByteArray startingAt: index.
			 index := index + count].
	^stringOrByteArray
]

{ #category : #receiving }
RFBSocket >> receiveData: bytesOrWords startingAt: index count: count [
	"This is a bug fix implementation.  (The core Socket class does not implement any methods to receive a bounded amount of data.)  Receive count bytes of bytesOrWords starting at index, answer the number of bytes read."

	| currIndex lastIndex nRead |
	currIndex := index.
	lastIndex := currIndex + count.
	[currIndex < lastIndex]
		whileTrue:
			[self waitForData.
			 nRead := self
						primSocket: socketHandle
						receiveDataInto: bytesOrWords
						startingAt: currIndex
						count: lastIndex - currIndex.
			 currIndex := currIndex + nRead].
	^count
]

{ #category : #receiving }
RFBSocket >> receiveNew: eventClass [
	"Answer a new RFBMessage initialised from received data."

	^self receiveData: eventClass new startingAt: 2
]

{ #category : #receiving }
RFBSocket >> receiveString [
	"Answer a String constructed by reading a 4-byte length followed by length characters."

	| length |
	length := (self receiveData: (RFBMessage new: 4)) unsignedLongAt: 1.
	^self receiveData: (String new: length)
]

{ #category : #running }
RFBSocket >> runSafely: aBlock [
	"Repeatedly execute aBlock until the connection failes or an error is signaled.  If debugging is enabled in RFBServer, open a debugger on the error context for the purposes of developer enlightenment."

	[[[self isValid and: [self isConnected]] whileTrue: aBlock]
			on: Error
			do: [:ex |
				Transcript cr; show: 'RFB: caught ' , ex printString.
				RFBServer current enableDebugging
					ifTrue:
						[Transcript endEntry.
						 self halt]]]
		ensure: [self closeAndDestroy]
]

{ #category : #sending }
RFBSocket >> sendData: bytesOrWords [
	"This is a bug-fix implementation only.  Socket>>sendData: sends the buffer #size, rather than #byteSize, which is somewhat unfortunate when the buffer happens to be a WordArray."

	^self sendData: bytesOrWords startingAt: 1 count: bytesOrWords byteSize
]

{ #category : #sending }
RFBSocket >> sendData: bytesOrWords startingAt: index count: count [
	"This is a bug-fix implementation only.  Socket>>sendData: asks the buffer for its #size, rather than its #byteSize, which is somewhat unfortunate when the buffer happens to be a WordArray."

	| currIndex lastIndex sent waitForSendDone |
	currIndex := index.
	lastIndex := currIndex + count.
	[currIndex < lastIndex]
		whileTrue:
			[
			 waitForSendDone := (self waitForSendDoneFor: self sendTimeout).
			 waitForSendDone ifNil: [ ConnectionTimedOut signal: 'send data issue; data not sent' ].
			 waitForSendDone ifFalse: [ConnectionTimedOut signal: 'send data timeout; data not sent'].
			 sent := self primSocket: socketHandle
				sendData: bytesOrWords
				startIndex: currIndex
				count: (lastIndex - currIndex min: self maximumTransmissionUnit).
			 currIndex := currIndex + sent].

	^count
]

{ #category : #sending }
RFBSocket >> sendStream: aStream [
	"Write the entire contents of aStream on the receiver's connection."

	^self sendData: aStream originalContents count: aStream size
]

{ #category : #constants }
RFBSocket >> sendTimeout [
	"Answer the send timeout for writes on this socket."

	^SendTimeout
]

{ #category : #receiving }
RFBSocket >> waitForDataForMilliseconds: timeout [
	"Wait for the given nr of milliseconds for data to arrive."

	| deadline |
	deadline := Time millisecondClockValue + timeout.
	[Time millisecondClockValue < deadline]
		whileTrue: [
			(self primSocketReceiveDataAvailable: socketHandle) ifTrue: [^true].
			self isConnected ifFalse: [^false].
			self readSemaphore waitTimeoutMSecs: (deadline - Time millisecondClockValue)].
	^false
]

{ #category : #sending }
RFBSocket >> waitForSendDoneFor: timeout [
	"This is a (dual) bug-fix implementation only.  Broken VMs (like the Windoze one) confuse the read and write Semaphores (bug #1), and the new Socket implementation fails utterly to deal properly with the situation (bug #2)."

	| remainingTime drainDelay sendDone |
	remainingTime := timeout * 1000.
	drainDelay := Delay forMilliseconds: 5.	"Time to send 4 MTUs on a 10Mbps network."
	"Avoid waiting on the writeSemaphore, otherwise the server read loop goes catatonic."
	[self isConnected
			and: [(sendDone := self primSocketSendDone: socketHandle) not
			and: [remainingTime > 0]]]
		whileTrue:
			[drainDelay wait.
			 remainingTime := remainingTime - 6].
	^sendDone

]
