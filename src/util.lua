json = require('dkjson')

-- CONSTANTS
T_NUMBER = "T_NUMBER"
T_BOOLEAN = "T_BOOLEAN"
T_STRING = "T_STRING"
T_TABLE = "T_TABLE"

local LOG_PREFIX = "DaikinWifiPlugin::"
-----------------------------------------
-------- General Utility functions ------
-----------------------------------------
function log (text,level)
	luup.log(LOG_PREFIX .. (text or ""),level or 50)
end

function debug (text,level)
	if (DEBUG_MODE == true) then
		log(text,level or 1)
	end
end

-----------------------------------------
-------- Data Manipulation functions ----
-----------------------------------------
function parseBody(body)

	local valuePairs = {}
	for key,value in body:gmatch"(%w+)=(%w+)" do
		valuePairs[key]=value
	end
-- for key,value in valuePairs do
--   local data = nil
--   print("key : "..key.."-- value : "..value)
-- end

	return valuePairs
end

-- Convert HEX of format %xx%xx%xx
function hexToASCII(str)
	local retString = ""
	
	for i in string.gmatch(string.gsub(str, "%%", " "), "%S+") do
  		print(i)
  		retString = retString .. string.char(tonumber(i, 16))
	end
	-- print(retString)
    return retString
end

-----------------------------------------
-------- Lua Utility functions ----------
-----------------------------------------
function getIp(for_device)
	return luup.attr_get('ip', for_device) or ""
end

function getDeviceCode(for_device)
	return luup.attr_get("altid",for_device) or ""
end

function setLuupVariable(serviceId, variableName, newValue, deviceId)
	debug("setting Luup Variables: " .."deviceId ".. deviceId.."serviceId "..serviceId.."variableName "..variableName.."newValue ".. newValue,50)

	if (type(deviceId) == "string") then
		lul_device = tonumber(deviceId)
	end

	if (newValue == nil) then
		luup.variable_set(serviceId, variableName, "", deviceId)
	elseif (type(newValue) == "boolean") then
		local luupValue = "0"
		if (newValue) then
	  		luupValue = "1"
		end
		luup.variable_set(serviceId, variableName, luupValue, deviceId)
	elseif (type(newValue) == "table") then
		luup.variable_set(serviceId, variableName, json.encode(newValue):gsub("\"", "'"), deviceId)
	else
		luup.variable_set(serviceId, variableName, newValue, deviceId)
	end
end

function getLuupVariable(serviceId, variableName, deviceId, varType)
	if (type(deviceId) == "string") then
		deviceId = tonumber(deviceId)
	end

	local rawValue = luup.variable_get(serviceId, variableName, deviceId)
	local returnValue = nil

	if (not rawValue) then
		returnValue = nil
	elseif (varType == T_BOOLEAN) then
		returnValue = (rawValue == "1")
	elseif (varType == T_NUMBER) then
		returnValue = tonumber(rawValue)
	elseif (varType == T_STRING) then
		returnValue = tostring(rawValue)
	elseif (varType == T_TABLE) then
		rawValue = rawValue:gsub("'", "\"")
		debug ("rawValue = ", rawValue)
		returnValue = json.decode(rawValue)
	else
		debug("Invalid varType passed to getLuupVariable ".."serviceId :".. serviceId..
	  	" variableName :" .. variableName .. " deviceId :" .. deviceId ..
	  	" varType" .. tostring(varType))
		return nil
	end

	return returnValue
end
