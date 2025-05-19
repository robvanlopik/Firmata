"
Helper class to  implement I2C access to Firmata driver in the same way as WiringPi does, and with an equivalent protocol

Instvars:
firmata - the Firmata instance this connection belongs to (the real driver!)
address - the address of the I2C device; this has the same role as handle in WiringPiDeviceConnection 
readDelay - a Duration to wait before the result of a read request is read. Due to the asynchronous nature of the Firmata protocol we set it to 20 milliseconds, the smallest sample interval of a Firmata sketch.

Note that Firmata I2C reads and returns byteArrays. On reading results, the first byte is the register number.
"
Class {
	#name : 'FirmataI2CConnection',
	#superclass : 'Object',
	#instVars : [
		'firmata',
		'address',
		'readDelay'
	],
	#category : 'Firmata',
	#package : 'Firmata'
}

{ #category : 'accessing' }
FirmataI2CConnection >> address [
	^ address
]

{ #category : 'accessing' }
FirmataI2CConnection >> address: anObject [
	address := anObject
]

{ #category : 'initialize-release' }
FirmataI2CConnection >> close [
	"is sent by a PotDevice when disconnecting, but Firmata dos not have the concept 
	of closing an I2C connection, so do nothing "	
			
	
]

{ #category : 'accessing' }
FirmataI2CConnection >> firmata [
	^ firmata
]

{ #category : 'accessing' }
FirmataI2CConnection >> firmata: anObject [
	firmata := anObject
]

{ #category : 'initialization' }
FirmataI2CConnection >> initialize [
	
	readDelay := 20 milliSeconds.
]

{ #category : 'i2c' }
FirmataI2CConnection >> read16BitsAt: aRegister [
	| answer |
	firmata i2cRead: address count: 2  register: aRegister .
	readDelay wait.
	answer := firmata i2cReadAnswer: address .
	^(answer at: 3) * 256 + (answer at: 2)
]

{ #category : 'accessing' }
FirmataI2CConnection >> read8BitsArray: blockSize startingAt: reg [
	"this is copied from WiringPi; I think Firmata is smarter"
"	| result bits |
	result := ByteArray new: blockSize.
	
	1 to: blockSize do: [ :i | 
		bits := self read8BitsAt: reg + i - 1.
		result at: i put: bits].
	
	^result"
	| answer |
	firmata i2cRead: address count: blockSize register: reg.
	readDelay wait.
	answer := firmata i2cReadAnswer: address.
	^answer allButFirst
	
]

{ #category : 'i2c' }
FirmataI2CConnection >> read8BitsAt: aRegister [
	firmata i2cRead: address count: 1  register: aRegister .
	readDelay wait.
	^(firmata i2cReadAnswer: address) at: 2 "a byteArray is returned, but the first byte is the registerr number"
]

{ #category : 'accessing' }
FirmataI2CConnection >> readByteAt: aRegister [
	^self read8BitsAt: aRegister
]

{ #category : 'accessing' }
FirmataI2CConnection >> readBytesAt: aRegister count: aNumber [
	| answer |
	firmata i2cRead: address count: aNumber register: aRegister.
	readDelay wait.
	answer := firmata i2cReadAnswer: address.
	^answer allButFirst
]

{ #category : 'accessing' }
FirmataI2CConnection >> readDelay [
	^ readDelay
]

{ #category : 'accessing' }
FirmataI2CConnection >> readDelay: anObject [
	readDelay := anObject
]

{ #category : 'accessing' }
FirmataI2CConnection >> readWordAt: aRegister [
	"default read low byte first"
	^self readWordAt: aRegister bigEndian: false
]

{ #category : 'i2c' }
FirmataI2CConnection >> readWordAt: aRegister bigEndian: bool [
	"if BigEndian is true, the first byte read is the high byte"
	| answer |
	firmata i2cRead: address count: 2  register: aRegister .
	readDelay wait.
	answer := firmata i2cReadAnswer: address .
	bool ifTrue: [ ^( answer at: 2) * 256 + (answer at: 3)].
	^(answer at: 3) * 256 + (answer at: 2)
]

{ #category : 'i2c' }
FirmataI2CConnection >> write16BitsAt: aRegister data: aWord [
	firmata i2cWriteTo:  address 
			data: (ByteArray with: aRegister with: (aWord bitAnd: 16rFF) with: (aWord // 256)).
	readDelay wait. "To be sure the write takes effect"

]

{ #category : 'i2c' }
FirmataI2CConnection >> write8BitsAt: aRegister data: aByte [
	firmata i2cWriteTo:  address data: (ByteArray with: aRegister with: (aByte bitAnd: 16rFF)).
	readDelay wait. "To be sure the write takes effect"

]

{ #category : 'writing' }
FirmataI2CConnection >> writeByteAt: aRegister data: aByte [
	self write8BitsAt: aRegister data: aByte
]

{ #category : 'writing' }
FirmataI2CConnection >> writeBytesAt: aRegister data: aByteArray [

	| packet |
	packet := aRegister asByteArray , aByteArray.
	firmata i2cWriteTo: address data: packet.
	readDelay wait.
]

{ #category : 'i2c' }
FirmataI2CConnection >> writeWordAt: aRegister data: aWord [
	"default write low  byte first"
	self writeWordAt: aRegister data: aWord  bigEndian: false

]

{ #category : 'i2c' }
FirmataI2CConnection >> writeWordAt: aRegister data: aWord bigEndian: bool [
	"if bool is true write the high byte first"
	| packet |
	bool ifTrue: [ packet := ByteArray with: aRegister with: (aWord // 256) with: (aWord bitAnd: 16rFF) ]
		ifFalse: [ packet := ByteArray with: aRegister with: (aWord bitAnd: 16rFF) with: (aWord // 256) ].

	firmata i2cWriteTo:  address data: packet .
	readDelay wait. "To be sure the write takes effect"

]
