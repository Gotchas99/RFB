"
I am a Form that record damaged areas relative to another Form.  After instantiating me with ""on: originalForm"" you can ask me at any time ""isDamaged"" or ""isDamagedIn: boundingRectangle"" and I will answer true or false, depending on whether originalForm has changed in the given bounds since the last time you asked.
"
Class {
	#name : #RFBDamageRecorder,
	#superclass : #RFBForm,
	#instVars : [
		'targetForm'
	],
	#classVars : [
		'DamageHeight',
		'DamageWidth'
	],
	#category : #'RFB-Server'
}

{ #category : #'instance creation' }
RFBDamageRecorder class >> forDisplay [
	"Answer a new DamageRecorder for the current Display object."

	^self on: Display
]

{ #category : #'class initialisation' }
RFBDamageRecorder class >> initialize [
	"RFBDamageFilter initialize"

	DamageWidth := 64.
	DamageHeight := 64.
]

{ #category : #'instance creation' }
RFBDamageRecorder class >> on: aForm [
	"Answer a new DamageRecorder for aForm."

	^(self extent: aForm extent depth: aForm depth)
		setTargetForm: aForm
]

{ #category : #testing }
RFBDamageRecorder >> isDamaged [
	"Answer whether any damage is present in the entire Form covered by the receiver."

	^self isDamagedIn: self boundingBox
]

{ #category : #testing }
RFBDamageRecorder >> isDamagedIn: bounds [
	"Answer whether any damage exists in the receiver's Form within bounds."

	| damageFlag |
	(targetForm extent = self extent and: [targetForm bits size == bits size])
		ifFalse:
			[self setExtent: targetForm extent depth: targetForm depth].
	(damageFlag := self pvtChangedFrom: targetForm in: bounds)
		ifTrue: [self updateDamageIn: bounds].
	^damageFlag





"
| c f g r |
c := OrderedCollection new.
#(1 2 4 8 16 32) do: [:d |
	f := RFBDamageRecorder on: (g := Form extent: 100@100 depth: d).
	0 to: 90 by: 10 do: [:o |
		r := o@o extent: 10@10.
		g fill: r fillColor: Color red.
		c add: d -> (r ->
			((f isDamagedIn: (49@49 corner: 51@51))
				-> (f isDamagedIn: (49@49 corner: 51@51))))]].
^String streamContents: [:s | c do: [:e | e printOn: s.  s cr]]
"
]

{ #category : #'initialise-release' }
RFBDamageRecorder >> release [
	"Drop references to anything potentially large."

	targetForm := nil.
	bits := nil
]

{ #category : #private }
RFBDamageRecorder >> setTargetForm: aForm [
	"Set the Form for which the receiver monitors damage."

	(BitBlt toForm: self)
        sourceForm: (targetForm := aForm);
        combinationRule: Form over;
        destRect: self boundingBox;
        copyBits.
]

{ #category : #private }
RFBDamageRecorder >> updateDamageIn: bounds [
	"Update the receiver's cached copy of the targetForm with the given bounds, eliminating any damage that might have been there."

	(BitBlt toForm: self)
		sourceForm: targetForm;
		sourceOrigin: bounds origin;
		combinationRule: Form over;
		destRect: bounds;
		copyBits
]
