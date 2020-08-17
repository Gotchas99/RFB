"
I am a kind of Bag that interprets its contents as a map of pixelValue -> pixelCount.
"
Class {
	#name : #RFBPixelPopulation,
	#superclass : #Bag,
	#category : #'RFB-Server'
}

{ #category : #accessing }
RFBPixelPopulation >> dominantPixel [
	"Answer the dominant pixel in the population represented by the receiver.  Since the receiver is a kind of Bag, this is just the key associated with the largest value.  Avoids the (very) expensive equivalent: aBag sortedContents first key."

	| max dominant |
	max := 0.
	contents associationsDo: [:assoc |
		assoc value > max
			ifTrue:
				[max := (dominant := assoc) value]].
	^dominant isNil ifTrue: [0] ifFalse: [dominant key]
]
