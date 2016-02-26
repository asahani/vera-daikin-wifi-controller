# DAIKIN WIFI Controller
This is a plugin for the Daikin **BRP072A42** WIFI controller module for Vera UI5.

##Installation 
1. Goto https://github.com/asahani/vera-daikin-wifi-controller.git and download the zip file
2. Extract the zip file and goto the src folder
3. Open APPS section; Develop Apps >> Luup files.
4. Upload the following files to Vera
	* D_DaikinWifiController.json
	* D_DaikinWifiController.xml
	* I_DaikinWifiController.xml
	* L_DaikinWifiController.lua
	* Daikin.lua
	* DaikinAttribute.lua
	* util.lua
	* dkjson.lua

5. Open APPS section; Develop Apps >> Create Device.
6. In the Upnp Device Filename input box enter D_DaikinWifiController.xml.
7. In the Upnp Implementation Filename input box enter I_DaikinWifiController.xml.
8. optional: you can add the ip address of the BRP072A42 module as well
9. Click Create device.
10. Close the popup window that informs you about the creation of a new device, then push the Reload button (The luup engine will reload).
11. When reload is done, refresh your Web browser cache (Ctrl+F5 in most of the browsers).
12. Under the advanced tab add the IP Address of the BRP072A42 module (if not done earlier) and reload (as per above).

## Testing
If you are interested in developing and testing then please download the test file alongwith the src files. Open the D_DaikinWifiController.lua file and comment out the second line: 
```javascript
-- local http = require("socket.http")
```
*This is because i could not get a mock included for the socket.http in the test suite for the some of the controller methods. I am still finding my feet with lua and luup development.*

Then run ' lua TestSuite.lua' assuming that you have a lua dev environment setup on the command line.

## References
- https://github.com/ael-code/daikin-control
- https://github.com/hugheaves/mios_wifi-thermostat
- https://github.com/hugheaves/mios_zzcommon
- https://github.com/dmlogic/vera-HeatingCoordinator

###Manually remove unwanted devices from Vera
- http://<Vera_IP>:3480/data_request?id=device&action=delete&device=<device_ID>

### Vera plugin development info
- http://wiki.micasaverde.com/index.php/Plugin_Creation_Tutorial
- http://wiki.micasaverde.com/index.php/Luup_Plugins_ByHand
- http://wiki.micasaverde.com/index.php/Luup_plugins_and_Luup_code
- http://wiki.micasaverde.com/index.php/Luup_Declarations
- http://wiki.micasaverde.com/index.php/Luup_Lua_extensions#function:_call_delay
- http://wiki.micasaverde.com/index.php/Luup_UPnP_Variables_and_Actions#HVAC_FanOperatingMode1
- http://wiki.micasaverde.com/index.php/Luup_UPNP_Files#HVAC_FanOperatingMode1
- http://wiki.micasaverde.com/index.php/Luup_Requests
- http://wiki.micasaverde.com/index.php/Luup_plugins:_Static_JSON_file
- http://wiki.micasaverde.com/index.php/Luup_plugin_tabs
- http://wiki.micasaverde.com/index.php/JavaScript_API
- http://wiki.micasaverde.com/index.php/Luup_Debugging

### Log location
/tmp/log/cmh/LuaUPnP.log
