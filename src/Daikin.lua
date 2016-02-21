util = require('util')
daikinAttribute = require('DaikinAttribute')

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
local MCV_OPERATING_STATE_SID = "urn:micasaverde-com:serviceId:HVAC_OperatingState1"

------------------------------------------------------------------
----- Define Daikin Specific Values -------
------------------------------------------------------------------
local DEFAULT_SETPOINT = 21

DAIKIN_WIFI_SID  = "urn:asahani-com:serviceId:DaikinWifiController1"

local RETURN_VARIABLE = "ret"
local POW_VARIABLE = "pow"
local MODEL_VARIABLE = "model"
local TYPE_VARIABLE = "type"
local VERSION_VARIABLE = "ver"
local NAME_VARIABLE = "name"
local MAC_ADDR_VARIABLE = "mac"

local MODE_VARIABLE = "mode"
local STEMP_VARIABLE = "stemp"
local HTEMP_VARIABLE = "htemp"
local OTEMP_VARIABLE = "otemp"
local FRATE_VARIABLE= "f_rate"
local FDIR_VARIABLE = "f_dir"

local SHUM_VARIABLE = "shum"

local g_modes = {
  ['0'] = "AutoChangeOver",
  ['4'] = "HeatOn",
  ['1'] = "AutoChangeOver",
  ['7'] = "AutoChangeOver",
  ['3'] = "CoolOn"
}

-- Meta class
Daikin = {deviceId = "", attributes  ={}}
Daikin.__index = Daikin

-- Base class method new
function Daikin.new(deviceId)
	local self = setmetatable({},Daikin)

	self.deviceId = deviceId
	self.attributes = initVariables(deviceId)
	--Set Manufacturer
    luup.attr_set("manufacturer", "Daikin", self.deviceId)

	return self
end


-- Derived class methods
function Daikin:getCommandString()
	local power = POW_VARIABLE.."="..self.attributes[POW_VARIABLE].value
	local mode = MODE_VARIABLE.."="..self.attributes[MODE_VARIABLE].value
	local temprature = STEMP_VARIABLE.."="..string.format("%.1f",tonumber(self.attributes[STEMP_VARIABLE].value))
	local humidity = SHUM_VARIABLE.."="..self.attributes[SHUM_VARIABLE].value
	local fanSpeed = FRATE_VARIABLE.."="..self.attributes[FRATE_VARIABLE].value
	local fanDirection = FDIR_VARIABLE.."="..self.attributes[FDIR_VARIABLE].value

	return power.."&".. mode .."&".. temprature .."&" .. humidity .. "&".. fanSpeed .. "&".. fanDirection
end


function Daikin:setAttributes(attribs)
	for key,val in pairs(attribs) do
	  -- print("key : "..key.."-- value : "..val)
	  self:setAttribute(key,val)
	end
end

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

		elseif attrKey == OTEMP_VARIABLE then
			local otempVal = tonumber(attrValue,10)
			if otempVal ~= nil then
				attr:setValue(otempVal)
			else
				attr:setValue(attrValue)
			end

		elseif attrKey == FRATE_VARIABLE then
			local fVal = tonumber(attrValue)
			if fVal ~= nil then
				setLuupVariable(FAN_SPEED_SID, "FanSpeedStatus", fVal, attr.deviceId)
				setLuupVariable(FAN_SPEED_SID, "FanSpeedTarget", fVal, attr.deviceId)
				attr:setValue(fVal)
			else
				setLuupVariable(FAN_MODE_SID, "Mode", "Auto", attr.deviceId)
				attr:setValue(attrValue)
			end
		elseif attrKey == NAME_VARIABLE then
			local deviceName = hexToASCII(attrValue)
			attr:setValue(deviceName)
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
	attribs[POW_VARIABLE] = initVariableIfNotSet("Power",  POW_VARIABLE, DAIKIN_WIFI_SID, "0", daikin_device)
	attribs[MODEL_VARIABLE] = initVariableIfNotSet("Model Info",  MODEL_VARIABLE, DAIKIN_WIFI_SID, "", daikin_device)
	attribs[TYPE_VARIABLE] = initVariableIfNotSet("Device Type",  TYPE_VARIABLE, DAIKIN_WIFI_SID, "", daikin_device)
	attribs[VERSION_VARIABLE] = initVariableIfNotSet("Device Version",  VERSION_VARIABLE, DAIKIN_WIFI_SID, "", daikin_device)
	attribs[NAME_VARIABLE] = initVariableIfNotSet("Device Name",  NAME_VARIABLE, DAIKIN_WIFI_SID, "", daikin_device)
	attribs[MAC_ADDR_VARIABLE] = initVariableIfNotSet("Model Info",  MAC_ADDR_VARIABLE, DAIKIN_WIFI_SID, "", daikin_device)
	
	---------- Set Mode ---------
	attribs[MODE_VARIABLE] = initVariableIfNotSet("Operating Mode Target", MODE_VARIABLE, DAIKIN_WIFI_SID, "Off", daikin_device)

	---------- Current Temprature ---------
	-- Set varaibles for TEMP_SENSOR_SID = "urn:upnp-org:serviceId:TemperatureSensor1"
	attribs[HTEMP_VARIABLE] = initVariableIfNotSet("Current Temperature",  "CurrentTemperature", TEMP_SENSOR_SID, 0, daikin_device)
	attribs[OTEMP_VARIABLE] = initVariableIfNotSet("Current Outside Temperature",  "CurrentOutsideTemperature", DAIKIN_WIFI_SID, 0, daikin_device)

	---------- Set Temprature ---------
	attribs[STEMP_VARIABLE] = initVariableIfNotSet("UPnP Temperature Set Point",  "CurrentSetpoint", TEMP_SETPOINT_SID, DEFAULT_SETPOINT, daikin_device)
	
	---------- Fan Control ---------
	-- Set varaibles for FAN_SPEED_SID  = "urn:upnp-org:serviceId:FanSpeed1"
	attribs[FRATE_VARIABLE] = initVariableIfNotSet("Fan Speed",  "FanSpeedStatus", DAIKIN_WIFI_SID, "A", daikin_device)
	attribs[FDIR_VARIABLE] = initVariableIfNotSet("Fan Direction", FDIR_VARIABLE, DAIKIN_WIFI_SID, 3, daikin_device)

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
	
	debug("Set initial value of "..attr.name.." (".. attr.SERVICE_SID.. ") to "..attr.value)

	return attr
end
