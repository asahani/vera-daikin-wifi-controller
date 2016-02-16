util = require('util')

------------------------------------------------------------------
----- Define SIDs used by the various thermostat services -------
------------------------------------------------------------------
local TEMP_SENSOR_SID = "urn:upnp-org:serviceId:TemperatureSensor1"
local TEMP_SETPOINT_SID= "urn:upnp-org:serviceId:TemperatureSetpoint1"
local HEAT_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
local COOL_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"
local FAN_MODE_SID = "urn:upnp-org:serviceId:HVAC_FanOperatingMode1"
local FAN_SPEED_SID  = "urn:upnp-org:serviceId:FanSpeed1"
local USER_OPERATING_MODE_SID = "urn:upnp-org:serviceId:HVAC_UserOperatingMode1"
local MCV_HA_DEVICE_SID = "urn:micasaverde-com:serviceId:HaDevice1"
local MCV_OPERATING_STATE_SID = "urn:micasaverde-com:serviceId:HVAC_OperatingState1"

------------------------------------------------------------------
----- Define Daikin Specific Values -------
------------------------------------------------------------------
local DEFAULT_SETPOINT = 21

local DAIKIN_WIFI_SID  = "urn:asahani-org:serviceId:DaikinWifiController1"

local POW_VARIABLE = "pow"
local MODE_VARIABLE = "mode"
local STEMP_VARIABLE = "stemp"
local HTEMP_VARIABLE = "htemp"
local FRATE_VARIABLE= "f_rate"
local FDIR_VARIABLE = "f_dir"
local RETURN_VARIABLE = "ret"
local SHUM_VARIABLE = "shum"

local g_modes = {
  ['0'] = "AutoChangeOver",
  ['4'] = "HeatOn",
  ['1'] = "AutoChangeOver",
  ['7'] = "AutoChangeOver",
  ['3'] = "CoolOn"
}

-- Meta class
Daikin = {deviceName = "", deviceType = "", version = "", deviceId = "", attributes  ={}}
Daikin.__index = Daikin

-- Base class method new
function Daikin.new(deviceName, deviceType, version, deviceId)
	local self = setmetatable({},Daikin)

	self.deviceName = deviceName
	self.deviceType = deviceType
	self.version = version
	self.deviceId = deviceId

	self.attributes = initVariables(deviceId)

	return self
end


-- Derived class methods
function Daikin:setAttribute(attrKey,attrValue)
	local attr = self.attributes[attrKey]

	if (attr == nil) then
		debug("DaikinAttribute:SetAttribute: ERROR: Not handled parameter type:" .. (attrKey or "") .. " value=" .. (attrValue or "") .. ".")
	else
		debug("DaikinAttribute:SetAttribute: key=" .. (attrKey or "") .. " value=" .. (attrValue or "") .. ".")

		-- Implement if conditions for Vera specific service files
		if attrKey == POW_VARIABLE then
			if attrValue == "0" then
				setLuupVariable(USER_OPERATING_MODE_SID, "ModeStatus", "Off", attr.deviceId)
				setLuupVariable(FAN_MODE_SID, "FanStatus", "Off", attr.deviceId)
			else
				setLuupVariable(FAN_MODE_SID, "FanStatus", "On", attr.deviceId)
			end
			attr:setValue(attrValue)

		elseif attrKey == MODE_VARIABLE then
			local mode = g_modes[attrValue] or "nil"
			setLuupVariable(USER_OPERATING_MODE_SID, "ModeStatus", mode, attr.deviceId)
			attr:setValue(attrValue)

		elseif attrKey == STEMP_VARIABLE then
			local tempVal = tonumber(attrValue,10)
			if tempVal ~= nil then
				setLuupVariable(TEMP_SETPOINT_SID, "CurrentSetpoint", tempVal, attr.deviceId)
				setLuupVariable(HEAT_SETPOINT_SID, "CurrentSetpoint", tempVal, attr.deviceId)
				setLuupVariable(COOL_SETPOINT_SID, "CurrentSetpoint", tempVal, attr.deviceId)
				attr:setValue(tempVal)
			end

		elseif attrKey == HTEMP_VARIABLE then
			local htempVal = tonumber(attrValue,10)
			if htempVal ~= nil then
				attr:setValue(htempVal)
			end

		elseif attrKey == FRATE_VARIABLE then
			local fVal = tonumber(attrValue)
			if fVal ~= nil then
				setLuupVariable(FAN_SPEED_SID, "FanSpeedStatus", fVal, attr.deviceId)
				setLuupVariable(TEMP_SETPOINT_SID, "FanSpeedTarget", fVal, attr.deviceId)
				attr:setValue(fVal)
			else
				setLuupVariable(TEMP_SETPOINT_SID, "CurrentSetpoint", "Auto", attr.deviceId)
				attr:setValue(attrValue)
			end

		else
			attr:setValue(attrValue)
		end

		self.attributes[attrKey] = attr
	end

