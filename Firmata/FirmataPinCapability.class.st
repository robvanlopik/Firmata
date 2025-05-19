"
I represent one of the possible capabilities of a FirmataPn. 

instance vars:
mode - the mode of the pin, a number see FirmataConstants
resolution: - the number of bits of resolution, eg for PWM or AnalogInput
"
Class {
	#name : 'FirmataPinCapability',
	#superclass : 'Object',
	#instVars : [
		'mode',
		'resolution'
	],
	#category : 'Firmata',
	#package : 'Firmata'
}

{ #category : 'as yet unclassified' }
FirmataPinCapability class >> mode: number resolution: number2 [
	"create instance with given values"	
	^self new mode: number; resolution: number2
]

{ #category : 'accessing' }
FirmataPinCapability >> mode [
	^ mode
]

{ #category : 'accessing' }
FirmataPinCapability >> mode: anObject [
	mode := anObject
]

{ #category : 'accessing' }
FirmataPinCapability >> resolution [
	^ resolution
]

{ #category : 'accessing' }
FirmataPinCapability >> resolution: anObject [
	resolution := anObject
]
