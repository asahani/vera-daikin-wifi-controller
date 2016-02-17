--[[
    Emulates the lua luup extensions for testing
]]
luup = {}
local luupvars = {}
local luupwatching = {}

function luup.task(a,b,c,d)
    taskMessage = a
end

function luup.log(msg,lvl)
    if(lvl == nil) then value = "nil" end
    print("LOG "..lvl..": "..msg)
end

function luup.variable_get(serviceId,varName,deviceId)
    key = serviceId..varName..deviceId
    value = luupvars[key]
    if(value == nil) then value = 0 end
    -- print("variable get: "..key.. " is : "..value)
    return value
end

function luup.variable_set(serviceId,varName,value,deviceId)

    key = serviceId..varName..deviceId
    luupvars[key] = value

    if(value == nil) then value = "nil" end

    -- print("variable set: "..key..":"..value)
end

function luup.variable_watch(func,service,var,deviceId)
    key = deviceId..service..var
    luupwatching[key] = func
end

function luup.call_action(serviceId,actionName,args,deviceId)

    for k,v in pairs(args) do
        -- print("pairs "..serviceId..","..k..","..v..","..deviceId)
        luup.variable_set(serviceId,k,v,deviceId)
    end

    -- this allows us to test at least that the call was made as expected
    return {serviceId,actionName,args,deviceId}
end

function luup.call_timer()
    return true;
end

function luup.attr_get(attr, deviceId)
    if deviceId == nil then
        deviceId = ""
    end 
    
    key = attr..deviceId
    value = luupvars[key]

    -- if(value ~= nil) then 
    --     print("variable get: "..key.. " is : "..value)
    -- else
    --     print("variable get: "..key.. " is : nil")
    -- end

    return value
end

function luup.attr_set(attr,value,deviceId)
    key = attr..deviceId
    luupvars[key] = value

    if(value == nil) then value = "nil" end

    -- print("variable set: "..key..":"..value)
end
