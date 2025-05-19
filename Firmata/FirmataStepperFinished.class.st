"
I am an announcement that is published when a stepper motor has finished its move.
My only parameter is the number of the motor
"
Class {
	#name : 'FirmataStepperFinished',
	#superclass : 'Announcement',
	#instVars : [
		'stepperNr'
	],
	#category : 'Firmata',
	#package : 'Firmata'
}

{ #category : 'accessing' }
FirmataStepperFinished >> stepperNr [
	^ stepperNr
]

{ #category : 'accessing' }
FirmataStepperFinished >> stepperNr: anObject [
	stepperNr := anObject
]
