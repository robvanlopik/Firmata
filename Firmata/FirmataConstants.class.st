"
See class side. I collect a bunch of constants for the Firmata protocol.
"
Class {
	#name : 'FirmataConstants',
	#superclass : 'Object',
	#category : 'Firmata',
	#package : 'Firmata'
}

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> analogMappingQuery [
	^16r69
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> analogMappingResponse [
	^16r6A
]

{ #category : 'message commands' }
FirmataConstants class >> analogMessage [
"0xE0 send data for an analog pin (or PWM)"
^16rE0
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> capabilityQuery [
	^16r6B
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> capabilityResponse [
	^16r6C
]

{ #category : 'message commands' }
FirmataConstants class >> digitalMessage [
"0x90 send data for digital pin"
^16r90
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> encoderData [
	^16r61
]

{ #category : 'message commands' }
FirmataConstants class >> endSysex [
"0xF7 end a MIDI Sysex message"
^16rF7
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> extendedAnalog [
	^16r6F
]

{ #category : 'version numbers' }
FirmataConstants class >> firmataMajorVersion [
"for non-compatible changes"
^2
]

{ #category : 'version numbers' }
FirmataConstants class >> firmataMinorVersion [
"for backward compatible changes"
^0
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> firmataString [
"0x71 a string message with 14-bits per character"
^16r71
]

{ #category : 'sysex processing' }
FirmataConstants class >> i2cConfig [
	^16r78
]

{ #category : 'sysex processing' }
FirmataConstants class >> i2cReply [
	^16r77
]

{ #category : 'sysex processing' }
FirmataConstants class >> i2cRequest [
	^16r76
]

{ #category : 'others' }
FirmataConstants class >> maxDataBytes [
"Maximum number of data bytes in non-Sysex messages"
^64
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeAnalog [
"analog pin in analogInput mode"
^2
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeEncoder [
	^16r09
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeI2C [
	^16r06
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeInput [
^0
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeInputPullup [
	^16r0B
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeOnewire [
	^16r07
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeOutput [
^1
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModePwm [
"digital pin in PWM output mode"
^3
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeSerial [
	^16r0A
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeServo [
	^16r04
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeShift [
	^16r05
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeStepper [
	^16r08
]

{ #category : 'pin modes' }
FirmataConstants class >> pinModeUnavailable [
	^ -1
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> pinStateQuery [
	^16r6D
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> pinStateResponse [
	^16r6E
]

{ #category : 'message commands' }
FirmataConstants class >> reportAnalog [
"0xC0 enable analog input by pin number"
^16rC0
]

{ #category : 'message commands' }
FirmataConstants class >> reportDigital [
"0xD0 enable digital input by port pair"
^16rD0
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> reportFirmware [
"0x79 report name and version of the firmware"
^16r79
]

{ #category : 'message commands' }
FirmataConstants class >> reportVersion [
"0xF9 report protocol version"
^16rF9
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> samplingInterval [
	^16r7A
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> servoConfig [
"0x70 set maximum angle, minPulse, maxPulse, frequency"
^16r70
]

{ #category : 'message commands' }
FirmataConstants class >> setDigitalPinValue [
	"cfrom protocol version 2.5"	
			
	^16rF5
]

{ #category : 'message commands' }
FirmataConstants class >> setPinMode [
"0xF4 set a pin to INPUT/OUTPUT/ANALOG/PWM/SERVO - 0/1/2/3/4"
^16rF4
]

{ #category : 'message commands' }
FirmataConstants class >> startSysex [
"0xF0 start a MIDI Sysex message"
^16rF0
]

{ #category : 'sysex processing' }
FirmataConstants class >> stepperCommand [
	^16r72
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> stringData [
	^16r71
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> sysexNonRealtime [
"0x7E MIDI reserved for non-realtime messages"
^16r7E
]

{ #category : 'extended command set using Sysex' }
FirmataConstants class >> sysexRealtime [
"0x7F MIDI reserved for realtime messages"
^16r7F
]

{ #category : 'message commands' }
FirmataConstants class >> systemReset [
"0xFF reset from MIDI"
^16rFF
]

{ #category : 'version numbers' }
FirmataConstants class >> versionBlickPin [
"digital pin to blick version on"
^13
]
