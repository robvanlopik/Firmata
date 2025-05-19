"
I am an implementation of the Firmata protocol for talking to an Arduino board. 
For more information check: http://www.firmata.org/

This implementation is mostly based on FirmataVB by Andrew Craigie.
http://www.acraigie.com/programming/firmatavb/default.html

firmata := Firmata new
	connectOnPort: '/dev/ttyACM0'
	baudRate: 57600.
	
firmata isConnected.
firmata digitalPin: 13 mode: FirmataConstants pinModeOutput.

firmata digitalWrite: 13 value: 1.
1 second wait.
firmata digitalWrite: 13 value: 0.
1 second wait.
firmata digitalWrite: 13 value: 1.
1 second wait.
firmata digitalWrite: 13 value: 0.
1 second wait.
firmata digitalWrite: 13 value: 1.

firmata disconnect.

Note that allPins numbers firmata pins the smalltalk way, zo allPins at: 1 denotes arduino pin 0!

"
Class {
	#name : 'Firmata',
	#superclass : 'Object',
	#instVars : [
		'port',
		'analogInputData',
		'digitalInputData',
		'digitalOutputData',
		'parsingSysex',
		'storedInputData',
		'sysexBytesRead',
		'waitForData',
		'executeMultiByteCommand',
		'multiByteChannel',
		'majorVersion',
		'minorVersion',
		'steppingProcess',
		'allPins',
		'pinMap',
		'i2cData',
		'encoderData',
		'dataGuard',
		'announcer',
		'firmwareName',
		'stringData',
		'dispatchDict'
	],
	#category : 'Firmata',
	#package : 'Firmata'
}

