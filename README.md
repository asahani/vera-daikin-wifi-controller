# DAIKIN WIFI Controller
This is a plugin for the Daikin **BRP072A42** WIFI controller module.

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
