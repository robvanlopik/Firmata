Class {
	#name : 'BaselineOfFirmata',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfFirmata',
	#package : 'BaselineOfFirmata'
}

{ #category : 'baselines' }
BaselineOfFirmata >> baseline: spec [

	<baseline>
	spec for: #common do: [ 
		self declareSerialPortOn: spec.
		spec package: #Firmata with: [ spec requires: #('SerialPort')].

		spec group: 'default' with: #( 'Firmata' ) ]
]

{ #category : 'external projects' }
BaselineOfFirmata >> declareSerialPortOn: spec [

	spec
		baseline: 'SerialPort'
		with: [ spec repository: 'github://robvanlopik/SerialPort:main' ]
]
