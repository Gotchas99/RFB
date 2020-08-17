"
I am a kind of RFBDamageRecorder that understands damaged regions (consisting of Collections of Rectangles) instead of just a simple bounding Rectangle.  You instantiate me just like a RFBDamageRecorder, and can then ask me to ""getDamageInRegion: rectangleCollection"".  I will answer with another Collection containing only rectangles that really were modified since the last time you asked, and which have been trimmed as necessary to guarantee that no ""false"" damage is reported more than 32 pixels away from ""real"" damage.
"
Class {
	#name : #RFBDamageFilter,
	#superclass : #RFBDamageRecorder,
	#category : #'RFB-Server'
}

{ #category : #'damage containement' }
RFBDamageFilter >> coalesceDamage: rectangleList [
	"See the comment in #coalesceSortedDamage:."

	^self coalesceSortedDamage:
		(rectangleList asSortedCollection:
			[:r :s | r top == s top
					ifTrue: [r left < s left]
					ifFalse: [r top < s top]])
		asOrderedCollection
]

{ #category : #'damage containement' }
RFBDamageFilter >> coalesceSortedDamage: rectangleList [
	"Answer a SequenceableCollection of Rectangles, covering the same overall area as those in rectangleList, but in which adjacent rectangles have been coalesced into maximal y-x bands."

	| mergedHorizontalRects currentRect mergedVerticalRects |
	rectangleList isEmpty ifTrue: [^rectangleList].
	mergedHorizontalRects := OrderedCollection new.
	currentRect := rectangleList removeFirst.
	rectangleList do: [:rect |
		(rect top == currentRect top
		 and: [rect left == currentRect right
		 and: [rect bottom == currentRect bottom]])
			ifTrue:
				[currentRect := currentRect origin corner: rect corner]
			ifFalse:
				[mergedHorizontalRects addLast: currentRect.
				 currentRect := rect]].
	mergedHorizontalRects addLast: currentRect.
	mergedVerticalRects := OrderedCollection new.
	currentRect := mergedHorizontalRects removeFirst.
	mergedHorizontalRects do: [:rect |
		(rect left == currentRect left
		 and: [rect top == currentRect bottom
		 and: [rect right == currentRect right]])
			ifTrue:
				[currentRect := currentRect origin corner: rect corner]
			ifFalse:
				[mergedVerticalRects addLast: currentRect.
				 currentRect := rect]].
	mergedVerticalRects addLast: currentRect.
	^mergedVerticalRects
]

{ #category : #'damage containement' }
RFBDamageFilter >> getDamageInRect: bounds [
	"Answer a SequenceableCollection of Rectangles representing validated damage in the given bounds."

	| l r t b damagedRects h w subRect |
	l := bounds left.  r := bounds right.
	t := bounds top.  b := bounds bottom.
	damagedRects := OrderedCollection new.
	t to: b - 1 by: DamageHeight do: [:y |
		h := y + DamageHeight >= b ifTrue: [b - y] ifFalse: [DamageHeight].
		l to: r - 1 by: DamageWidth do: [:x |
			w := x + DamageWidth >= r ifTrue: [r - x] ifFalse: [DamageWidth].
			subRect := x@y corner: (x+w)@(y+h).
			(self isDamagedIn: subRect)
				ifTrue: [damagedRects addLast: subRect]]].
	^self coalesceSortedDamage: damagedRects
]

{ #category : #'damage containement' }
RFBDamageFilter >> getDamageInRegion: rectangleList [
	"Answer a SequenceableCollection of Rectangles covering validated damage within the regions covered by rectangleList."

	| damagedRects |
	damagedRects := OrderedCollection new.
	rectangleList do: [:rect | damagedRects addAll: (self getDamageInRect: rect)].
	^self coalesceDamage: damagedRects
]

{ #category : #'damage containement' }
RFBDamageFilter >> updateDamageInRegion: rectangleList [
	"Invalidate any damage in the region described by the rectangleList."

	rectangleList do: [:rect | self updateDamageIn: rect]
]
