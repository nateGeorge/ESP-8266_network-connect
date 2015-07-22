# ESP-8266_network-setup
convenient package for connecting to wifi networks with ESP8266 devices


::implementation::


The idea is to minimize the work required to connect an ESP8266 device to a router.

Step 1:  Power on the first ESP-8266 device.  Connect to the webserver it creates, and enter 

         SSID/password for the router.

Step 2:  Power on another/other ESP-8266 device(s).  Press a button on the first device, and 

         voila -- the other device(s) is/are connected.



::goal of the project::

I want to make the IoT cheaper and easier for all.



There are many IoT companies and devices out there popping up.  One flaw I see with them 

is that they usually require purchase of a 'hub' device that makes connection to the 

network easy, and may do some of the controlling of the devices.  These hubs normally cost 

somewhere in the range of $50-$200.  Routers can already handle 255 devices, so why 

not use those up before requiring someone to buy an expensive expansion hub?


This project is intended to be an implementation of best-practices IoT connection 

to standard routers with ESP-8266 devices, making entry into the IoT cheaper and 

easier for everyone.


:: task list::

* set up task list on a virtual taskboard, like scrumy or asana

* enable editing network list (change password, delete network, etc)

* write code for step 2 in implementation

* make webpage for entering SSID/password popup automatically

* figure out/solve security issues

* make interface look better/be easily customizable

* port over to C and roll into NodeMCU software