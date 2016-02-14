local http = require("socket.http")
local utils = require("util")

http.TIMEOUT = 3

DEBUG_MODE = true
local VERSION = "0.01"
local DAIKIN_WIFI_SID  = "urn:asahani-org:serviceId:DaikinWifiController1"
local DEFAULT_SETPOINT = 21
local DEFAULT_POLL = "1m"

local GET_BASIC_INFO_URL = "/common/basic_info"
local GET_CONTROL_URL = "/aircon/get_control_info"
local GET_MODEL_URL = "/aircon/get_model_info"
local GET_SENSOR_URL = "/aircon/get_sensor_info"
local GET_TARGET_URL = "/aircon/get_target"
local GET_PROGRAM_URL = "/aircon/get_program"

local SET_CONTROL_URL = "/aircon/set_control_info"
local SET_TARGET_URL = "/aircon/set_target"
local SET_PROGRAM_URL = "/aircon/set_program"


local HADEVICE_SID = "urn:micasaverde-com:serviceId:HaDevice1"
local HVACHEAT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
local HVACCOOL_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"

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

local HAD_POLL = "Poll"
local HAD_SET_POLL_FREQUENCY = "SetPollFrequency"
local HAD_LAST_UPDATE = "LastUpdate"
local HAD_COMM_FAILURE = "CommFailure"
local HAD_CONFIG = "Configured"

function sendCommand(command_url, data, retry)

	local l_retry = retry or 0

	local code = getDeviceCode(daikin_device)
	if (code == "") then
      return false, "sendCommand: No device code.", "Daikin Wifi Controller"
    end

	local ip = getIp(daikin_device)
	if (ip == "") then
	  return false, "sendCommand: No IP address.", "Daikin Wifi Controller"
	end

	local commandString = "http://" .. ip .. command_url .. (data or "")
	
	debug("sendCommand: " .. commandString)
	local sParam, status = http.request(commandString)

	if (status == 200 and sParam) then
	  luup.variable_set(DAIKIN_WIFI_SID, "Message", sParam, daikin_device)
	  parseBody(sParam)
	  return true
	elseif (l_retry <= 8) then
	  commandRetry(command_url, data, l_retry)
	else
	  debug("sendCommand: ERROR parameters:" .. (sParam or "") .. " status=" .. (status or "") .. ".")
	  return false
	end

end

local function commandRetry(command_url, data, retry)

	retry = retry + 1
	sendCommand(command_url, data, retry)
end

local function initVariableIfNotSet(description,  variableName, serviceId, initValue, deviceId)
	debug("Entering initVariableIfNotSet : ","deviceId : "..deviceId.." serviceId : "..serviceId.." variableName : "..variableName..
	" initValue : ".. initValue.." description : "..description)

	local value = luup.variable_get(serviceId, variableName, deviceId)
	debug ("initVariableIfNotSet: current value= ", value)
	
	if (value == nil or value == "") then
		value = initValue
	end

	local attr = DaikinAttribute:new(nil,description,variableName,serviceId,value,deviceiceId)
	log("Set initial value of "..variableName.." (".. serviceId.. ") to "..initValue)
	
	return attr
end

local function initDaikin()
		-- initialize state variables
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "CreateGenericDevice", 0, g_deviceId)

	util.initVariableIfNotSet(RTCOA_WIFI_SID, "PollInterval", DEFAULT_POLL_INTERVAL, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "SyncClock", 0, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "ProgramSetpoints", 0, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "LooseTempControl", 0, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "Programs", "", g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "LogLevel", log.LOG_LEVEL_INFO, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "InitialPollDelay", 0, g_deviceId)

	util.initVariableIfNotSet(RTCOA_WIFI_SID, "EnergyLEDColor", "Off", g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "EnergyLEDSet", 0, g_deviceId)

	util.initVariableIfNotSet(RTCOA_WIFI_SID, "PMAMessage", "", g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "PMALine", 0, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "PMASet", 0, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "PMATempDevice", 0, g_deviceId)

	util.initVariableIfNotSet(RTCOA_WIFI_SID, "RemoteTempDevice", 0, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "RemoteTempSet", 0, g_deviceId)
	util.initVariableIfNotSet(RTCOA_WIFI_SID, "RemoteTemp", 0, g_deviceId)

	util.initVariableIfNotSet(RTCOA_WIFI_SID, "IPAddress", "0.0.0.0", g_deviceId)

	util.initVariableIfNotSet(RTCOA_WIFI_SID, "ForceHold", 0, g_deviceId)

