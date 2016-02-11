util = require('util')

-- Meta class
DaikinAttribute = {description = "", name= "", SERVICE_SID = "", value = "", deviceId = ""}

-- Base class method new
function DaikinAttribute:new (o,description,name,SERVICE_SID,value,deviceId)
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	self.description = description
	self.name = name
	self.SERVICE_SID = SERVICE_SID
	self.value = value
	self.deviceId = deviceId
	setLuupVariable(self.SERVICE_SID,  self.name, self.value, self.deviceId)
	
	return o
end

-- Derived class methods
function DaikinAttribute:setValue(newValue)
	
	debug("SetAttribute Message type description: " .. self.description)
    self.value = newValue
    setLuupVariable(self.SERVICE_SID,  self.name, self.value, self.deviceId)
end

function DaikinAttribute:getValue()
	return self.value
end
