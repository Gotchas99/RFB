Extension { #name : #EventSensorConstants }

{ #category : #'*rfb' }
EventSensorConstants class >> keysDo: aBlock [
	"Answer the names of my class variables.  Avoids a notifier when the Encoder is finding a list of alternatives for a misspelled or undeclared class variable."

	^classPool keysDo: aBlock
]
