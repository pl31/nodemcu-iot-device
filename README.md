nodemcu-iot-device
==================

Some lua scripts to send data from a nodemcu device to a mqtt broker.

Right now, it is tested with am2302 only. To use other sensors, see `source/am2302`.


Getting started
---------------

To get started you need a configured mqtt-broker, e.g. mosquitto. To prepare your nodemcu-device, follow steps below:

- Use an appropriate firmware. For more details, see [here](firmware/README.md)
- Copy the file `source/config.lua.example` to `source/config.lua`
- Edit your `source/config.lua`
- Copy `source/*.lua` files to your device
