"
I am a (somewhat trimmed-down) 3DES encryption algorithm intended only for use in VNC password authentication.  My reason for existing is to avoid an otherwise very nasty dependency on the DESPlugin (which would provided suitable functionality, but which is not normally bundled with Squeak VMs).

I'm not particularly fast (you wouldn't want to ask me to encrypt a megabyte of data) but, since I'm only here to encrypt 16-byte authentication challenges during the connection handshake, who cares?
"
Class {
	#name : #RFB3DES,
	#superclass : #Object,
	#instVars : [
		'knl',
		'knr',
		'kn3'
	],
	#classVars : [
		'BigByte',
		'ByteBit',
		'PC1',
		'PC2',
		'SP1',
		'SP2',
		'SP3',
		'SP4',
		'SP5',
		'SP6',
		'SP7',
		'SP8',
		'TotRot'
	],
	#category : #'RFB-Crypto-3DES'
}

{ #category : #examples }
RFB3DES class >> example1 [
	"Encrypts the password 'squeak' and verifies that the result is as expected.
	Note: if you use 'squeak' as your real password then: (1) you are crazy to think such an obvious word is secure; and: (2) anybody who gains access to your image for more than 10 seconds will be in a position to look at the stored (encrypted) VNC password, compare it with the expected result below, and know instantly that your password is 'squeak'.  You have been warned."
	"RFB3DES example1"

	| data des |
	data := (ByteArray new: 8) replaceFrom: 1 to: 6 with: 'squeak'.
	des := RFB3DES new encryptionKey: #(23 82 107 6 35 78 88 7) asByteArray.
	des des: data to: data.
	data = #(252 108 241 14 193 201 46 62) asByteArray
		ifFalse: [self error: 'something rotten in the works'].
	^data
]

{ #category : #'class initialisation' }
RFB3DES class >> initialize [
	"Initialise the various magic tables used for DES encryption."
	"RFB3DES initialize"

	BigByte := #(
		16r800000	16r400000	16r200000	16r100000
		16r080000	16r040000	16r020000	16r010000
		16r008000	16r004000	16r002000	16r001000
		16r000800	16r000400 	16r000200 	16r000100
		16r000080	16r000040	16r000020	16r000010
		16r000008	16r000004	16r000002	16r000001).
	ByteBit := #(1 2 4 8 16 32 64 128).
	"Key schedule [ANSI X3.92-1981]."
	PC1 := #(
		56 48  40 32 24 16  8		 0 57 49 41 33 25 17
		 9   1 58 50 42 34 26		18 10  2 59 51 43 35
		62 54  46 38 30 22 14		 6 61 53 45 37 29 21
		13   5 60 52 44 36 28		20 12  4 27 19 11  3).
	PC2 := #(
	 	13 16 10 23  0  4  2 27 14  5 20  9
		22 18 11  3 25  7 15  6 26 19 12  1
		40 51 30 36 46 54 29 39 50 44 32 47
		43 48 38 55 33 52 45 41 49 35 28 31).
	TotRot := #(1 2 4 6 8 10 12 14 15 17 19 21 23 25 27 28).
	SP1 := #(
		16r01010400 16r00000000 16r00010000 16r01010404
		16r01010004 16r00010404 16r00000004 16r00010000
		16r00000400 16r01010400 16r01010404 16r00000400
		16r01000404 16r01010004 16r01000000 16r00000004
		16r00000404 16r01000400 16r01000400 16r00010400
		16r00010400 16r01010000 16r01010000 16r01000404
		16r00010004 16r01000004 16r01000004 16r00010004
		16r00000000 16r00000404 16r00010404 16r01000000
		16r00010000 16r01010404 16r00000004 16r01010000
		16r01010400 16r01000000 16r01000000 16r00000400
		16r01010004 16r00010000 16r00010400 16r01000004
		16r00000400 16r00000004 16r01000404 16r00010404
		16r01010404 16r00010004 16r01010000 16r01000404
		16r01000004 16r00000404 16r00010404 16r01010400
		16r00000404 16r01000400 16r01000400 16r00000000
		16r00010004 16r00010400 16r00000000 16r01010004).
	SP2 := #(
		16r80108020 16r80008000 16r00008000 16r00108020
		16r00100000 16r00000020 16r80100020 16r80008020
		16r80000020 16r80108020 16r80108000 16r80000000
		16r80008000 16r00100000 16r00000020 16r80100020
		16r00108000 16r00100020 16r80008020 16r00000000
		16r80000000 16r00008000 16r00108020 16r80100000
		16r00100020 16r80000020 16r00000000 16r00108000
		16r00008020 16r80108000 16r80100000 16r00008020
		16r00000000 16r00108020 16r80100020 16r00100000
		16r80008020 16r80100000 16r80108000 16r00008000
		16r80100000 16r80008000 16r00000020 16r80108020
		16r00108020 16r00000020 16r00008000 16r80000000
		16r00008020 16r80108000 16r00100000 16r80000020
		16r00100020 16r80008020 16r80000020 16r00100020
		16r00108000 16r00000000 16r80008000 16r00008020
		16r80000000 16r80100020 16r80108020 16r00108000).
	SP3 := #(
		16r00000208 16r08020200 16r00000000 16r08020008
		16r08000200 16r00000000 16r00020208 16r08000200
		16r00020008 16r08000008 16r08000008 16r00020000
		16r08020208 16r00020008 16r08020000 16r00000208
		16r08000000 16r00000008 16r08020200 16r00000200
		16r00020200 16r08020000 16r08020008 16r00020208
		16r08000208 16r00020200 16r00020000 16r08000208
		16r00000008 16r08020208 16r00000200 16r08000000
		16r08020200 16r08000000 16r00020008 16r00000208
		16r00020000 16r08020200 16r08000200 16r00000000
		16r00000200 16r00020008 16r08020208 16r08000200
		16r08000008 16r00000200 16r00000000 16r08020008
		16r08000208 16r00020000 16r08000000 16r08020208
		16r00000008 16r00020208 16r00020200 16r08000008
		16r08020000 16r08000208 16r00000208 16r08020000
		16r00020208 16r00000008 16r08020008 16r00020200).
	SP4 := #(
		16r00802001 16r00002081 16r00002081 16r00000080
		16r00802080 16r00800081 16r00800001 16r00002001
		16r00000000 16r00802000 16r00802000 16r00802081
		16r00000081 16r00000000 16r00800080 16r00800001
		16r00000001 16r00002000 16r00800000 16r00802001
		16r00000080 16r00800000 16r00002001 16r00002080
		16r00800081 16r00000001 16r00002080 16r00800080
		16r00002000 16r00802080 16r00802081 16r00000081
		16r00800080 16r00800001 16r00802000 16r00802081
		16r00000081 16r00000000 16r00000000 16r00802000
		16r00002080 16r00800080 16r00800081 16r00000001
		16r00802001 16r00002081 16r00002081 16r00000080
		16r00802081 16r00000081 16r00000001 16r00002000
		16r00800001 16r00002001 16r00802080 16r00800081
		16r00002001 16r00002080 16r00800000 16r00802001
		16r00000080 16r00800000 16r00002000 16r00802080).
	SP5 := #(
		16r00000100 16r02080100 16r02080000 16r42000100
		16r00080000 16r00000100 16r40000000 16r02080000
		16r40080100 16r00080000 16r02000100 16r40080100
		16r42000100 16r42080000 16r00080100 16r40000000
		16r02000000 16r40080000 16r40080000 16r00000000
		16r40000100 16r42080100 16r42080100 16r02000100
		16r42080000 16r40000100 16r00000000 16r42000000
		16r02080100 16r02000000 16r42000000 16r00080100
		16r00080000 16r42000100 16r00000100 16r02000000
		16r40000000 16r02080000 16r42000100 16r40080100
		16r02000100 16r40000000 16r42080000 16r02080100
		16r40080100 16r00000100 16r02000000 16r42080000
		16r42080100 16r00080100 16r42000000 16r42080100
		16r02080000 16r00000000 16r40080000 16r42000000
		16r00080100 16r02000100 16r40000100 16r00080000
		16r00000000 16r40080000 16r02080100 16r40000100).
	SP6 := #(
		16r20000010 16r20400000 16r00004000 16r20404010
		16r20400000 16r00000010 16r20404010 16r00400000
		16r20004000 16r00404010 16r00400000 16r20000010
		16r00400010 16r20004000 16r20000000 16r00004010
		16r00000000 16r00400010 16r20004010 16r00004000
		16r00404000 16r20004010 16r00000010 16r20400010
		16r20400010 16r00000000 16r00404010 16r20404000
		16r00004010 16r00404000 16r20404000 16r20000000
		16r20004000 16r00000010 16r20400010 16r00404000
		16r20404010 16r00400000 16r00004010 16r20000010
		16r00400000 16r20004000 16r20000000 16r00004010
		16r20000010 16r20404010 16r00404000 16r20400000
		16r00404010 16r20404000 16r00000000 16r20400010
		16r00000010 16r00004000 16r20400000 16r00404010
		16r00004000 16r00400010 16r20004010 16r00000000
		16r20404000 16r20000000 16r00400010 16r20004010).
	SP7 := #(
		16r00200000 16r04200002 16r04000802 16r00000000
		16r00000800 16r04000802 16r00200802 16r04200800
		16r04200802 16r00200000 16r00000000 16r04000002
		16r00000002 16r04000000 16r04200002 16r00000802
		16r04000800 16r00200802 16r00200002 16r04000800
		16r04000002 16r04200000 16r04200800 16r00200002
		16r04200000 16r00000800 16r00000802 16r04200802
		16r00200800 16r00000002 16r04000000 16r00200800
		16r04000000 16r00200800 16r00200000 16r04000802
		16r04000802 16r04200002 16r04200002 16r00000002
		16r00200002 16r04000000 16r04000800 16r00200000
		16r04200800 16r00000802 16r00200802 16r04200800
		16r00000802 16r04000002 16r04200802 16r04200000
		16r00200800 16r00000000 16r00000002 16r04200802
		16r00000000 16r00200802 16r04200000 16r00000800
		16r04000002 16r04000800 16r00000800 16r00200002).
	SP8 := #(
		16r10001040 16r00001000 16r00040000 16r10041040
		16r10000000 16r10001040 16r00000040 16r10000000
		16r00040040 16r10040000 16r10041040 16r00041000
		16r10041000 16r00041040 16r00001000 16r00000040
		16r10040000 16r10000040 16r10001000 16r00001040
		16r00041000 16r00040040 16r10040040 16r10041000
		16r00001040 16r00000000 16r00000000 16r10040040
		16r10000040 16r10001000 16r00041040 16r00040000
		16r00041040 16r00040000 16r10041000 16r00001000
		16r00000040 16r10040040 16r00001000 16r00041040
		16r10001000 16r00000040 16r10000040 16r10040000
		16r10040040 16r10000000 16r00040000 16r10001040
		16r00000000 16r10041040 16r00040040 16r10000040
		16r10040000 16r10001000 16r10001040 16r00000000
		16r10041040 16r00041000 16r00041000 16r00001040
		16r00001040 16r00040040 16r10000000 16r10041000).

]