end


function initVariables(daikin_device)
	-- initialize state variables
	
	local attribs = {}
	attribs["test"] = initVariableIfNotSet("description",  "variableName", "serviceId", "initValue", daikin_device)

	attribs[RETURN_VARIABLE] = initVariableIfNotSet("Command Return Status", RETURN_VARIABLE, DAIKIN_WIFI_SID, "OK", daikin_device)

	---------- Set Mode ---------
	attribs[POW_VARIABLE] = initVariableIfNotSet("Power",  POW_VARIABLE, DAIKIN_WIFI_SID, "0", daikin_device)
	attribs[MODE_VARIABLE] = initVariableIfNotSet("Operating Mode Target", MODE_VARIABLE, DAIKIN_WIFI_SID, "Off", daikin_device)

	---------- Current Temprature ---------
	-- Set varaibles for TEMP_SENSOR_SID = "urn:upnp-org:serviceId:TemperatureSensor1"
	attribs[HTEMP_VARIABLE] = initVariableIfNotSet("Current Temperature",  "CurrentTemperature", TEMP_SENSOR_SID, 0, daikin_device)

	---------- Set Temprature ---------
	attribs[STEMP_VARIABLE] = initVariableIfNotSet("UPnP Temperature Set Point",  "CurrentSetpoint", TEMP_SETPOINT_SID, DEFAULT_SETPOINT, daikin_device)
	
	---------- Fan Control ---------
	
	-- Set varaibles for FAN_SPEED_SID  = "urn:upnp-org:serviceId:FanSpeed1"
	attribs[FRATE_VARIABLE] = initVariableIfNotSet("Fan Speed",  "FanSpeedStatus", DAIKIN_WIFI_SID, "A", daikin_device)
	attribs[FDIR_VARIABLE] = initVariableIfNotSet("Fan Direction", "FDIR_VARIABLE", DAIKIN_WIFI_SID, 3, daikin_device)

	---------- Humidity ---------
	attribs[SHUM_VARIABLE] = initVariableIfNotSet("Humidity",  SHUM_VARIABLE, DAIKIN_WIFI_SID, 0, daikin_device)


	-- Set varaibles for USER_OPERATING_MODE_SID = "urn:upnp-org:serviceId:HVAC_UserOperatingMode1"
	-- Set for mode & pow
	initVariableIfNotSet("Operating Mode Status",  "ModeStatus", USER_OPERATING_MODE_SID, "Off", daikin_device)
	initVariableIfNotSet("Operating Mode Target", "ModeTarget", USER_OPERATING_MODE_SID, "Off", daikin_device)

	-- Set varaibles for TEMP_SETPOINT_SID= "urn:upnp-org:serviceId:TemperatureSetpoint1"
	-- HEAT_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
	-- COOL_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"
	initVariableIfNotSet("UPnP Heat Temperature Set Point",  "CurrentSetpoint", HEAT_SETPOINT_SID, DEFAULT_SETPOINT, daikin_device)
	initVariableIfNotSet("UPnP Cool Temperature Set Point",  "CurrentSetpoint", COOL_SETPOINT_SID, DEFAULT_SETPOINT, daikin_device)

	-- Set varaibles for FAN_MODE_SID = "urn:upnp-org:serviceId:HVAC_FanOperatingMode1"
	initVariableIfNotSet("Fan Status",  "FanStatus", FAN_MODE_SID, "Off", daikin_device)
	initVariableIfNotSet("Fan Mode",  "Mode", FAN_MODE_SID, "Auto", daikin_device)
	initVariableIfNotSet("Fan Speed",  "FanSpeedStatus", FAN_SPEED_SID, 3, daikin_device)
	initVariableIfNotSet("Fan Speed Target",  "FanSpeedTarget", FAN_SPEED_SID, "A", daikin_device)

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