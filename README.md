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
$ opam install jbuilder core opium lwt yojson ppx_deriving_yojson
```

Then compile
```
$ cd server && jbuilder build shades_server.exe
```