{ #category : #'instance creation' }
RFB3DES class >> new [
	"Create a new 3des algorithm with a null (all zeros) key."

	^super new initialise
]

{ #category : #private }
RFB3DES >> cookey: raw [
	"Answer a cooked version of the given raw key."

	| raw1 dough cook raw0 cooked |
	raw1 := 1.
	dough := WordArray new: 32.
	cook := 1.
	16 timesRepeat:
		[raw0 := raw1.
		 raw1 := raw1 + 1.
		 cooked :=				(((raw at: raw0) bitAnd: 16r00FC0000) bitShift: 6).
		 cooked := cooked bitOr:	(((raw at: raw0) bitAnd: 16r00000FC0) bitShift: 10).
		 cooked := cooked bitOr:	(((raw at: raw1) bitAnd: 16r00FC0000) bitShift: -10).
		 cooked := cooked bitOr:	(((raw at: raw1) bitAnd: 16r00000FC0) bitShift: -6).
		 dough at: cook put: cooked.
		 cook := cook + 1.
		 cooked :=				(((raw at: raw0) bitAnd: 16r0003F000) bitShift: 12).
		 cooked := cooked bitOr:	(((raw at: raw0) bitAnd: 16r0000003F) bitShift: 16).
		 cooked := cooked bitOr:	(((raw at: raw1) bitAnd: 16r0003F000) bitShift: -4).
		 cooked := cooked bitOr:	(((raw at: raw1) bitAnd: 16r0000003F)).
		 dough at: cook put: cooked.
		 cook := cook + 1.
		 raw1 := raw1 + 1].
	self useKey: dough
]

{ #category : #accessing }
RFB3DES >> decryptionKey: newKey [
	"Set the internal DES key to newKey, in a form appropriate for data decryption."

	self desKey: newKey mode: #DE1
]

{ #category : #private }
RFB3DES >> des: block key: keyArray [
	"Perform DES en/decryption on the given data block using the keys stored in keyArray.  Update the data block in-place with the result."

	| leftt right work keys fval |
	leftt := block at: 1.
	right := block at: 2.
	work := ((leftt bitShift: -4) bitXor: right) bitAnd: 16r0F0F0F0F.
	right := right bitXor: work.
	leftt := leftt bitXor: (work bitShift: 4).
	work := ((leftt bitShift: -16) bitXor: right) bitAnd: 16r0000FFFF.
	right := right bitXor: work.
	leftt := leftt bitXor: (work bitShift: 16).
	work := ((right bitShift: -2) bitXor: leftt) bitAnd: 16r33333333.
	leftt := leftt bitXor: work.
	right := right bitXor: (work bitShift: 2).
	work := ((right bitShift: -8) bitXor: leftt) bitAnd: 16r00FF00FF.
	leftt := leftt bitXor: work.
	right := right bitXor: (work bitShift: 8).
	right := ((right bitShift: 1) bitOr: ((right bitShift: -31) bitAnd: 1)) bitAnd: 16rFFFFFFFF.
	work := (leftt bitXor: right) bitAnd: 16rAAAAAAAA.
	leftt := leftt bitXor: work.
	right := right bitXor: work.
	leftt := ((leftt bitShift: 1) bitOr: ((leftt bitShift: -31) bitAnd: 1)) bitAnd: 16rFFFFFFFF.
	keys := ReadStream on: keyArray.
	8 timesRepeat:
		[work := ((right bitShift: 28) bitOr: (right bitShift: -4)) bitAnd: 16rFFFFFFFF.
		work := work bitXor: keys next.
		fval :=				(SP7 at: 1 + ((work)				bitAnd: 16r3F)).
		fval := fval bitOr:	(SP5 at: 1 + ((work bitShift: -8)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP3 at: 1 + ((work bitShift: -16)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP1 at: 1 + ((work bitShift: -24)	bitAnd: 16r3F)).
		work := right bitXor: keys next.
		fval := fval bitOr:	(SP8 at: 1 + ((work)				bitAnd: 16r3F)).
		fval := fval bitOr:	(SP6 at: 1 + ((work bitShift: -8)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP4 at: 1 + ((work bitShift: -16)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP2 at: 1 + ((work bitShift: -24)	bitAnd: 16r3F)).
		leftt := leftt bitXor: fval.
		work := ((leftt bitShift: 28) bitOr: (leftt bitShift: -4)) bitAnd: 16rFFFFFFFF.
		work := work bitXor: keys next.
		fval := 				(SP7 at: 1 + ((work)				bitAnd: 16r3F)).
		fval := fval bitOr:	(SP5 at: 1 + ((work bitShift:  -8)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP3 at: 1 + ((work bitShift: -16)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP1 at: 1 + ((work bitShift: -24)	bitAnd: 16r3F)).
		work := leftt bitXor: keys next.
		fval := fval bitOr:	(SP8 at: 1 + ((work)				bitAnd: 16r3F)).
		fval := fval bitOr:	(SP6 at: 1 + ((work bitShift:  -8)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP4 at: 1 + ((work bitShift: -16)	bitAnd: 16r3F)).
		fval := fval bitOr:	(SP2 at: 1 + ((work bitShift: -24)	bitAnd: 16r3F)).
		right := right bitXor: fval].
	right := ((right bitShift: 31) bitOr: (right bitShift: -1)) bitAnd: 16rFFFFFFFF.
	work := (leftt bitXor: right) bitAnd: 16rAAAAAAAA.
	leftt := leftt bitXor: work.
	right := right bitXor: work.
	leftt := ((leftt bitShift: 31) bitOr: (leftt bitShift: -1)) bitAnd: 16rFFFFFFFF.
	work := ((leftt bitShift: -8) bitXor: right) bitAnd: 16r00FF00FF.
	right := right bitXor: work.
	leftt := leftt bitXor: (work bitShift: 8).
	work := ((leftt bitShift: -2) bitXor: right) bitAnd: 16r33333333.
	right := right bitXor: work.
	leftt := leftt bitXor: (work bitShift: 2).
	work := ((right bitShift: -16) bitXor: leftt) bitAnd: 16r0000FFFF.
	leftt := leftt bitXor: work.
	right := right bitXor: (work bitShift: 16).
	work := ((right bitShift: -4) bitXor: leftt) bitAnd: 16r0F0F0F0F.
	leftt := leftt bitXor: work.
	right := right bitXor: (work bitShift: 4).
	block
		at: 1 put: right;
		at: 2 put: leftt
]

{ #category : #accessing }
RFB3DES >> des: inBlock to: outBlock [
	"Encrypt or decrypt 8 bytes of data from inBlock, storing the result in outBlock.
	Note: inBlock can == outBlock (which is useful for implicitly destroying plaintext data during encryption)."

	| workArray |
	workArray := WordArray new: 2.
	1 to: inBlock size - 7 by: 8 do:
		[:offset | self
			scrunch: inBlock to: workArray startingAt: offset;
			des: workArray key: knl;
			unscrunch: workArray to: outBlock startingAt: offset]
]

{ #category : #private }
RFB3DES >> desKey: newKey mode: mode [
	"Set the internal en/decryption key based a raw newKey.  If mode is #EN0 then the internally-set key will be suitable for encryption; if mode == #DE1 then it will be suitable for decryption."

	| pcr kn pc1m m n l |
	pcr := ByteArray new: 56.
	kn := WordArray new: 32.
	pc1m := (PC1 collect: [:i |
				m := i bitAnd: 7.
				((newKey at: 1 + (i bitShift: -3)) bitAnd: (ByteBit at: 1 + m)) ~~ 0
					ifTrue: [1]
					ifFalse: [0]])
		asByteArray.
	0 to: 15 do: [:i |
		m := (mode == #DE1
				ifTrue: [15 - i]
				ifFalse: [i])
			 bitShift: 1.
		n := m + 1.
		kn at: 1 + m put: (kn at: 1 + n put: 0).
		0 to: 27 do: [:j |
			l := j + (TotRot at: 1 + i).
			pcr at: 1 + j put: (pc1m at: 1 + (l < 28 ifTrue: [l] ifFalse: [l - 28]))].
		28 to: 55 do: [:j |
			l := j + (TotRot at: 1 + i).
			pcr at: 1 + j put: (pc1m at: 1 + (l < 56 ifTrue: [l] ifFalse: [l - 28]))].
		0 to: 23 do: [:j |
			0 ~~ (pcr at: 1 + (PC2 at: 1 + j))
				ifTrue: [kn at: 1 + m put: ((kn at: 1 + m) bitOr: (BigByte at: 1 + j))].
			0 ~~ (pcr at: 1 + (PC2 at: 1 + j + 24))
				ifTrue: [kn at: 1 + n put: ((kn at: 1 + n) bitOr: (BigByte at: 1 + j))]]].
	self cookey: kn
]

{ #category : #accessing }
RFB3DES >> encryptionKey: newKey [
	"Set the internal DES key to newKey, in a form appropriate for data encryption."

	self desKey: newKey mode: #EN0
]

{ #category : #'initialise-release' }
RFB3DES >> initialise [
	"Default conditions: ready to en/decrypt, but with useless (null) keys."

	knl := WordArray new: 32.
	knr := WordArray new: 32.
	kn3 := WordArray new: 32
]

{ #category : #private }
RFB3DES >> scrunch: bytes to: block [
	"Create a 2-word DES data block from 8 bytes of user data."

	^self scrunch: bytes to: block startingAt: 1
]

{ #category : #private }
RFB3DES >> scrunch: bytes to: block startingAt: index [
	"Create a 2-word DES data block from 8 bytes of user data."

	| tmp |
	tmp :=				((bytes at: index + 0) bitShift: 24).
	tmp := tmp bitOr:	((bytes at: index + 1) bitShift: 16).
	tmp := tmp bitOr:	((bytes at: index + 2) bitShift: 8).
	tmp := tmp bitOr:	((bytes at: index + 3)).
	block at: 1 put: tmp.
	tmp :=				((bytes at: index + 4) bitShift: 24).
	tmp := tmp bitOr:	((bytes at: index + 5) bitShift: 16).
	tmp := tmp bitOr:	((bytes at: index + 6) bitShift: 8).
	tmp := tmp bitOr:	((bytes at: index + 7)).
	block at: 2 put: tmp
]

{ #category : #private }
RFB3DES >> unscrunch: block to: bytes [
	"Create 8 bytes of user data from a 2-word DES data block."

	^self unscrunch: block to: bytes startingAt: 1
]

{ #category : #private }
RFB3DES >> unscrunch: block to: bytes startingAt: index [
	"Create 8 bytes of user data from a 2-word DES data block."

	| tmp |
	tmp := block at: 1.
	bytes at: index + 0 put: ((tmp bitShift: -24)	bitAnd: 16rFF).
	bytes at: index + 1 put: ((tmp bitShift: -16)	bitAnd: 16rFF).
	bytes at: index + 2 put: ((tmp bitShift: -8)	bitAnd: 16rFF).
	bytes at: index + 3 put: ((tmp 			)	bitAnd: 16rFF).
	tmp := block at: 2.
	bytes at: index + 4 put: ((tmp bitShift: -24)	bitAnd: 16rFF).
	bytes at: index + 5 put: ((tmp bitShift: -16)	bitAnd: 16rFF).
	bytes at: index + 6 put: ((tmp bitShift: -8)	bitAnd: 16rFF).
	bytes at: index + 7 put: ((tmp 			)	bitAnd: 16rFF)
]

{ #category : #accessing }
RFB3DES >> useKey: cookedKey [
	"Set the internal DES key to cookedKey.
	Note: you almost certainly don't want to invoke this method directly (use #de/encryptionKey: instead), but if you do then you are responsible for cooking your own raw key beforehand."

	knl := cookedKey
]
