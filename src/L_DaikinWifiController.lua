--local http = require("socket.http")
local utils = require("util")
local daikin = require("Daikin")

http.TIMEOUT = 3

DEBUG_MODE = false

local VERSION = "0.01"

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

local MCV_HA_DEVICE_SID = "urn:micasaverde-com:serviceId:HaDevice1"

local HA_DEVICE_POLL = "Poll"
local HA_DEVICE_SET_POLL_FREQUENCY = "SetPollFrequency"
local HA_DEVICE_LAST_UPDATE = "LastUpdate"
local HA_DEVICE_COMM_FAILURE = "CommFailure"
local HA_DEVICE_CONFIG = "Configured"

function sendCommand(command_url, data, retry)
	local l_retry = retry or 0
	
	local code = getDeviceCode(daikin_device_id)

	if (code == "") then
      return false, "sendCommand: No device code.", "Daikin Wifi Controller"
    end
    
	local ip = getIp(daikin_device_id)
	
	if (ip == "") then
	  return false, "sendCommand: No IP address.", "Daikin Wifi Controller"
	end
	
	local commandString = "http://" .. ip .. command_url .. (data or "")
	
	debug("sendCommand: " .. commandString)
	local sParam, status = http.request(commandString)
	
	if (status == 200 and sParam) then
	  luup.variable_set(DAIKIN_WIFI_SID, "Message", sParam, daikin_device_id)
	  daikin_device:setAttributes(parseBody(sParam))
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

local function initPlugin()
	luup.variable_set(DAIKIN_WIFI_SID, "Message", "", daikin_device_id)

	-- set plugin version number
	luup.variable_set(DAIKIN_WIFI_SID, "PluginVersion", PLUGIN_VERSION, daikin_device_id)
	
	local config = tonumber(luup.variable_get(MCV_HA_DEVICE_SID,  HA_DEVICE_CONFIG, daikin_device_id),10) or ""
    if (config == "") then
      luup.variable_set(MCV_HA_DEVICE_SID, HA_DEVICE_CONFIG, "0", daikin_device_id)
    end
end

-- Called in loop
function deviceUpdate()
	--get_control_info
	--getsensorinfo
end

---------------------------------------------------------------------
-- Statrup Function
---------------------------------------------------------------------
function DaikinStartup(lul_device)
	log(":Daikin Wifi Conntroller Plugin version " .. VERSION .. ".")

    daikin_device_id = tonumber(lul_device)

    -- PREREQUISITES CHECK
    local code = getDeviceCode(daikin_device_id)
	if (code == "") then
      return false, "sendCommand: No device code.", "Daikin Wifi Controller"
    end

	local ip = getIp(daikin_device_id)
	if (ip == "") then
	  return false, "sendCommand: No IP address.", "Daikin Wifi Controller"
	end

	-- initialise the plugin
	initPlugin(daikin_device_id)
	-- create Daikin device
    daikin_device = Daikin.new(daikin_device_id)

    local status = sendCommand(GET_BASIC_INFO_URL)
    if (status) then
      luup.set_failure(false, daikin_device_id)
      sendCommand(GET_MODEL_URL)
      sendCommand(GET_CONTROL_URL)
      luup.attr_set("manufacturer", "Daikin", daikin_device_id)

      luup.call_delay("deviceUpdate", 60, "")
      debug("Daikin Wifi Controller Plugin Startup SUCCESS: Startup successful.")
      luup.variable_set(MCV_HA_DEVICE_SID,  HA_DEVICE_CONFIG, "1", daikin_device_id)

      luup.set_failure(false, daikin_device_id)            
      return true, "Startup successful.", "Daikin Wifi Controller"
    end

end
