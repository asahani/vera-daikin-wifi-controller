util = require('util')

-- Meta class
Daikin = {deviceType = "", version = "", deviceId = ""}

-- Base class method new
function Daikin:new (o,deviceType,version,deviceId)
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	self.deviceType = deviceType
	self.version = version
	self.deviceId = deviceId
	self.attributes = {}
	return o
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

