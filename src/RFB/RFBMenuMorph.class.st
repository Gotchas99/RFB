"
I am a MenuMorph that knows how to retrieve update information from blocks in addition to the usual ""target + selector"" mechanism.
"
Class {
	#name : #RFBMenuMorph,
	#superclass : #MenuMorph,
	#category : #'RFB-Server'
}

{ #category : #construction }
RFBMenuMorph >> add: aBlockOrString action: selector help: helpString [
	"Add a new menu item with the given action selector and balloon helpString.  If aBlockOrString is a string then the item's label is fixed.  If aBlockOrString is a Block then the label will update from the result of invoking the block."

	aBlockOrString isBlock
		ifTrue:
			[(self addUpdating: nil action: selector) lastItem
				wordingProvider: aBlockOrString
				wordingSelector: #value]
		ifFalse:
			[super add: aBlockOrString action: selector].
	self balloonTextForLastItem: helpString
]

{ #category : #construction }
RFBMenuMorph >> add: label get: getBlock set: setBlock help: helpString [
	"Add a new updating item with the given label and balloon helpString.  The getBlock provides a Boolean with which the <yes>/<no> prefix for the label is retrieved.  If the item is selected then setBlock is invoked."

	(self addUpdating: #getLabel: target: setBlock selector: #value argumentList: EmptyArray)
		wordingProvider: self
		wordingSelector: #getLabel:;
		wordingArgument: (Array with: getBlock with: label).
	self balloonTextForLastItem: helpString
]

{ #category : #construction }
RFBMenuMorph >> addUpdating: wordingSelector target: target selector: aSymbol argumentList: argList [ 
	"Append a menu item with the given label. If the item is selected, it will send the given selector to the target object with the given arguments. If the selector takes one more argument than the number of arguments in the given list, then the triggering event is supplied as as the last argument.  In this variant, the wording of the menu item is obtained by sending the wordingSelector to the target,  Answer the item added."
	| item |
	item := UpdatingMenuItemMorph new
		target: target;
		selector: aSymbol;
		wordingProvider: target
			wordingSelector: wordingSelector;
		arguments: argList asArray.
	self addMorphBack: item.
	^ item
]

{ #category : #private }
RFBMenuMorph >> getLabel: blockAndLabelArray [
	"The blockAndLabelArray contains a Block and a label String.  Answer a new label created by invoking the block, converting its (Boolean) result into a <yes>/<no> prefix, and prepending it to the label."

	| block label prefix |
	block := blockAndLabelArray first.
	label := blockAndLabelArray second.
	prefix := block value ifTrue: ['<yes>'] ifFalse: ['<no>'].
	^prefix , label
]
