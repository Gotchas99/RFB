"
I am a completely bogus ZLib write stream.

You write uncompressed data to me with #nextPutAll: and retrieve the 'compressed' data with #contents (followed by position: 0, if appropriate, to empty my output buffer).

If you expect a pause in your data stream then you should send me #synchronise.  This will ensure that *all* data is flushed through to the *final* consumer of the uncompressed data at the other end of the (e.g.) network connection.

You can therefore repeat the cycle:

	oneOfMe
		nextPutAll: yourUncompressedData;
		synchronise;
		contents;
		position: 0.

as many times as you like, each time sending the answer to #contents to a (possibly remote) consumer who is piping their incoming 'compressed' data through a zlib inflation process.  This consumer is *guaranteed* to receive all yourUncompressedData at each point you send #synchronise.

I am completely bogus because I don't compress anything at all.  The 'compressed' data is larger than the uncompressed data, but it *does* conform rigorously to the format described in RFC 1951.  You can therefore send the 'compressed' data I produce to any conforming implementation of zlib and expect to retrieve the original data, with inflation 'latencies' managed correctly as per the synchronisation behaviour described above.
"
Class {
	#name : #RFBZLibFakeStream,
	#superclass : #WriteStream,
	#category : #'RFB-Communication'
}

{ #category : #'READ ME' }
RFBZLibFakeStream class >> readMe [
	"The following demontrates how this stream is used.  'Compressed' data generated from this method can be piped directly into the C implementation of zlib and will correctly reconstruct the origin input data."

	"RFBZLibFakeStream readMe"

	| zlib a b |
	zlib := RFBZLibFakeStream on: (ByteArray new: 100).

	zlib nextPutAll: 'Hello' asByteArray.
	zlib nextPutAll: '...' asByteArray.
	"signal a possible pause in the compressed data stream"
	zlib synchronise.		"at this point the consumer will be guaranteed to receive all preceding data"
	a := zlib contents.		"output data to send down the wire"
	zlib position: 0.			"empty the output buffer"

	"send some more data (maybe after a pause)..."
	zlib nextPutAll: 'Goodbye!' asByteArray.
	zlib synchronise.		"as above"
	b := zlib contents.		"idem"

	^Array with: a with: b
]

{ #category : #accessing }
RFBZLibFakeStream >> commit [
	"Write an empty, non-final, non-compressed block onto the receiver."
	"Note:  This kind of empty block is a marker informing zlib of a potential 'pause' in the incoming compressed data stream.  It is detected by zlib's 'inflate:=sync()' function which will subsequently ensure that all previously-read compressed data is fully inflated and made available to the final consumer.  It shows up in the compressed data stream as a sequence of five bytes: 0 0 0 255 255."

	self nextPutBlock: (ByteArray new)
]

{ #category : #accessing }
RFBZLibFakeStream >> nextPut16: anInteger [
	"Encode a 16-bit integer, LSB first."

	self
		nextPut: (anInteger bitAnd: 255);
		nextPut: (anInteger bitShift: -8)
]

{ #category : #accessing }
RFBZLibFakeStream >> nextPutAll: bytes [
	"Encode bytes onto the receiver as a sequence of one or more non-compressed blocks."

	| in |
	in := ReadStream on: bytes.
	[in position < in size]
		whileTrue:
			[self nextPutBlock: (in next: (in size min: 65535))]
]

{ #category : #accessing }
RFBZLibFakeStream >> nextPutBlock: bytes [
	"Write a non-compressed block containing bytes onto the receiver."
	"Assumes: bytes size < 65536."
	"NOTE:  If bytes is empty then an empty block is written on the receiver (see #synchronise)."

	| len |
	len := bytes size.
	self
		nextPut: 0;						"BFINAL, BTYPE: non-final, non-compressed; align(8)"
		nextPut16: len;					"LEN"
		nextPut16: (len bitXor: 16rFFFF).	"NLEN"
	super nextPutAll: bytes				"literal data"
]

{ #category : #'initialise-release' }
RFBZLibFakeStream >> on: aCollection [
	"Initialise the receiver and prepend a feasible 2-byte zlib stream header."

	super on: aCollection.
	self
		nextPut: 120;		"32K dictionary window (irrelevant since we only send non-compressed blocks)"
		nextPut: 1			"no presets, check sum (irrelevant since this stream *never* terminates)"
]

{ #category : #accessing }
RFBZLibFakeStream >> synchronisedContents [
	"Flush all pending data, write an inflation synchronisation marker onto the encodedStream, and answer the contents of the encodedStream.  Reset the encodedStream to empty in the process."

	| compressedData |
	self commit.
	compressedData := self contents.
	self position: 0.
	^compressedData
]
