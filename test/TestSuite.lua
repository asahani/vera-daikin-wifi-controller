
package.path = package.path .. ";../src/?.lua"

local luaunit = require('luaunit')
local httpmock = require('httpmock')
local mockluup = require('luup')
local util = require('util')
local daikinAttribute = require('DaikinAttribute')
local daikin = require('Daikin')

TestHttp = {}
	function TestHttp:testRequest()
		local response = http.request("hhttp://192.168.178.148/aircon/get_control_info")
		--print(response)
		luaunit.assertNotNil(response)
	end

-- end of table TestHttp

TestUtil ={}

	function TestUtil:testNoIpSet()
		local ip = getIp(2)
		luaunit.assertEquals(ip,"")
	end

	function TestUtil:testGetIp()
		luup.attr_set("ip","192.168.178.148","1")
		local ip = getIp(1)
		luaunit.assertNotNil(ip)
		luaunit.assertEquals(ip,"192.168.178.148")
	end

	function TestUtil:testNoDeviceCode()
		local code = getDeviceCode(2)
		luaunit.assertEquals(code,"")
	end

	function TestUtil:testGetDeviceCode()
		luup.attr_set("altid","1","1")
		local code = getDeviceCode(1)
		luaunit.assertNotNil(code)
		luaunit.assertEquals(code,"1")
	end

	function TestUtil:testSetLuupVariable()
		setLuupVariable("TEST_ID","Test Name",13,12)
		local returnValue = luup.variable_get("TEST_ID","Test Name",12)
		-- print(returnValue)
		luaunit.assertEquals(returnValue,13)
	end
    

	function TestUtil:testGetLuupVariable()
		setLuupVariable("TEST_ID2","Test Name2",12,10)
		
		local returnValue = getLuupVariable("TEST_ID2","Test Name2",10,T_NUMBER)
		-- print(returnValue)

		luaunit.assertEquals(returnValue,12)
	end

	function TestUtil:testParseBody()
		local valuePairs = parseBody("ret=OK,pow=0,mode=3,adv=,stemp=18.0,shum=0,dt1=25.0,dt2=M,dt3=18.0,dt4=25.0,dt5=25.0,dt7=25.0,dh1=AUTO,dh2=50,dh3=0,dh4=0,dh5=0,dh7=AUTO,dhh=50,b_mode=3,b_stemp=18.0,b_shum=0,alert=255")
		luaunit.assertNotNil(valuePairs)
		luaunit.assertEquals(valuePairs["ret"],"OK")
	end

	function TestUtil:testHexToASCII()
		local hexString = "%4c%6f%75%6e%67%65"
		local asciiString = hexToASCII(hexString)

		luaunit.assertEquals(asciiString,"Lounge")
	end

-- end of table TestUtil

TestDaikinAttribute = {}

	function TestDaikinAttribute:testNewAttribute()
		local attr = DaikinAttribute:new(nil,"Test Attribute","Test Service name","urn:upnp-org:serviceId:HVAC_UserOperatingMode1",1,1)
		luaunit.assertEquals(attr.description,"Test Attribute")
		luaunit.assertEquals(attr.name,"Test Service name")
		luaunit.assertEquals(attr.SERVICE_SID,"urn:upnp-org:serviceId:HVAC_UserOperatingMode1")
		luaunit.assertEquals(attr.value,1)
		luaunit.assertEquals(attr.deviceId,1)
		
		attr.value = 2
		luaunit.assertEquals(attr.value,2)

		attr:setValue(3)
		luaunit.assertEquals(attr.value,3)
	end
-- end of table TestDaikinAttribute

TestDaikin ={}

	function TestDaikin:testNewDaikinDevice()
		local device = Daikin:new(nil,"Aircon","2.0.2",1)
		luaunit.assertEquals(device.deviceType,"Aircon")
		luaunit.assertEquals(device.version,"2.0.2")
		luaunit.assertEquals(device.deviceId,1)
		luaunit.assertNotNil(device.attributes)
	end


-- end of table TestDaikin
os.exit(luaunit.LuaUnit.run())