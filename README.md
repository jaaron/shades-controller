Smart Home Shade Controller
===========================

This project includes the software and 3D printable parts for an Alexa
enabled controller for roller shades. It includes:
    * A web application that manages shade controllers on the local
      network, relays commands from Alexa, and provides a simple web
      UI
    * A Node-JS script for an Amazon Lambda service to relay requests
      from a custom Alexa skill to the web application
    * An arduino sketch for a NodeMCU microcontrollers
    * OpenSCAD files for the housing and driver wheel for the
      controller

Building The Server
===================

First, edit `shades_server.ml` to include the email address associated
with your Amazon account as the `authorized_email`. This is used to
authorize requests from the internet (notably from the Lambda
function) using the Login With Amazon auth credential. At line 6,
replace the string `"user@host.com"` with your email address.

```
$ sed -i -e 's/user@host\.com/me@mydomain.com/' server/shades_server.ml
```

Next, install the dependencies, assuming you have `opam` installed:

```
$ sudo apt-get install mosquitto
$ opam depext mosquitto
$ opam install jbuilder core opium lwt yojson ppx_deriving_yojson mosquitto
```

Then compile
```
$ cd server && jbuilder build shades_server.exe
```

The server is intended to be run a Raspberry Pi Zero W with a touch
display for the web client but should work fine on any system capable
of running ocaml. Building the dependencies (notably core) on the Pi
Zero W may require provisioning a swap disk:

```
$ dd if=/dev/zero of=./swap.img bs=1024 count=$((1024 * 1024 * 4))
$ mkswap ./swap.img
$ sudo swapon ./swap.img
```

Hardware
=========

The SCAD files are designed around the following components for the
controllers:

    * NodeMCU ESP8266 microcontroller + Motorshield:
      https://www.amazon.com/ESP8266-Development-NodeMCU-CP2102-Shield/dp/B075VMNLZR
    * Pololu 99:1 Metal Gearmotor 25Dx54L:
      https://www.pololu.com/product/1587
    * Batteryspace LiFePO4 18650 Battery (6.4V x 1500 mah):
      http://www.batteryspace.com/lifepo418650battery64v1350mahflat864wh4aratewithpcbandpolyswitch.aspx
    * Amrka 6V 12V 10A Auto Solar Panel Charge Controller Battery Charge Regulator PWM
      https://www.amazon.com/gp/product/B072WSQPJN
    * US100 Ultrasonic Sensor:
      https://www.bananarobotics.com/shop/US-100-Ultrasonic-Distance-Sensor-Module
    * NUZAMAS 3.5W 6V 600ma Mini Solar Panel Module:
      https://www.amazon.com/gp/product/B071R3NQBP
      
The solar charging isn't fully worked out yet, I'm currently using one
of the above listed panels and a smaller 330ma panel, I'm planning to
switch to 3x600ma to (hopefully) get better results.

The SCAD files should be exported to STL and should be printable on
any 3D printer (I used a M3D Micro which is about the smallest printer
on the market). The parts are:

   * driver-wheel (x1): the actual wheel to put on the motor shaft and
     loop the shade string around. Assumes a simple rope for the
     shades. I recommend putting a few rubber bands around the wheel
     to increase friction. I print this with model-on-model support
     enabled.

   * housing (x1): the main housing for the controller, battery,
     motor, and solar charge regulator. Print with model-on-model
     support enabled.

   * motor-top (x1): a rounded piece to fit between the motor and the
     top of the housing, this gives the thumbscrews something to push
     down on to tension the motor/wheel into place. No support needed.

   * screwplate-6mm (x2 or 3): these should be inserted in the motor
     housing above and below the motor. One is inserted at the top of
     the housing to give the thumbscrews something to push against
     into all the layers (so the tension isn't shearing across the
     layers of the housing). One or more may be inserted below the
     motor to give it something to rest against (you may need to
     vertically scale this depending on your mounting).

  * ultrasonic-sensor-us100 (x1): split into two parts, base and
    shell, to house the ultrasonic sensor. Export once with `base =
    true` and `shell = false`, and once with `base = false` and `shell
    = true` (lines 23 and 24).

  * solar-panel-hook (2x # of panels): this is designed to hook to the
    underside of a siding J-strip to mount the solar panels below a
    window.
  
  * settings (x0): don't print this, it's just a master settings file
    included by the other scad files to ensure consistency.

See the thingiverse page: https://www.thingiverse.com/thing:3014140
for pre-exported STL files.

Configuring Controllers
=======================

Individual controllers are configured by modifying the `config.h` file
in the `shade-controller` subdirectory. Just edit this file to include
your WiFi network SSID and password (assumes WPA2), and for each shade
controller substitute in a unique id, a human friendly name, and a
description.

Once you've edited the `config.h` file, use the Arduino IDE to compile
and upload the firmware to each control unit.

Wiring
======

* The motor should be wired to the Motor A port of the motor shield
* The ultrasonic sensor should have TX connected to D8 and RX to D7
  and voltage and ground connected appropriately
* The battery should be wired to the Vin/Gnd terminals on the motor
  shield, with the Vin/Vm jumper installed

Calibration
===========

Prior to first use, you need to calibrate the maximum height of your
shades. With the controoler on, log into your MQTT broker and use the
`mosquitto_pub` command to issue the `CALIBRATE` instruction.

```
$ mosquitto_pub -t shade-controller-00 -m "CALIBRATE"
```

This *should* cause the controller to run its motor to raise the shade
until it stops moving, then set the current distance as the max
distance. In practice, it's easiest to just manually open the shade
all the way prior to sending the command. You can also use `SETMAX mm`
to set the maximum distance to `mm` in millimeters.

```
$ mosquitto_pub -t shade-controller-00 -m "SETMAX 1200"
```

Once the controller has been calibrated it will store the maximum
distance in EEPROM, so it shouldn't require recalibration. Adding a UI
for calibration is on the todo list.

Alexa Skill
===========

Create a new Amazon Alexa Smart Home Skill. See
https://developer.amazon.com/docs/smarthome/steps-to-build-a-smart-home-skill.html
for details.

As the backend, create an Amazon Lambda function, and upload the file
`alexa-backend/index.js`

In the lambda function configuration, set the process environment
variables `BACKEND_HOST`, `BACKEND_PORT` to the IP address and HTTPS
port of your server respectively. And set `USER_EMAIL` to your Amazon
email address (used for authorization).

Enable the skill in your Alexa app, then login with your amazon
account information and it should pick up all of your shades.