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

local TEMP_SID  = "urn:upnp-org:serviceId:TemperatureSensor1"
local FAN_SID  = "urn:upnp-org:serviceId:FanSpeed1"
local HVACO_SID = "urn:upnp-org:serviceId:HVAC_UserOperatingMode1"
local HVACF_SID  = "urn:upnp-org:serviceId:HVAC_FanOperatingMode1"
local HVACS_SID  = "urn:micasaverde-com:serviceId:HVAC_OperatingState1"
local HVACSET_SID= "urn:upnp-org:serviceId:TemperatureSetpoint1"
local HADEVICE_SID = "urn:micasaverde-com:serviceId:HaDevice1"
local HVACHEAT_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
local HVACCOOL_SID = "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"

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

function commandRetry(command_url, data, retry)

	retry = retry + 1
	sendCommand(command_url, data, retry)
end

function initDaikin()
	
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

	luup.variable_set(SKYFI_SID, "Message", "", skyfi_device)
	local config = tonumber(luup.variable_get(HADEVICE_SID,  HAD_CONFIG, skyfi_device),10) or ""
    if (config == "") then
      luup.variable_set(HADEVICE_SID, HAD_CONFIG, "0", skyfi_device)
    end


    luup.attr_set("manufacturer", value, skyfi_device)
end
