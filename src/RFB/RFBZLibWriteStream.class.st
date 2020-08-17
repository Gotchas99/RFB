"
I am a ZLibWriteStream that understands how to synchronise my encodedData with a remote inflation process.  At each synchronisation point I write a marker to the encodedStream that will cause the inflation process in the remote client to ensure that all preceding data has been inflated and presented to the final consumer, avoiding any possibility for data to become 'stuck' in the inflation buffer.  This is most convenient when encoded data is being sent over a network and contains (for example) interactive screen updates.
"
Class {
	#name : #RFBZLibWriteStream,
	#superclass : #ZLibWriteStream,
	#category : #'RFB-Communication'
}

{ #category : #encoding }
RFBZLibWriteStream >> commit [
	"Flush all pending data onto the encodedStream."

	blockPosition < position ifTrue: [self deflateBlock; flushBlock: false].
	self sendSynchronisationBlock.
	encoder commit.
	blockStart := blockPosition.

]

{ #category : #'stored blocks' }
RFBZLibWriteStream >> sendSynchronisationBlock [
	"Send a synchronisation marker: a non-final, non-compressed, empty block.  When the block is encountered in an incoming compressed data stream, the inflation process guarantees that all data read before it will be inflated and presented to the client for consumption."

	encoder
		nextBits: 3 put: StoredBlock << 1 + 0;		"Non-final, non-compressed block header."
		flushBits;								"Align to byte boundary."
		nextBits: 16 put: 0;						"Length of non-compressed literal data to follow (zero bytes)."
		nextBits: 16 put: 16rFFFF;				"One's complement of data length."
		flushBits
]

{ #category : #encoding }
RFBZLibWriteStream >> synchronisedContents [
	"Flush all pending data, write an inflation synchronisation marker onto the encodedStream, and answer the contents of the encodedStream.  Reset the encodedStream to empty in the process."

	| compressedData |
	self commit.
	compressedData := self encodedStream contents.
	self encodedStream position: 0.
	^compressedData
]