{ #category : 'instance creation' }
Firmata class >> onPort: portNumber baudRate: aNumber [
	^ self new
		connectOnPort: portNumber baudRate: aNumber;
		yourself
]

{ #category : 'analog pins' }
Firmata >> activateAnalogPin: pinNumber [ 
	self analogPinReport: pinNumber onOff: 1.

]

{ #category : 'digital pins' }
Firmata >> activateDigitalPort: n [
			self digitalPortReport: n onOff: 1

]

{ #category : 'analog pins' }
Firmata >> analogPinReport: pin onOff: onOff [ 
	"Sends a message to turn Analog Pin reportng on or off for a pin"
self port 
		nextPutAll: (ByteArray
				with: (FirmataConstants reportAnalog  bitOr: pin)
				with: onOff)
]

{ #category : 'analog pins' }
Firmata >> analogRead: pinNumber [
"Returns an analog value for an individual Analog pin"
	| value |
	dataGuard critical: [ value := (allPins at: (pinMap at: pinNumber)) pinValue ].
	^value
]

{ #category : 'digital pins' }
Firmata >> analogWrite: pin value: value [ 
	"Sends a PWM value to a digital pin. 0 - 255
	if necessary use extended analog rite"
	| analogWriteBuffer |
	(pin > 15) ifTrue: [^self  extendedAnalogWrite: pin value: value rounded].
	analogWriteBuffer := ByteArray new: 3 withAll: 0.
	analogWriteBuffer
		at: 1
		put: (FirmataConstants analogMessage
				bitOr: (pin bitAnd: 15));
		
		at: 2
		put: (value rounded bitAnd: 127);
		
		at: 3
		put: ((value rounded bitShift: -7)
				bitAnd: 127).
self port  nextPutAll: analogWriteBuffer
]

{ #category : 'encoder' }
Firmata >> attachEncoder: number pinA: pinNumber1 pinB: pinNumber2 [
	"attach (init)  an encode with e number <= maxEncoders(5?)	"
			
	| request |
	request := ByteArray new: 7.
	request 
		at: 1 put: FirmataConstants startSysex ;
		at: 2 put: FirmataConstants encoderData;
		at: 3 put: 0;  "encoder_attach"
		at: 4 put: number ;
		at: 5 put: pinNumber1 ;
		at: 6 put: pinNumber2;
		at: 7 put: FirmataConstants endSysex .
								
	self port nextPutAll: request.
	encoderData at: number put: 0.
]

{ #category : 'servos' }
Firmata >> attachServoToPin: pinNumber [ 
	self
		servoConfig: pinNumber
		minPulse: 544
		maxPulse: 2400
		angle: 0
]

{ #category : 'connection' }
Firmata >> connectOnPort: portName baudRate: aNumber [
	"If the port cant't be open it stores nil, this way we can know if it is
	connected by asking if port is nil.
	In windows we can't open a port using the port name, so I convert the
	string to an integer"
	self isConnected ifTrue: [^ self].
	port := SerialPort new baudRate: aNumber.
	portName isString ifFalse: [ 
		self error: 'Expected port name. E.g. ''/dev/ttyACM0''' ].
	port openPort: portName.
	
	self isConnected ifTrue: [
		self
			startSteppingProcess;
			controlFirmataInstallation;
			setupPins ]
]

{ #category : 'error control' }
Firmata >> controlConnection [
	self isConnected
		ifFalse: [ ^ self error: 'Serial port is not connected' ]
]

{ #category : 'error control' }
Firmata >> controlFirmataInstallation [
	"If Firmata is not installed I throw an error"

	self isFirmataInstalled
		ifFalse: [ ^ self
				error:
					'Firmata doesn''t seem to be installed.
Please use the Arduino IDE to upload the StandardFirmata sketch' ]
]

{ #category : 'analog pins' }
Firmata >> deactivateAnalogPin: pinNumber [ 
	self analogPinReport: pinNumber onOff: 0
]

{ #category : 'digital pins' }
Firmata >> deactivateDigitalPort: n [
			self digitalPortReport: n onOff: 0

]

{ #category : 'encoder' }
Firmata >> detachEncoder: encoderNumber [
	| request |
	request := (ByteArray new: 4)
		at: 1 put: FirmataConstants startSysex ;
		at: 2 put: FirmataConstants encoderData ;
		at: 3 put: 5 ; "ENCODER_DETACH"
		at: 4 put: FirmataConstants endSysex ;
		yourself.
	self port nextPutAll: request
]

{ #category : 'servos' }
Firmata >> detachServoFromPin: pinNumber [ 
	self pin: pinNumber mode: FirmataConstants pinModeOutput 
]

{ #category : 'digital pins' }
Firmata >> digitalPin: pinNumber mode: mode [
"Digital ports should always be active"
pinNumber <= 7
	ifTrue: [self activateDigitalPort: 0]
	ifFalse: [self activateDigitalPort: 1].
self  pin: pinNumber mode: mode
]

{ #category : 'digital pins' }
Firmata >> digitalPortReport: port1 onOff: onOff [
"Sends a message to toggle reporting for a whole digital port"
	self port 
		nextPutAll: (ByteArray
				with: (FirmataConstants reportDigital bitOr: port1 )
				with: onOff)
]

{ #category : 'digital pins' }
Firmata >> digitalRead: pinNumber [ 
	"Retuns On/Off data for an individual Digital Pin"
	" ((digitalInputData at: (pinNumber bitShift: -3)
			+ 1)
		bitShift: (pinNumber bitAnd: 7) * -1)
		bitAnd: 1"
		
	dataGuard critical: [^(allPins at: (pinNumber + 1)) pinValue]
]

{ #category : 'digital pins' }
Firmata >> digitalWrite: pin value: value [ 
	"Sends an On or Off message to an individual Digital Pin"
	| portNumber adjustment digitalWriteBuffer |
	portNumber := (pin bitShift: -3)
				bitAnd: 15.
	adjustment := 1
				bitShift: (pin bitAnd: 7).
	digitalWriteBuffer := ByteArray new: 3 withAll: 0.
	value = 0
		ifTrue: [digitalOutputData
				at: portNumber + 1
				put: ((digitalOutputData at: portNumber + 1)
						bitAnd: adjustment bitInvert)]
		ifFalse: [digitalOutputData
				at: portNumber + 1
				put: ((digitalOutputData at: portNumber + 1)
						bitOr: adjustment)].
	digitalWriteBuffer
		at: 1
		put: (FirmataConstants digitalMessage bitOr: portNumber);
		at: 2
		put: ((digitalOutputData at: portNumber + 1)
				bitAnd: 127);
		at: 3
		put: ((digitalOutputData at: portNumber + 1)
				bitShift: -7).
	self port nextPutAll: digitalWriteBuffer
]

{ #category : 'digital pins' }
Firmata >> directDigitalWrite: pinNumber value: oneOrZero [
	"directly write 0 or ! to digital pin, bypassing port mechanism"	
			
	| buffer  |
	buffer := ByteArray with: FirmataConstants setDigitalPinValue
								with: pinNumber
								with: oneOrZero.
	port nextPutAll: buffer 
]

{ #category : 'connection' }
Firmata >> disconnect [
	self isConnected
		ifTrue: [self stopSteppingProcess.
			port close.
			port := nil.
			self initializeVariables]
]

{ #category : 'sysex processing' }
Firmata >> dispatchSysex [
	" at this point we have a sysex message in storedInputData"
	| sysexCommand data action|
	sysexCommand := storedInputData first.
	data := storedInputData copyFrom: 2 to: sysexBytesRead.
	action := dispatchDict at: sysexCommand ifAbsent: [ self error: 'Unknown sysex command ' , sysexCommand hex].
	self perform: action with: data.
]

{ #category : 'encoder' }
Firmata >> encoderAutoReporting: aBoolean [
	"enable/disable auto reporting (at sample interval!)"
	| request |
	request := (ByteArray new: 4)
		at: 1 put: FirmataConstants startSysex ;
		at: 2 put: FirmataConstants encoderData ;
		at: 3 put: aBoolean asBit;
		at: 4 put: FirmataConstants endSysex ;
		yourself.
	self port nextPutAll: request
	
]

{ #category : 'digital pins' }
Firmata >> extendedAnalogWrite: pinNr value: aNumber [
	"allows addressing beyond pin 15 and also higherr resolution"	
			
	| data iNumber buffer|
	iNumber := aNumber rounded.
	data := OrderedCollection new.
	data add: (iNumber bitAnd: 16r7F).
	data add: ((iNumber bitShift: -7) bitAnd: 16r7F).
	iNumber := iNumber bitShift: -14.
	(iNumber ~=  0) ifTrue: [data add: (iNumber bitAnd: 16r7F)].
	buffer := (FirmataConstants startSysex) asByteArray,
					(FirmataConstants extendedAnalog) asByteArray,
					data asByteArray,
					(FirmataConstants endSysex ) asByteArray.
	port nextPutAll: buffer
	
]

{ #category : 'analog pins' }
Firmata >> firmataAnalogPinnr: anAnalogPinNumber [
	"creturn the FirmataPin with the corresponding arduino pin number
	should this not be a copy??"	
			
	^(allPins at: ((pinMap at: anAnalogPinNumber)  + 1)) copy
]

{ #category : 'other commands' }
Firmata >> firmataPin: anArduinoPinNumber [
	"creturn the FirmataPin with the corresponding arduino pin number
	should this not be a copy??"	
			
	^(allPins at: (anArduinoPinNumber + 1)) copy
]

{ #category : 'other commands' }
Firmata >> firmwareName [
	^firmwareName asString
]

{ #category : 'utilities' }
Firmata >> from4Bytes: aByteArray [ 
	"cconvert 4 7-bits bytes to one integer"	
			
	| response |
	response := (((aByteArray at: 4) * 128 +
					(aByteArray at: 3)) * 128 +
					(aByteArray at: 2)) * 128 +
					(aByteArray at: 1).
	^response
]

{ #category : 'other commands' }
Firmata >> fullSysex: aByteArray [ 
	"send start, bytes and end"	
			
	self startSysex .
	self port nextPutAll: aByteArray.
	self endSysex
]

{ #category : 'i2c' }
Firmata >> i2cConfig [
	"start i2c on the standard pins. It makes sense to update capability query afterwards"
	
self port nextPutAll: (ByteArray with: FirmataConstants startSysex
										with: FirmataConstants i2cConfig
										with: FirmataConstants endSysex)

]

{ #category : 'i2c' }
Firmata >> i2cConfigWithDelay: microseconds [
	| message |
	message := ByteArray with: FirmataConstants startSysex
									with: FirmataConstants i2cConfig
									with: (microseconds bitAnd:  16r7F)
									with: ((microseconds bitShift: -7) bitAnd: 16r7F)
									with: FirmataConstants endSysex.
	self port nextPutAll: message
]

{ #category : 'i2c' }
Firmata >> i2cRead: anI2Caddress count: aNumber [
	| request |
	request := ByteArray new: 7.
	request
		at: 1 put: FirmataConstants startSysex;
		at: 2 put: FirmataConstants i2cRequest;
		at: 3 put: (anI2Caddress bitAnd: 16r7F);
		at: 4 put: 2r00001000; "single read"
		at: 5 put: (aNumber bitAnd: 16r7F);
		at: 6 put: ((aNumber bitShift: -7) bitAnd: 16r7F);
		at: 7 put: FirmataConstants endSysex .
	self port nextPutAll: request.
]

{ #category : 'i2c' }
Firmata >> i2cRead: anI2Caddress count: aNumber register: aRegister [
	| request |
	request := ByteArray new: 9.
	request
		at: 1 put: FirmataConstants startSysex;
		at: 2 put: FirmataConstants i2cRequest;
		at: 3 put: (anI2Caddress bitAnd: 16r7F);
		at: 4 put: 2r00001000; "single read"
		at: 5 put: (aRegister bitAnd: 16r7F);
		at: 6 put: (aRegister bitShift: -7);
		at: 7 put: (aNumber bitAnd: 16r7F);
		at: 8 put: ((aNumber bitShift: -7) bitAnd: 16r7F);
		at: 9 put: FirmataConstants endSysex .
	self port nextPutAll: request
	
]

{ #category : 'i2c' }
Firmata >> i2cReadAnswer: address [
	^i2cData at: address
]

{ #category : 'i2c' }
Firmata >> i2cReadContinous: anI2Caddress count: aNumber [
	| request |
	request := ByteArray new: 7.
	request
		at: 1 put: FirmataConstants startSysex;
		at: 2 put: FirmataConstants i2cRequest;
		at: 3 put: (anI2Caddress bitAnd: 16r7F);
		at: 4 put: 2r00010000; "continuous read"
		at: 5 put: (aNumber bitAnd: 16r7F);
		at: 6 put: ((aNumber bitShift: -7) bitAnd: 16r7F);
		at: 7 put: FirmataConstants endSysex .
	self port nextPutAll: request
]

{ #category : 'i2c' }
Firmata >> i2cReadContinous: anI2Caddress count: aNumber register: aRegister [
	| request |
	request := ByteArray new: 9.
	request
		at: 1 put: FirmataConstants startSysex;
		at: 2 put: FirmataConstants i2cRequest;
		at: 3 put: (anI2Caddress bitAnd: 16r7F);
		at: 4 put: 2r00010000; "continuous read"
		at: 5 put: (aRegister bitAnd: 16r7F);
		at: 6 put: (aRegister bitShift: -7);
		at: 7 put: (aNumber bitAnd: 16r7F);
		at: 8 put: ((aNumber bitShift: -7) bitAnd: 16r7F);
		at: 9 put: FirmataConstants endSysex .
	self port nextPutAll: request
]

{ #category : 'i2c' }
Firmata >> i2cStopReading: address [ 
	"stop continuous reading on the specified address"
	| request |
	request := ByteArray with: FirmataConstants startSysex 
								with: FirmataConstants i2cRequest 
								with: (address bitAnd: 16r7F)
								with: 2r00011000 "stop reading"
								with: FirmataConstants endSysex .
	self port nextPutAll: request

]

{ #category : 'i2c' }
Firmata >> i2cWriteTo: anI2CAddress data: bytes [
	"Write a variable number of bytes to a i2c device at address anI2CAdress
	"

	| buffer request |
	buffer := self to7Bits: bytes.
	request := ByteArray
		with: FirmataConstants startSysex
		with: FirmataConstants i2cRequest
		with: (anI2CAddress bitAnd: 16r7F)
		with: 0.
	request := request, buffer, ((FirmataConstants endSysex) asByteArray).
	self port nextPutAll: request
]

{ #category : 'initialize-release' }
Firmata >> initialize [
self initializeVariables
]

{ #category : 'initialize-release' }
Firmata >> initializeVariables [
	digitalOutputData := Array new: 16 withAll: 0.
	digitalInputData := Array new: 16 withAll: 0.
	analogInputData := Array new: 16 withAll: 0.
	storedInputData := Array new: (FirmataConstants maxDataBytes) * 5 withAll: 0.
	allPins := OrderedCollection new.
	parsingSysex := false.
	sysexBytesRead := waitForData := executeMultiByteCommand := multiByteChannel := majorVersion := minorVersion := 0.
	pinMap := Dictionary new.  "With analog pin number as key"
	i2cData := Dictionary new.  "with i2c address as key and a bytearray as data"
	encoderData := Dictionary new. "encoder number as key"
	dataGuard := Mutex new.
	announcer := Announcer new.
	dispatchDict := { 
			(FirmataConstants analogMappingResponse -> #processAnalogMapping:) .
			(FirmataConstants capabilityResponse -> #processCapability:).
			(FirmataConstants reportFirmware -> #processFirmware: ).
			(FirmataConstants pinStateResponse -> #processPinState: ).
			(FirmataConstants stringData -> #processStringData: ).
			(FirmataConstants i2cReply -> #processI2CData: ).
			(FirmataConstants encoderData -> #processEncoderData:).
			(FirmataConstants stepperCommand -> #processStepperEvent: )
			 } asDictionary 
]

{ #category : 'connection' }
Firmata >> isConnected [
^port notNil
]

{ #category : 'testing' }
Firmata >> isFirmataInstalled [
"I check if Firmata responds well to queryVersion. I try for 5 seconds"
| t timeout |
t := Time millisecondClockValue.
timeout := 5000.
[self queryVersion. 500 milliSeconds asDelay wait.
self version > 0 or: [(Time millisecondsSince: t) > timeout]] whileFalse.
^self version > 0
]

{ #category : 'accessing' }
Firmata >> majorVersion [
^majorVersion
]

{ #category : 'accessing' }
Firmata >> majorVersion: version1 minorVersion: version2 [
majorVersion := version1.
minorVersion := version2
]

{ #category : 'accessing' }
Firmata >> maxPins [
	" return total number of pins, including analog "	
			
	^allPins size
]

{ #category : 'other commands' }
Firmata >> millisFromT1: timestamp1 toT2: timestamp2 [
	"uniform method to get the time in milliseconds between two timestamps"
	^(timestamp2 - timestamp1) asMilliSeconds 
]

{ #category : 'accessing' }
Firmata >> minorVersion [
^minorVersion
]

{ #category : 'accessing' }
Firmata >> nameSymbol [
	^ #firmata
]

{ #category : 'i2c' }
Firmata >> openI2C: deviceAddress [ 
	"creates and returns an I2CFirmataConnection for the specified i2c deviceAddress
	This equivalent to the way WiringPi reifies the I2C Connection
	and can directly be used in the ArduinoFirmataDriver of PharoThings"
	| connection |
	connection := FirmataI2CConnection new.
	connection address: deviceAddress.
	connection firmata: self.
	self i2cConfig ."no problem that this will be executed for each I2C device"
	^connection
]

{ #category : 'receiving' }
Firmata >> parseCommandHeader: inputByte [ 
"I check the inputByte for a command header and then I set the variables accordingly to process the data in the following step"
	| command |
	inputByte < 240
		ifTrue: [command := inputByte bitAnd: 240.
			multiByteChannel := inputByte bitAnd: 15.]
		ifFalse: [command := inputByte].
	command caseOf: {
		[FirmataConstants analogMessage] -> 
			[waitForData := 2.
			executeMultiByteCommand := command].
		[FirmataConstants digitalMessage] -> 
			[waitForData := 2.
			executeMultiByteCommand := command].
		[FirmataConstants setPinMode] -> 
			[waitForData := 2.
			executeMultiByteCommand := command].
		[FirmataConstants reportDigital] -> 
			[waitForData := 1.
			executeMultiByteCommand := command].
		[FirmataConstants startSysex] -> 
			[parsingSysex := true.
			sysexBytesRead := 0].
		[FirmataConstants reportVersion] -> 
			[waitForData := 2.
			executeMultiByteCommand := command]}
		 otherwise: []
]

{ #category : 'receiving' }
Firmata >> parseData: inputByte [ 
"I check inputByte for data according to the command header I found in the previous step, then I use the data to set the corresponding variables"

	waitForData := waitForData - 1.
	storedInputData at: waitForData + 1 put: inputByte.

	(waitForData = 0
			and: [executeMultiByteCommand ~= 0])
		ifTrue: [executeMultiByteCommand caseOf: {
				[FirmataConstants analogMessage] -> [self setAnalogInput: multiByteChannel value: (storedInputData first bitShift: 7)
						+ storedInputData second].
				[FirmataConstants digitalMessage] -> [
						self setDigitalInputs: multiByteChannel data: (storedInputData first bitShift: 7)
						+ storedInputData second].
				[FirmataConstants reportVersion] -> [self majorVersion: storedInputData first minorVersion: storedInputData second]}
				 otherwise: [].
			executeMultiByteCommand := 0]
]

{ #category : 'sysex processing' }
Firmata >> parseSysex: inputByte [ 
	inputByte = FirmataConstants endSysex
		ifTrue: [parsingSysex := false. self dispatchSysex]
		ifFalse: [storedInputData at: sysexBytesRead + 1 put: inputByte.
			sysexBytesRead := sysexBytesRead + 1
				]
]

{ #category : 'digital pins' }
Firmata >> pin: pin mode: mode [
"Sends an individual Pin Mode message"
	self assert: ((self firmataPin: pin)  capableOfMode: mode)
		description: 'Mode ', mode printString, ' not available for pin: ', pin printString.
self port nextPutAll: (ByteArray with: FirmataConstants setPinMode with: pin with: mode).
]

{ #category : 'pin modes' }
Firmata >> pinsWithMode: aMode [
	"return collection with true or falsee for each pin number"
	^allPins collect: [ :pin | pin capableOfMode: aMode ]
]

{ #category : 'accessing' }
Firmata >> port [
	self controlConnection.
	^port
]

{ #category : 'printing' }
Firmata >> printOn: aStream [
super printOn: aStream.
aStream nextPutAll: '(',self hash asString,')'
]

{ #category : 'sysex processing' }
Firmata >> processAnalogMapping: data [ 
	"the result of an anlog mapping request consists op the sequence of pin, with 127 representing a non-nalog pin and the analog pin number if it is analog"	
			
	(allPins isEmpty) ifTrue: [ ^nil ]. "ignore, should do capability query first"
	data withIndexDo: [ :each :i | 
				(each ~= 127) ifTrue: [ (allPins at: i )analogPinNumber: each. pinMap at: each put: (i - 1) ] ]
	
]

{ #category : 'sysex processing' }
Firmata >> processCapability: data [
	"fill allPins with the results of the capability querys"	
		
	| pindata pinNr |
	(allPins size ~= 0) ifTrue: [ ^nil ]. "We might lso update allPins, but usally boards don't change"
	pindata := data splitOn: 127.
	pindata removeLast.
	pinNr := 0.
	pindata do: [ :eachPin | | pin length|
		pin := FirmataPin new.
		pin id: pinNr.
		pinNr := pinNr + 1.
		pin pinValue: 0.
		length := eachPin size.
		(length > 0) ifTrue:
			[ 
				1 to: length by: 2 do: [ :i |  
					pin addCapability: (FirmataPinCapability mode: (eachPin at: i) 
								resolution: (eachPin at: (i + 1)))]
				 ].
		allPins add: pin.
			
			]
]

{ #category : 'sysex processing' }
Firmata >> processEncoderData: data [
	" This response can contain more than one answer"
	| encoderNumber sign value totalNumber signBit|
	totalNumber := (data size - 1) / 5.
	1 to: totalNumber do: [ :i |
		encoderNumber := (data at: (5 * i - 4)) bitAnd: 2r00111111.
		signBit := (data at: (5 * i - 4)) bitAnd: 2r01000000.
		sign := -1.
		(signBit = 0) ifTrue: [ sign := 1].
		value := sign * ( self from4Bytes: (data copyFrom: (5 * i - 3) to: (5 * i ))).
		encoderData at: encoderNumber put: value]
		

]

{ #category : 'sysex processing' }
Firmata >> processFirmware: data [
	majorVersion := data at: 1.
	minorVersion := data at: 2.
	firmwareName := ByteArray new: ((data size - 2) / 2).
	3 to: data size by: 2 do:
		[ :i | firmwareName at: ((i - 1) / 2) put: (data at: i) ]
]

{ #category : 'sysex processing' }
Firmata >> processI2CData: data [
	| buffer address|
	address := (data at: 1) + ((data at: 2) bitShift: 7).
	buffer := OrderedCollection new.
	3 to: (data size)  by: 2 do: 
		[ :x | buffer add: ((data at: x) + ((data at: (x + 1)) bitShift: 7)) ].
	i2cData at: address put: (buffer asByteArray)
	



]

{ #category : 'receiving' }
Firmata >> processInput [
	| data |
	data := port readByteArray.

	data
		do: [:inputByte | 

parsingSysex
				ifTrue: [self parseSysex: inputByte]
				ifFalse: [(waitForData > 0
							and: [inputByte < 128])
						ifTrue: [self parseData: inputByte]
						ifFalse: [self parseCommandHeader: inputByte]]]
]

{ #category : 'sysex processing' }
Firmata >> processPinState: data [
	"answer to pin state request. Update corresponding pin in allPins, 
	do nothing when allPins has not been initialized"	
		|	targetPin |
	allPins ifNil: [ ^nil ].
	targetPin := allPins at: ((data at: 1) + 1) .
	targetPin mode: (data at: 2).
	targetPin state: (data at: 3).
]

{ #category : 'sysex processing' }
Firmata >> processStepperEvent: data [ 
	"a (legacy stepper sends this when it is finished moving
	data in this case is the stepper number and we give notice of the event 
	with a StepperFinished announcement"
	[ announcer announce: (FirmataStepperFinished new stepperNr: (data first)) ]
	 forkAt: Processor userInterruptPriority 
]

{ #category : 'sysex processing' }
Firmata >> processStringData: data [
	" what to do with received string data? For now provide a popup	
		I should strip the null bytes from the string!!"
			
	stringData := ByteArray new: ((data size) / 2).
	1 to: data size by: 2 do:
		[  :i | stringData at: ((i + 1) / 2) put: (data at: i)]
]

{ #category : 'other commands' }
Firmata >> queryAnalogMapping [
	"sends the analog mapping query"
	|request |
	request := ByteArray with: FirmataConstants startSysex
								with: FirmataConstants analogMappingQuery
								with: FirmataConstants endSysex.
	self port nextPutAll: request
]

{ #category : 'other commands' }
Firmata >> queryCapabilities [
	"sends the capabilities query"
	|request |
	request := ByteArray with: FirmataConstants startSysex
								with: FirmataConstants capabilityQuery
								with: FirmataConstants endSysex.
	self port nextPutAll: request
]

{ #category : 'other commands' }
Firmata >> queryFirmware [
"Send a Firmware Name and Version query"

self port  nextPutAll: (ByteArray with: FirmataConstants startSysex with: FirmataConstants reportFirmware with: FirmataConstants endSysex).
]

{ #category : 'other commands' }
Firmata >> queryPinState: pinNumber [
	"query the pin state for pin 0-127"
	|packet |
	self assert: (pinNumber < self maxPins) description: 'pin number out of range'.
	packet := ByteArray with: FirmataConstants startSysex 
							with: FirmataConstants pinStateQuery 
							with: (pinNumber bitAnd: 16r7F)
							with: FirmataConstants endSysex .
	self port nextPutAll: packet
]

{ #category : 'other commands' }
Firmata >> queryVersion [
"Send a version report query"
self port nextPutAll: (ByteArray with: FirmataConstants reportVersion ).
]

{ #category : 'encoder' }
Firmata >> readAnswerOfEncoder:  number [
	^encoderData at: number
]

{ #category : 'encoder' }
Firmata >> readEncoder: number [ 
	| request |
	request := ByteArray with: FirmataConstants startSysex 
								with: FirmataConstants encoderData
								with: 1  "encoder_repot_position"
								with: number
								with: FirmataConstants endSysex .
	self port nextPutAll: request
]

{ #category : 'encoder' }
Firmata >> readEncodersAll [
	"request positions of all encoders"
	| request |
	request := (ByteArray new: 4).
	request
		at: 1 put: FirmataConstants startSysex ;
		at: 2 put: FirmataConstants encoderData ;
		at: 3 put: 2 ; "ENCODER_REPORT_POSITION"
		at: 4 put: FirmataConstants endSysex.

	self port nextPutAll: request
]

{ #category : 'announce requests' }
Firmata >> removeSubscription: aSubscription [
	" remove this subscription from the subscription registry"	
			
	announcer removeSubscription: aSubscription

]

{ #category : 'other commands' }
Firmata >> reset [
	"send systemReset command"
			
	self port nextPutAll: (ByteArray with: FirmataConstants systemReset ).
]

{ #category : 'servos' }
Firmata >> servoConfig: pin minPulse: minPulse maxPulse: maxPulse [
	"Note: the parameter angle is ignored by Firmata, so considerr this method deprecated
	Default values: 
	minPulse 544 (LSB 32 MSB 4)
	maxPulse 2400 (LSB 96 MSB 18
	"
	| b |
	b := ByteArray new: 8.
	b at: 1 put: FirmataConstants startSysex;
		 at: 2 put: FirmataConstants servoConfig;
		 at: 3 put: pin;
		 at: 4 put:  (minPulse rounded bitAnd: 127);
		 at: 5 put: ((minPulse rounded bitShift: -7)
				bitAnd: 127);
		 at: 6 put: (maxPulse rounded bitAnd: 127);
		 at: 7 put: ((maxPulse rounded bitShift: -7)
				bitAnd: 127);
		
		 at: 8 put: FirmataConstants endSysex.
	self port nextPutAll: b
]

{ #category : 'servos' }
Firmata >> servoConfig: pin minPulse: minPulse maxPulse: maxPulse angle: angle [
	"Note: the parameter angle is ignored by Firmata, so considerr this method deprecated
	Default values: 
	minPulse 544 (LSB 32 MSB 4)
	maxPulse 2400 (LSB 96 MSB 18
	"
	| b |
	b := ByteArray new: 10.
	b at: 1 put: FirmataConstants startSysex;
		 at: 2 put: FirmataConstants servoConfig;
		 at: 3 put: pin;
		 at: 4 put:  (minPulse rounded bitAnd: 127);
		 at: 5 put: ((minPulse rounded bitShift: -7)
				bitAnd: 127);
		 at: 6 put: (maxPulse rounded bitAnd: 127);
		 at: 7 put: ((maxPulse rounded bitShift: -7)
				bitAnd: 127);
		 at: 8 put: (angle rounded bitAnd: 127);
		 at: 9 put: ((angle rounded bitShift: -7)
				bitAnd: 127);
		 at: 10 put: FirmataConstants endSysex.
	self port nextPutAll: b
]

{ #category : 'servos' }
Firmata >> servoOnPin: pinNumber angle: degrees [
self analogWrite: pinNumber value: degrees
]

{ #category : 'analog pins' }
Firmata >> setAnalogInput: pin value: value [
"Stores analog value data in the mapped firmataPin (with Arduino pinnr)"
	dataGuard critical: [ (allPins at: (pinMap at: pin)) pinValue: value]
]

{ #category : 'digital pins' }
Firmata >> setDigitalInputs: portNumber data: portData [ 
"Puts but masked On/Off data for a whole digital port into array"
	"digitalInputData at: portNumber + 1 put: portData"
	
	1 to: 8 do: [  :bit |  | newValue oldValue pinNr|
		pinNr := portNumber * 8 + bit.
		oldValue := (allPins at: pinNr) pinValue.
		newValue := portData bitAt: bit.
		dataGuard critical: [ (allPins at: pinNr) pinValue: newValue ].
		[(oldValue ~= newValue) ifTrue: 
			[ announcer announce: (FirmataPinChange new 
					pinNr: (pinNr - 1); 
					pinValue: newValue;
					timestamp: DateAndTime now )]] forkAt: Processor userInterruptPriority
	]
]

{ #category : 'other commands' }
Firmata >> setSamplingInterval: millis [
	"set the sampling interval to millis milliseconds. Cannot be less than 19
	This controls the reporting frequency and "
	| request |
	request := ByteArray with: FirmataConstants startSysex
								with: FirmataConstants samplingInterval
								with: (millis rounded bitAnd: 16r7F)
								with: (( millis rounded bitShift: -7) bitAnd: 16r7F)
								with: FirmataConstants endSysex.
	self port nextPutAll: request
]

{ #category : 'initialization-data' }
Firmata >> setupPins [
	" query capabilities and also initialize the allPins insnce variable 
	then setup the analog pin mapping; we will have to wait for the answers"	
		
	| retries delay |
	self queryCapabilities.
	delay := 50.
	retries := 0.
	[ delay milliSeconds wait. retries := retries + 1. (retries > 10) or: self maxPins ~= 0] whileFalse .
	(self maxPins = 0) ifTrue: [ self error: 'capability query failed' ].
	
	self queryAnalogMapping.
	retries := 0.
	[ delay milliSeconds wait. retries := retries + 1. (retries > 10) or: pinMap size ~= 0] whileFalse .
	(pinMap size = 0) ifTrue: [ self error: 'analog mapping  query failed (or no analog pins)' ].
			
	
]

{ #category : 'stepping' }
Firmata >> startSteppingProcess [
	steppingProcess notNil
		ifTrue: [^ self].
	steppingProcess := [[self step.
			(Delay forMilliseconds: self stepTime) wait] repeat]
				forkAt: Processor lowIOPriority  named: self asString 
]

{ #category : 'other commands' }
Firmata >> startSysex [
"Sends a Start Sysex message"
self port  nextPutAll: (ByteArray with: FirmataConstants startSysex  ).
]

{ #category : 'stepping' }
Firmata >> step [
	self processInput
]

{ #category : 'stepping' }
Firmata >> stepTime [
	^ 1
]

{ #category : 'stepper' }
Firmata >> stepperConfig: devnumber delay: museconds interface: code stepsPerRev: number pins: aByteArray [
	"This is the old stepper interface
	delay: 0 is 1 microsecond, 1 is 2 microseconds
	interface:  XXXX001 = step + direction driver XXXX010 = two wire XXX100 = four wire
	stepsPerRev(olution)
	pins: a ByeArray of 2 or 4 pin numbers (0-127)"
	| request |
	request := ByteArray new: 7.
	request
		at: 1 put: FirmataConstants startSysex;
		at: 2 put: FirmataConstants stepperCommand;
		at: 3 put: 0;  "config subcommand"
		at: 4 put: devnumber;
		at: 5 put: ((museconds bitShift: -3) bitOr: code);
		at: 6 put: (number bitAnd: 16r7F);
		at: 7 put: ((number bitShift: -7) bitAnd: 16r7F).
	request := request, aByteArray, ((FirmataConstants endSysex) asByteArray).
	self port nextPutAll: request
								
								
								
	
	
			
]

{ #category : 'stepper' }
Firmata >> stepperStep: stepperNn direction: dir steps: number speed: speed [
	" number of steps maximum2,097,151"	
	| request |
	request := ByteArray new: 11.
	request
		at: 1 put: FirmataConstants startSysex;
		at: 2 put: FirmataConstants stepperCommand;
		at: 3 put: 1;  "step"
		at: 4 put: stepperNn;
		at: 5 put: dir;
		at: 6 put: (number bitAnd: 16r7F);
		at: 7 put: ((number bitShift: -7) bitAnd: 16r7F);
		at: 8 put: ((number bitShift: -14) bitAnd: 16r7F);
		at: 9 put: (speed bitAnd: 16r7F);
		at: 10 put: ((speed bitShift: -7) bitAnd: 16r7F);
		at: 11 put: FirmataConstants endSysex.

	self port nextPutAll: request								
	
]

{ #category : 'stepper' }
Firmata >> stepperStep: stepperNn direction: dir steps: number speed: speed accel: accelValue decel: decelValue [
	" number of steps maximum2,097,151"	
	| request |
	request := ByteArray new: 15.
	request
		at: 1 put: FirmataConstants startSysex;
		at: 2 put: FirmataConstants stepperCommand;
		at: 3 put: 1;  "step"
		at: 4 put: stepperNn;
		at: 5 put: dir;
		at: 6 put: (number bitAnd: 16r7F);
		at: 7 put: ((number bitShift: -7) bitAnd: 16r7F);
		at: 8 put: ((number bitShift: -14) bitAnd: 16r7F);
		at: 9 put: (speed bitAnd: 16r7F);
		at: 10 put: ((speed bitShift: -7) bitAnd: 16r7F);
		at: 11 put: (accelValue bitAnd: 16r7F);
		at: 12 put: ((accelValue bitShift: -7) bitAnd: 16r7F);
		at: 13 put: (decelValue bitAnd: 16r7F);
		at: 14 put: ((decelValue bitShift: -7) bitAnd: 16r7F);
		at: 15 put: FirmataConstants endSysex.

	self port nextPutAll: request								
	
]

{ #category : 'stepper' }
Firmata >> stepperStep: stepperNo steps: aNumber speed: speed [
	" number of steps maximum2,097,151, negative is CCW"	
	| sign |
	sign := 0.
	(aNumber < 0 ) ifTrue: [ sign := 1 ].
	self stepperStep: stepperNo direction: sign steps: aNumber abs speed: speed
	

]

{ #category : 'stepper' }
Firmata >> stepperStep: stepperNo steps: aNumber speed: speed accel: accelValue decel: decelValue [
	" number of steps maximum 2,097,151, negative is CCW"	
	| sign |
	sign := 0.
	(aNumber < 0 ) ifTrue: [ sign := 1 ].
	self stepperStep: stepperNo direction: sign steps: aNumber abs speed: speed accel: accelValue decel: decelValue
	

]

{ #category : 'stepping' }
Firmata >> stopSteppingProcess [
	steppingProcess isNil
		ifTrue: [^ self].
	steppingProcess terminate. 
	steppingProcess := nil
]

{ #category : 'other commands' }
Firmata >> stringData [
	^stringData
]

{ #category : 'utilities' }
Firmata >> to7Bits: aByteArray [
	"return a ByteArray with 2 seven bitscharacters for each byte"	
			
	| buffer |
	buffer := OrderedCollection new .
	aByteArray do: [ :b | buffer add: (b bitAnd: 16r7F). buffer add: ((b bitShift: -7) bitAnd: 16r7F) ].
	^buffer asByteArray
]

{ #category : 'utilities' }
Firmata >> to8bits: aByteArray [ 
	"input is an array with 7 bits bytes, return the equivalent normal bytearray"
	| buffer |
	buffer := OrderedCollection new.

]

{ #category : 'pin modes' }
Firmata >> valueForInputMode [
^FirmataConstants pinModeInput
]

{ #category : 'pin modes' }
Firmata >> valueForOutputMode [
^FirmataConstants pinModeOutput 
]

{ #category : 'pin modes' }
Firmata >> valueForPwmMode [
^FirmataConstants pinModePwm
]

{ #category : 'pin modes' }
Firmata >> valueForServoMode [
^FirmataConstants pinModeServo 
]

{ #category : 'accessing' }
Firmata >> version [
"self queryVersion."
^(majorVersion asString , '.', minorVersion asString) asNumber
]

{ #category : 'announce requests' }
Firmata >> when: anEvent do: aBlock [
	"return the subscription so it can be removed"
	
	^announcer when: anEvent do: aBlock
]

{ #category : 'announce requests' }
Firmata >> when: anEvent send: aSelector to: anObject [
	^announcer when: anEvent send: aSelector to: anObject
]

{ #category : 'encoder' }
Firmata >> zeroEncoder: encoderNumber [
	"reset encoder to 0	"
			
	| request |
	request := ByteArray  with: FirmataConstants startSysex 
								with: FirmataConstants encoderData 
								with: 3  "encoder_reset_position"
								with: encoderNumber
								with: FirmataConstants endSysex .
	self port nextPutAll:  request 
]
