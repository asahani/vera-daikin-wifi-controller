util = require('util')


local DEFAULT_SETPOINT = 21

------------------------------------------------------------------
----- Define SIDs used by the various thermostat services -------
------------------------------------------------------------------
local DAIKIN_WIFI_SID  = "urn:asahani-org:serviceId:DaikinWifiController1"

local TEMP_SENSOR_SID = "urn:upnp-org:serviceId:TemperatureSensor1"
local TEMP_SETPOINT_SID= "urn:upnp-org:serviceId:TemperatureSetpoint1"
local HEAT_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
local COOL_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"
local FAN_MODE_SID = "urn:upnp-org:serviceId:HVAC_FanOperatingMode1"
local FAN_SPEED_SID  = "urn:upnp-org:serviceId:FanSpeed1"
local USER_OPERATING_MODE_SID = "urn:upnp-org:serviceId:HVAC_UserOperatingMode1"
local MCV_HA_DEVICE_SID = "urn:micasaverde-com:serviceId:HaDevice1"
local MCV_OPERATING_STATE_SID = "urn:micasaverde-com:serviceId:HVAC_OperatingState1"

-- Meta class
Daikin = {deviceType = "", version = "", deviceId = ""}
Daikin.__index = Daikin

-- Base class method new
function Daikin.new(o,deviceType,version,deviceId)
	local self = setmetatable({},Daikin)
	self.__index = self
	self.deviceType = deviceType
	self.version = version
	self.deviceId = deviceId
	self.attributes = {}
	return self
end


-- Derived class methods
function Daikin:setAttribute(attrKey,attrValue)
	local attr = attributes[attrKey]
	if (attr == nil) then
		debug("DaikinAttribute:SetAttribute: ERROR: Not handled parameter type:" .. (attrKey or "") .. " value=" .. (attrValue or "") .. ".")
	else
		debug("DaikinAttribute:SetAttribute: key=" .. (attrKey or "") .. " value=" .. (attrValue or "") .. ".")
		attr.setValue(attrValue)
	end

	-- Implement if conditions for Vera specific service files
end

function initVariables(daikin_device)
	-- initialize state variables
	
	local attribs = {}
	attribs["test"] = initVariableIfNotSet("description",  "variableName", "serviceId", "initValue", daikin_device)
print(attribs["test"].name)
	attribs["ret"] = initVariableIfNotSet("Command Return Status", "ret", DAIKIN_WIFI_SID, "OK", daikin_device)
print(attribs["test"].name)
	---------- Set Mode ---------
	attribs["pow"] = initVariableIfNotSet("Power",  "pow", DAIKIN_WIFI_SID, 0, daikin_device)
	attribs["mode"] = initVariableIfNotSet("Operating Mode Target", "mode", DAIKIN_WIFI_SID, "Off", daikin_device)
print(attribs["test"].name)
	---------- Current Temprature ---------
	-- Set varaibles for TEMP_SENSOR_SID = "urn:upnp-org:serviceId:TemperatureSensor1"
	attribs["htemp"] = initVariableIfNotSet("Current Temperature",  "CurrentTemperature", TEMP_SENSOR_SID, 0, daikin_device)

	---------- Set Temprature ---------
	attribs["stemp"] = initVariableIfNotSet("UPnP Temperature Set Point",  "CurrentSetpoint", TEMP_SETPOINT_SID, DEFAULT_SETPOINT, daikin_device)
	
	---------- Fan Control ---------
	-- Set varaibles for FAN_MODE_SID = "urn:upnp-org:serviceId:HVAC_FanOperatingMode1"
	attribs["FanMode"] = initVariableIfNotSet("Fan Mode",  "Mode", FAN_MODE_SID, "Auto", daikin_device)
	attribs["FanStatus"] = initVariableIfNotSet("Fan Status",  "FanStatus", FAN_MODE_SID, "Off", daikin_device)
	-- Set varaibles for FAN_SPEED_SID  = "urn:upnp-org:serviceId:FanSpeed1"
	attribs["f_rate"] = initVariableIfNotSet("Fan Speed",  "FanSpeedStatus", FAN_SPEED_SID, "A", daikin_device)
	attribs["f_dir"] = initVariableIfNotSet("Fan Direction",  "f_dir", DAIKIN_WIFI_SID, 3, daikin_device)

	---------- Humidity ---------
	attribs["shum"] = initVariableIfNotSet("Humidity",  "shum", DAIKIN_WIFI_SID, 0, daikin_device)


	-- Set varaibles for USER_OPERATING_MODE_SID = "urn:upnp-org:serviceId:HVAC_UserOperatingMode1"
	-- Set for mode & pow
	initVariableIfNotSet("Operating Mode Status",  "ModeStatus", USER_OPERATING_MODE_SID, "Off", daikin_device)
	initVariableIfNotSet("Operating Mode Target", "ModeTarget", USER_OPERATING_MODE_SID, "Off", daikin_device)

	-- Set varaibles for TEMP_SETPOINT_SID= "urn:upnp-org:serviceId:TemperatureSetpoint1"
	-- HEAT_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
	-- COOL_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"
	initVariableIfNotSet("UPnP Heat Temperature Set Point",  "CurrentSetpoint", HEAT_SETPOINT_SID, DEFAULT_SETPOINT, daikin_device)
	initVariableIfNotSet("UPnP Cool Temperature Set Point",  "CurrentSetpoint", COOL_SETPOINT_SID, DEFAULT_SETPOINT, daikin_device)


	-- Set varaibles for MCV_OPERATING_STATE_SID = "urn:micasaverde-com:serviceId:HVAC_OperatingState1"
	-- ["ModeState"] = initVariableIfNotSet("MCV Mode State",  "ModeState", MCV_OPERATING_STATE_SID, "off", daikin_device)

	return attribs
end

function initVariableIfNotSet(description,  variableName, serviceId, initValue, deviceId)
	debug("Entering initVariableIfNotSet : ".."deviceId : "..deviceId.." serviceId : "..serviceId.." variableName : "..variableName..
	" initValue : ".. initValue.." description : "..description)

	local value = luup.variable_get(serviceId, variableName, deviceId)

	if (value == nil or value == "") then
		value = initValue
	end

	debug ("initVariableIfNotSet: current value= ", value)

	local attr = DaikinAttribute:new(description,variableName,serviceId,value,deviceId)
	
	log("Set initial value of "..attr.name.." (".. attr.SERVICE_SID.. ") to "..attr.value)

	return attr
end