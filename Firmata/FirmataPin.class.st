"
I represent all that is known about an Arduino pin. I get created as a result of a capabilitiesrequest.
This should only be done once, presumably at initialisation of the Firmata protocol.

Be aware that Arduino pins are numbered from 0, not 1!!

    Instance Variables
	analogPinNumber:		the correspponding amalog pinnumber, filled by analogMappingRequest
	capabilities:		a list of FirmataPinCapabilities
	maxTimestamp:		timestamp of maxValue latch
	maxValue:		maximum value latch
	minTimestamp:		timestamp of min value latch
	minValue:		minimmum value
	mode:		the actul mode (from  pinStateRequest)
	state:		the pretended value (not measuered but reported)
	value:		the real value (analog or digital))


    Implementation Points
"
Class {
	#name : 'FirmataPin',
	#superclass : 'Object',
	#instVars : [
		'id',
		'value',
		'mode',
		'state',
		'maxValue',
		'maxTimestamp',
		'minValue',
		'minTimestamp',
		'capabilities',
		'analogPinNumber'
	],
	#category : 'Firmata',
	#package : 'Firmata'
}

{ #category : 'adding' }
FirmataPin >> addCapability: aCapability [
	"add a FirmataCapabiltiy to the lit in the pin"	
			
	capabilities add: aCapability
]

{ #category : 'accessing' }
FirmataPin >> analogPinNumber [
	^ analogPinNumber
]

{ #category : 'accessing' }
FirmataPin >> analogPinNumber: aNumber [

	analogPinNumber := aNumber
]

{ #category : 'accessing' }
FirmataPin >> capabilities [
	^capabilities
]

{ #category : 'testing' }
FirmataPin >> capableOfMode: aPinMode [
	" answer true if this pin has aPinMode among its capabilities "
	capabilities detect: [ :each | (each mode) = aPinMode ]
					ifNone: [ ^false ].
			^true
]

{ #category : 'accessing' }
FirmataPin >> id [ 	
	^id
]

{ #category : 'accessing' }
FirmataPin >> id: anArduinoPinNumber [
	id := anArduinoPinNumber 
]

{ #category : 'initialization' }
FirmataPin >> initialize [ 
	super initialize.
	value := 0.
	capabilities := OrderedCollection new.
]

{ #category : 'accessing' }
FirmataPin >> mode [
	^ mode
]

{ #category : 'accessing' }
FirmataPin >> mode: anObject [
	mode := anObject
]

{ #category : 'accessing' }
FirmataPin >> pinValue [
	^ value
]

{ #category : 'as yet unclassified' }
FirmataPin >> pinValue: aValue [
	value := aValue
]

{ #category : 'accessing' }
FirmataPin >> state [
	^ state
]

{ #category : 'accessing' }
FirmataPin >> state: anObject [
	state := anObject
]
