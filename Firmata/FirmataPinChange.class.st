"
I am an announcement that is triggered when a (input) pin changes state.

I deliver three values:
pinNr - the number of the pin this announcement concerns;
pinValue - the new value of the pin (0 or 1);
timestamp - the DateTime now value of the change (measured at the Pharo side)

ALL pin changes generate an announcement, as these data are received anyway
"
Class {
	#name : 'FirmataPinChange',
	#superclass : 'Announcement',
	#instVars : [
		'pinNr',
		'pinValue',
		'timestamp'
	],
	#category : 'Firmata',
	#package : 'Firmata'
}

{ #category : 'accessing' }
FirmataPinChange >> pinNr [
	^ pinNr
]

{ #category : 'accessing' }
FirmataPinChange >> pinNr: anObject [
	pinNr := anObject
]

{ #category : 'accessing' }
FirmataPinChange >> pinValue [
	^ pinValue
]

{ #category : 'accessing' }
FirmataPinChange >> pinValue: anObject [
	pinValue := anObject
]

{ #category : 'accessing' }
FirmataPinChange >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
FirmataPinChange >> timestamp: anObject [
	timestamp := anObject
]
