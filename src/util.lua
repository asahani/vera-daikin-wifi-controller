function log (text,level)
	luup.log("DaikinWifiPlugin::" .. (text or ""),level or 50)
end

local function debug (text,level)
	if (DEBUG_MODE == true) then
		log(text,level or 1)
	end
end

function getIp(for_device)
	return luup.attr_get('ip', for_device) or ""
end

function getDeviceCode(for_device)
	return luup.attr_get("altid",for_device) or ""
end