local TEMP_SENSOR_SID = "urn:upnp-org:serviceId:TemperatureSensor1"
util.initVariableIfNotSet(TEMP_SENSOR_SID, "CurrentTemperature",  0, g_deviceId)

local TEMP_SETPOINT_SID= "urn:upnp-org:serviceId:TemperatureSetpoint1"
local HEAT_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
local COOL_SETPOINT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"
util.initVariableIfNotSet(HEAT_SETPOINT_SID, "CurrentSetpoint", localizeTemp(60), g_deviceId)
	util.initVariableIfNotSet(COOL_SETPOINT_SID, "CurrentSetpoint", localizeTemp(80), g_deviceId)

local FAN_MODE_SID = "urn:upnp-org:serviceId:HVAC_FanOperatingMode1"
util.initVariableIfNotSet(FAN_MODE_SID, "Mode", "Auto", g_deviceId)
	util.initVariableIfNotSet(FAN_MODE_SID, "FanStatus", "Off", g_deviceId)

local FAN_SPEED_SID  = "urn:upnp-org:serviceId:FanSpeed1"

local USER_OPERATING_MODE_SID = "urn:upnp-org:serviceId:HVAC_UserOperatingMode1"
util.initVariableIfNotSet(USER_OPERATING_MODE_SID, "ModeTarget", "Off", g_deviceId)
	util.initVariableIfNotSet(USER_OPERATING_MODE_SID, "ModeStatus", "Off", g_deviceId)
	util.initVariableIfNotSet(USER_OPERATING_MODE_SID, "EnergyModeTarget", "Normal", g_deviceId)
	util.initVariableIfNotSet(USER_OPERATING_MODE_SID, "EnergyModeStatus", "Normal", g_deviceId)

local MCV_HA_DEVICE_SID = "urn:micasaverde-com:serviceId:HaDevice1"
local MCV_OPERATING_STATE_SID = "urn:micasaverde-com:serviceId:HVAC_OperatingState1"
util.initVariableIfNotSet(MCV_OPERATING_STATE_SID, "ModeState", "Off", g_deviceId)
	
	
	local attributes = {
		["test"] = initVariableIfNotSet("description",  "variableName", "serviceId", "initValue", daikin_device)
		["ModeStatus"] = initVariableIfNotSet("Operating Mode Status",  "ModeStatus", USER_OPERATING_MODE_SID, "off", daikin_device)

	}
	daikin.attributes = attributes
end
---------------------------------------------------------------------
-- Statrup Function
---------------------------------------------------------------------
function DaikinStartup(lul_device)
	log(":Daikin Wifi Conntroller Plugin version " .. VERSION .. ".")

    daikin_device = lul_device

    local code = getDeviceCode(daikin_device)
	if (code == "") then
      return false, "sendCommand: No device code.", "Daikin Wifi Controller"
    end

	local ip = getIp(daikin_device)
	if (ip == "") then
	  return false, "sendCommand: No IP address.", "Daikin Wifi Controller"
	end
-- set plugin version number
	luup.variable_set(RTCOA_WIFI_SID, "PluginVersion", PLUGIN_VERSION, g_deviceId)

	luup.variable_set(SKYFI_SID, "Message", "", skyfi_device)
	local config = tonumber(luup.variable_get(HADEVICE_SID,  HAD_CONFIG, skyfi_device),10) or ""
    if (config == "") then
      luup.variable_set(HADEVICE_SID, HAD_CONFIG, "0", skyfi_device)
    end
    daikin = Daikin:new("","",daikin_device)
    initDaikin()

    luup.attr_set("manufacturer", value, skyfi_device)
end
