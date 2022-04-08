baselines
baseline: spec

	<baseline>
	spec for: #common do: [ 
		self declareSerialPortOn: spec.
		spec package: #Firmata with: [ spec requires: #('SerialPort')].

		spec group: 'default' with: #( 'Firmata' ) ]