-- Comment http require to run unit tests
local http = require("socket.http")
local utils = require("util")
local daikin = require("Daikin")

http.TIMEOUT = 3

DEBUG_MODE = true

local PLUGIN_VERSION = "0.01"

local MAX_RETRY = 8
local UPDATE_INTERVAL  = 60

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

local DEFAULT_POLL = "1m"

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function sendCommand(command_url, data, retry)
	log(":Daikin Wifi Conntroller - sendCommand entered")
	local l_retry = retry or 0
	log(":Daikin Wifi Conntroller - sendCommand url"..command_url)
	-- local code = getDeviceCode(daikin_device_id)

	-- if (code == "") then
 --      return false, "sendCommand: No device code.", "Daikin Wifi Controller"
 --    end
    
	local ip = getIp(daikin_device_id)
	log(":Daikin Wifi Conntroller - sendCommand ip="..ip)
	if (ip == "") then
	  return false, "sendCommand: No IP address.", "Daikin Wifi Controller"
	end
	
	local commandString = "http://" .. ip .. command_url .. (data or "")
	log(":Daikin Wifi Conntroller - sendCommand commandString"..commandString)
	debug("sendCommand: " .. commandString)
	local sParam, status = http.request(commandString)
	log(":Daikin Wifi Conntroller - sendCommand sparam="..sParam)
	if (status == 200 and sParam) then
	  luup.variable_set(DAIKIN_WIFI_SID, "Message", sParam, daikin_device_id)
	  daikin_device:setAttributes(parseBody(sParam))
	  return true

	elseif (l_retry <= MAX_RETRY) then
	  commandRetry(command_url, data, l_retry)

	else
	  debug("sendCommand: ERROR parameters:" .. (sParam or "") .. " status=" .. (status or "") .. ".")
	  return false
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function commandRetry(command_url, data, retry)
	retry = retry + 1
	sendCommand(command_url, data, retry)
end

-------------------------------------------------------------------------------
-- MIOS UI Call functions
-------------------------------------------------------------------------------
function setFanMode(lul_device, NewMode)
	if NewMode == "Auto" then
		daikin_device.attributes["f_rate"].value = "A"
	end
	commandString = daikin_device:getCommandString()

	sendCommand(SET_CONTROL_URL,"&"..commandString)
	deviceUpdate()
	
	return true
end

function setFanSpeed(lul_device, FanSpeedTarget)
	local target = tonumber(FanSpeedTarget,10)

	if target ~= nil then
		if (target > 0 and target <= 20) then
      		daikin_device.attributes["f_rate"].value = 3
	    elseif(target > 20 and target <= 40) then
	    	daikin_device.attributes["f_rate"].value = 4
	    elseif(target > 40 and target <= 60) then
	    	daikin_device.attributes["f_rate"].value = 5
	    elseif(target > 60 and target <= 80) then
	    	daikin_device.attributes["f_rate"].value = 6
		elseif(target > 80) then
	    	daikin_device.attributes["f_rate"].value = 7
	    else
	      debug("setFanSpeed: Unknown speed:" .. FanSpeedTarget)
	      return false
	    end
	end

	commandString = daikin_device:getCommandString()

	sendCommand(SET_CONTROL_URL,"&"..commandString)
	deviceUpdate()
	return true

end

function setModeTarget(lul_device, NewModeTarget)
	local newMode = NewModeTarget

	if(NewModeTarget == "Off") then
      daikin_device.attributes["pow"].value = "0"
    elseif(NewModeTarget == "HeatOn") then
      newMode = "4"
    elseif(NewModeTarget == "AutoChangeOver") then
      newMode = "0"
    elseif(NewModeTarget == "CoolOn") then
      newMode = "3"
    else
      debug("setModeTarget: Unknown mode:" .. NewModeTarget)
      return false
    end

    daikin_device.attributes["mode"].value = newMode

	commandString = daikin_device:getCommandString()

	sendCommand(SET_CONTROL_URL,"&"..commandString)
	deviceUpdate()
	return true

end

function setpoint(lul_device, NewCurrentSetpoint)
	daikin_device.attributes["stemp"].value = string.format("%.1f",tonumber(NewCurrentSetpoint))

	commandString = daikin_device:getCommandString()

	sendCommand(SET_CONTROL_URL,"&"..commandString)

	return true
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function initPlugin()
	luup.variable_set(DAIKIN_WIFI_SID, "Message", "", daikin_device_id)

	-- set plugin version number
	luup.variable_set(DAIKIN_WIFI_SID, "PluginVersion", PLUGIN_VERSION, daikin_device_id)
	
	local config = tonumber(luup.variable_get(MCV_HA_DEVICE_SID,  HA_DEVICE_CONFIG, daikin_device_id),10) or ""
    if (config == "") then
      luup.variable_set(MCV_HA_DEVICE_SID, HA_DEVICE_CONFIG, "0", daikin_device_id)
    end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Called in loop
function deviceUpdate()
	local pollInterval = luup.variable_get(MCV_HA_DEVICE_SID,HA_DEVICE_POLL,daikin_device_id) or ""
    if (pollInterval == "") then
      pollInterval = DEFAULT_POLL
      luup.variable_set(MCV_HA_DEVICE_SID,HA_DEVICE_POLL,pollInterval,daikin_device_id)
    end
    luup.call_timer("deviceUpdate", 1, pollInterval, "", "")
    luup.variable_set(MCV_HA_DEVICE_SID, HA_DEVICE_LAST_UPDATE, tostring(os.time()), daikin_device_id)
    
    sendCommand(GET_CONTROL_URL)
    sendCommand(GET_SENSOR_URL)
end

---------------------------------------------------------------------
-- Statrup Function
---------------------------------------------------------------------
function DaikinStartup(lul_device)
	log(":Daikin Wifi Conntroller Plugin version " .. PLUGIN_VERSION .. ".")

    daikin_device_id = tonumber(lul_device)
	log(":Daikin Wifi Conntroller device id " .. daikin_device_id .. ".")    

    -- PREREQUISITES CHECK
 --    local code = getDeviceCode(daikin_device_id)
	-- if (code == "") then
 --      return false, "sendCommand: No device code.", "Daikin Wifi Controller"
 --    end

	local ip = getIp(daikin_device_id)
	if (ip == "") then
	  return false, "sendCommand: No IP address.", "Daikin Wifi Controller"
	end

	-- initialise the plugin
	initPlugin(daikin_device_id)
	log(":Daikin Wifi Conntroller - init complete")
	-- create Daikin device
    daikin_device = Daikin.new(daikin_device_id)
    log(":Daikin Wifi Conntroller - daikin device created")

    local status = sendCommand(GET_BASIC_INFO_URL)
     log(":Daikin Wifi Conntroller - First Send Command")
    if (status) then
      log(":Daikin Wifi Conntroller - sendCommand status = true")
      luup.set_failure(false, daikin_device_id)
      
      sendCommand(GET_MODEL_URL)
      log(":Daikin Wifi Conntroller - sendCommand Getmodel complete")
      sendCommand(GET_CONTROL_URL)
      log(":Daikin Wifi Conntroller - sendCommand Getcontrol complete")

      luup.attr_set("manufacturer", "Daikin", daikin_device_id)

      luup.call_delay("deviceUpdate", UPDATE_INTERVAL, "")

      debug("Daikin Wifi Controller Plugin Startup SUCCESS: Startup successful.")
      luup.variable_set(MCV_HA_DEVICE_SID,  HA_DEVICE_CONFIG, "1", daikin_device_id)

      luup.set_failure(false, daikin_device_id)         
       log(":Daikin Wifi Conntroller - Startup successful.")   
      return true, "Startup successful.", "Daikin Wifi Controller"
    end
     log(":Daikin Wifi Conntroller - exiting startup")
end
